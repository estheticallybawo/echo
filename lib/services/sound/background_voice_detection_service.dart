// Background Voice Detection Service
// Manages periodic voice monitoring using workmanager (Android) and native background tasks (iOS)
//
// ANDROID SETUP:
// 1. Add to AndroidManifest.xml inside <manifest>:
//    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
//
// 2. This service uses workmanager which schedules periodic tasks
//
// iOS SETUP (requires native code):
// 1. In ios/Runner/Info.plist, add:
//    <key>UIBackgroundModes</key>
//    <array>
//      <string>processing</string>
//      <string>audio</string>
//    </array>
//
// 2. In AppDelegate.swift, register background task:
//    import BackgroundTasks
//    BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.echo.voice-detection", 
//                                     using: nil) { task in
//      self.scheduleBackgroundVoiceDetection()
//    }

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'audio_record_service.dart';
import 'speech_transcription_service.dart';

typedef BackgroundVoiceDetectionCallback = Future<void> Function(Map<String, dynamic> result);

class BackgroundVoiceDetectionService {
  static final BackgroundVoiceDetectionService _instance = 
      BackgroundVoiceDetectionService._internal();

  factory BackgroundVoiceDetectionService() {
    return _instance;
  }

  BackgroundVoiceDetectionService._internal();

  static const String _taskName = 'background_voice_detection';
  static const String _taskId = 'com.echo.voice-detection';
  
  bool _isRunning = false;
  BackgroundVoiceDetectionCallback? _onDetection;

  bool get isRunning => _isRunning;

  /// Initialize background voice detection
  /// 
  /// Starts periodic voice monitoring task
  /// Frequency: every 15 minutes (adjustable)
  Future<bool> initialize({
    required BackgroundVoiceDetectionCallback onDetection,
    Duration checkInterval = const Duration(minutes: 15),
  }) async {
    try {
      _onDetection = onDetection;
      
      if (kIsWeb) {
        debugPrint('[BackgroundVoiceDetection] Web detected: Background tasks are not supported.');
        return true;
      }

      // Initialize workmanager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      debugPrint('[BackgroundVoiceDetection] Initialized with ${checkInterval.inMinutes}min interval');
      return true;
    } catch (e) {
      debugPrint('[BackgroundVoiceDetection] Initialization failed: $e');
      return false;
    }
  }

  /// Start periodic background voice detection
  Future<void> start({
    Duration checkInterval = const Duration(minutes: 15),
    bool requiresDeviceIdle = false,
  }) async {
    try {
      if (kIsWeb) {
        debugPrint('[BackgroundVoiceDetection] Cannot start periodic tasks on Web.');
        return;
      }

      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskId,
        frequency: checkInterval,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(
          requiresBatteryNotLow: true,
          requiresCharging: false,
          requiresDeviceIdle: requiresDeviceIdle,
          networkType: NetworkType.notRequired, 
        ),
      );

      _isRunning = true;
      debugPrint('[BackgroundVoiceDetection] Started with ${checkInterval.inMinutes}min intervals');
    } catch (e) {
      debugPrint('[BackgroundVoiceDetection] Failed to start: $e');
    }
  }

  /// Stop background voice detection
  Future<void> stop() async {
    try {
      if (kIsWeb) {
        _isRunning = false;
        return;
      }

      await Workmanager().cancelByTag(_taskName);
      _isRunning = false;
      debugPrint('[BackgroundVoiceDetection] Stopped');
    } catch (e) {
      debugPrint('[BackgroundVoiceDetection] Failed to stop: $e');
    }
  }

  /// Get task status
  Future<Map<String, dynamic>> getStatus() async {
    return {
      'isRunning': _isRunning,
      'taskName': _taskName,
      'taskId': _taskId,
      'platform': defaultTargetPlatform.toString(),
    };
  }
}

/// Callback dispatcher for workmanager
/// 
/// This must be a top-level function called from main()
@pragma('vm:entry-point')
void callbackDispatcher() {
  if (kIsWeb) return;

  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'background_voice_detection') {
      debugPrint('[BackgroundTask] Voice detection task triggered');
      
      try {
        // Quick audio sample collection (2 seconds)
        final recorder = AudioRecorderService();
        if (!await recorder.initialize()) {
          debugPrint('[BackgroundTask] Recorder initialization failed');
          return false;
        }

        await recorder.startRecording();
        await Future.delayed(const Duration(seconds: 2));
        await recorder.stopRecording();

        // Analyze audio buffer
        final transcriber = SpeechTranscriptionService();
        await transcriber.initialize();

        final audioData = recorder.buffer.getAudio();
        final result = await transcriber.transcribeAndAnalyse(
          audioData: audioData,
          sampleRateHz: 16000,
          context: {'backgroundTask': true},
        );

        debugPrint('[BackgroundTask] Analysis result: distress=${result.distressLevel}, confidence=${(result.confidence * 100).toInt()}%');

        // Alert if threat detected
        if (result.shouldAlert) {
          debugPrint('[BackgroundTask] ALERT: Potential threat detected!');
          // TODO: Trigger appropriate alert (push notification, foreground service, etc.)
        }

        await recorder.dispose();
        return true;
      } catch (e) {
        debugPrint('[BackgroundTask] Error during execution: $e');
        return false;
      }
    }
    return false;
  });
}

/// Setup background voice detection
/// 
/// Call this from main() after initializing other services:
/// 
///   final bgVoiceService = BackgroundVoiceDetectionService();
///   await bgVoiceService.initialize(
///     onDetection: (result) async {
///       print('Threat detected: ${result['distress_level']}');
///     },
///   );
///   await bgVoiceService.start(checkInterval: Duration(minutes: 15));
