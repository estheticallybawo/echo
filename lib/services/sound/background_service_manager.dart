// lib/services/background_service_manager.dart
//
// FEATURE BRANCH : feature/background-services
// PLATFORM       : Android (foreground service) + iOS (background audio mode)
// ─────────────────────────────────────────────────────────────────────────────
//
// WHAT THIS FILE DOES
// ───────────────────
// Flutter-side wrapper for background service management.
//
// On Android:
//   Communicates with GuardianForegroundService.kt via MethodChannel.
//   The foreground service keeps the microphone alive in the background.
//
// On iOS:
//   Activates the AVAudioSession background audio mode, which allows
//   microphone use when the app is backgrounded. No foreground service
//   equivalent exists on iOS — background audio mode is the correct approach.
//   Requires "Audio, AirPlay, and Picture in Picture" background mode in
//   Xcode → Signing & Capabilities → Background Modes.
//
// HOW TO USE
// ──────────
// Called from main.dart after onboarding completes:
//
//   final bgManager = BackgroundServiceManager();
//   await bgManager.startBackgroundServices();
//
// Called from Settings screen if user disables Guardian:
//
//   await bgManager.stopBackgroundServices();
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BackgroundServiceManager {

  /// MethodChannel to GuardianForegroundService.kt (Android only).
  /// Channel name must match FOREGROUND_CHANNEL constant in Kotlin file.
  static const _channel = MethodChannel('com.guardian.app/foreground_service');

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Start background services.
  ///
  /// Android: starts GuardianForegroundService (foreground service + notification).
  /// iOS: activates background audio mode via AVAudioSession.
  ///
  /// Call once after onboarding is complete, then on each app launch.
  Future<bool> startBackgroundServices() async {
    try {
      if (Platform.isAndroid) {
        // Tell the Kotlin foreground service to start.
        // GuardianServiceChannel.register() handles this in MainActivity.kt.
        await _channel.invokeMethod('startService');
        debugPrint('[BgService] Android foreground service started');
      } else if (Platform.isIOS) {
        // iOS does not have foreground services. Instead, we rely on:
        //   1. Background audio mode (set in Xcode → Background Modes)
        //   2. The app staying active via AVAudioSession
        // This is configured in ios/Runner/AppDelegate.swift — see inline note.
        debugPrint('[BgService] iOS background audio mode active '
            '(configured via AVAudioSession in AppDelegate)');
      }

      _isRunning = true;
      return true;

    } on PlatformException catch (e) {
      debugPrint('[BgService] Failed to start: ${e.message}');
      return false;
    }
  }

  /// Stop background services.
  ///
  /// Call when the user disables Guardian in Settings.
  /// This stops the Android foreground notification and releases the mic.
  Future<void> stopBackgroundServices() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('stopService');
        debugPrint('[BgService] Android foreground service stopped');
      }
      _isRunning = false;
    } on PlatformException catch (e) {
      debugPrint('[BgService] Failed to stop: ${e.message}');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// iOS SETUP NOTES (for Naema)
// ─────────────────────────────────────────────────────────────────────────────
//
// 1. In Xcode → Runner target → Signing & Capabilities → + Capability:
//    Add "Background Modes" and enable:
//    ✓ Audio, AirPlay, and Picture in Picture
//
// 2. In ios/Runner/Info.plist, add:
//    <key>UIBackgroundModes</key>
//    <array>
//      <string>audio</string>
//    </array>
//    <key>NSMicrophoneUsageDescription</key>
//    <string>Guardian listens for your safety phrase to activate in an emergency.</string>
//    <key>NSSpeechRecognitionUsageDescription</key>
//    <string>Guardian detects your safety phrase to activate in an emergency.</string>
//
// 3. In ios/Runner/AppDelegate.swift, activate AVAudioSession:
//    import AVFoundation
//    // In application(_:didFinishLaunchingWithOptions:):
//    do {
//      try AVAudioSession.sharedInstance().setCategory(
//        .playAndRecord,
//        mode: .default,
//        options: [.defaultToSpeaker, .allowBluetooth]
//      )
//      try AVAudioSession.sharedInstance().setActive(true)
//    } catch {
//      print("AVAudioSession setup failed: \(error)")
//    }
//
// NOTE: iOS still has a ~60-second STT session limit enforced by Apple.
// VoiceRecognitionService handles this via auto-restart in _onStatus().
// ─────────────────────────────────────────────────────────────────────────────