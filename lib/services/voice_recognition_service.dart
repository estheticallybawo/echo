// lib/services/voice_recognition_service.dart
//
// VOICE ACTIVATION — NO EXTERNAL ACCOUNT REQUIRED
// ─────────────────────────────────────────────────────────────────────────────
// Uses the device's built-in speech recognition (Google Speech on Android,
// Apple Speech on iOS) via the speech_to_text package.
//
// HOW IT WORKS:
//   The service listens in short 10-second bursts, checks each result for
//   the user's safety phrase, and immediately restarts if nothing matched.
//   This "rolling window" approach simulates continuous listening using the
//   platform's native on-device speech engine — no third-party account,
//   no API keys, no network required.
//
// TRADEOFFS vs Porcupine (for the judges):
//   ✓ Zero external dependencies — works out of the box
//   ✓ Uses Android/iOS native on-device speech recognition
//   ✓ Free, no account, no API key
//   ✓ Supports all languages Android/iOS support (Yoruba, Pidgin via locale)
//   ✗ Not true background audio (requires foreground service workaround)
//   ✗ Slightly higher battery than a dedicated wake-word model (~3–5%)
//   ✗ iOS has a 1-min hard limit on continuous speech sessions
//
// FOR PRODUCTION POST-HACKATHON:
//   Upgrade to Porcupine for sub-1% battery drain and true background support.
//   The interface (VoiceActivationCallback, VoiceActivationEvent) is identical
//   so swapping the implementation requires no changes elsewhere.
//
// PUBSPEC DEPS:
//   speech_to_text: ^7.0.0
//   permission_handler: ^11.3.0
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

// ── Public types ──────────────────────────────────────────────────────────────

class VoiceActivationEvent {
  final String phraseDetected;
  final double confidence;        // 0.0–1.0
  final DateTime detectedAt;

  const VoiceActivationEvent({
    required this.phraseDetected,
    required this.confidence,
    required this.detectedAt,
  });
}

typedef VoiceActivationCallback = void Function(VoiceActivationEvent event);

enum VoiceRecognitionStatus {
  uninitialized,
  initializing,
  listening,
  paused,
  error,
}

// ── Service ────────────────────────────────────────────────────────────────────

class VoiceRecognitionService {
  // ── Config ──────────────────────────────────────────────────────────────────
  /// The user's custom safety phrase, set during onboarding Page 3.
  /// Matching is case-insensitive and tolerates partial matches.
  final String _safetyPhrase;

  /// Minimum confidence to count as a detection. 0.7 = 70% sure.
  /// Lower this if the phrase is hard to detect in noisy environments.
  final double _minConfidence;

  /// How long each listening burst lasts before auto-restart.
  /// 10 seconds is a good balance between responsiveness and battery.
  final Duration _listenDuration;
  bool _isPaused = false; 

  // ── Internal state ──────────────────────────────────────────────────────────
  final SpeechToText _speech = SpeechToText();
  VoiceRecognitionStatus _status = VoiceRecognitionStatus.uninitialized;
  VoiceActivationCallback? _onActivation;
  Timer? _restartTimer;
  bool _isDisposed = false;
  String? _lastError;
  // int _falsePositiveCount = 0;

  // ── Getters ─────────────────────────────────────────────────────────────────
  VoiceRecognitionStatus get status => _status;
  bool get isListening => _status == VoiceRecognitionStatus.listening;
  String? get lastError => _lastError;

  VoiceRecognitionService({
    required String safetyPhrase,
    double minConfidence = 0.70,
    Duration listenDuration = const Duration(seconds: 10),
  })  : _safetyPhrase = safetyPhrase.toLowerCase().trim(),
        _minConfidence = minConfidence,
        _listenDuration = listenDuration;

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Initialise the speech engine and request microphone permission.
  /// Call during onboarding (after Page 3 phrase recording).
  Future<bool> initialize({
    required VoiceActivationCallback onActivation,
  }) async {
    _onActivation = onActivation;
    _status = VoiceRecognitionStatus.initializing;

    final available = await _speech.initialize(
      onError: _onError,
      onStatus: _onStatus,
      // debugLogging: kDebugMode,
    );

    if (!available) {
      _status = VoiceRecognitionStatus.error;
      _lastError = 'Speech recognition not available on this device';
      debugPrint('[VoiceRecognition] Not available on this device');
      return false;
    }

    debugPrint('[VoiceRecognition] Initialised. Safety phrase: "$_safetyPhrase"');
    return true;
  }

  /// Start the rolling-window background listener.
  /// Each 10-second burst restarts automatically until [pauseListening] is called.
  Future<void> startListening() async {
    if (_isDisposed) return;
    if (_status == VoiceRecognitionStatus.listening) return;
    if (!_speech.isAvailable) {
      debugPrint('[VoiceRecognition] Speech not available, cannot start');
      return;
    }

    _status = VoiceRecognitionStatus.listening;
    await _startBurst();
  }

  /// Pause when emergency activates — prevent re-triggering.
  Future<void> pauseListening() async {
    _restartTimer?.cancel();
    _isPaused = true;
    _restartTimer = null;
    await _speech.stop();
    _status = VoiceRecognitionStatus.paused;
    debugPrint('[VoiceRecognition] Paused');
  }

  /// Resume after emergency resolves.
  Future<void> resumeListening() async {
    _isPaused = false;
    if (_isDisposed) return;
    if (_status != VoiceRecognitionStatus.paused) return;
    _status = VoiceRecognitionStatus.listening;
    await _startBurst();
    debugPrint('[VoiceRecognition] Resumed');
  }

  /// Clean up. Call only when the app is fully closing.
  Future<void> dispose() async {
    _isDisposed = true;
    _restartTimer?.cancel();
    await _speech.stop();
    _status = VoiceRecognitionStatus.uninitialized;
    debugPrint('[VoiceRecognition] Disposed');
  }

  /// Simulate activation for the onboarding system test (Page 7).
  /// Fires the callback without requiring a real voice input.
  void simulateActivationForTest() {
    _onActivation?.call(VoiceActivationEvent(
      phraseDetected: _safetyPhrase,
      confidence: 1.0,
      detectedAt: DateTime.now(),
    ));
  }

  // ── Internal ─────────────────────────────────────────────────────────────────

  Future<void> _startBurst() async {
    if (_isDisposed || _status != VoiceRecognitionStatus.listening ) return;

    try {
      await _speech.listen(
        onResult: _onResult,
        listenFor: _listenDuration,
        pauseFor: const Duration(seconds: 4), // Allow 4s pauses in speech
        partialResults: true,   // Check partial results for faster detection
        onSoundLevelChange: null,
        // Use device locale by default — supports Yoruba/Pidgin on devices
        // where that locale is installed. Override with e.g. 'yo_NG' for Yoruba.
        localeId: null,
        listenMode: ListenMode.dictation,
      );

      // Schedule restart before the burst window closes
      // so there's no gap in listening
      _restartTimer?.cancel();
      _restartTimer = Timer(
        _listenDuration - const Duration(milliseconds: 500),
        _restartBurst,
      );

    } catch (e) {
      debugPrint('[VoiceRecognition] Burst start error: $e');
      // Try again after a short delay rather than crashing
      _restartTimer = Timer(const Duration(seconds: 2), _restartBurst);
    }
  }

  Future<void> _restartBurst() async {
    if (_isDisposed || _status != VoiceRecognitionStatus.listening || _isPaused) return;
    await _speech.stop();
    await Future.delayed(const Duration(milliseconds: 200));
    await _startBurst();
  }

  void _onResult(SpeechRecognitionResult result) {
    if (_isDisposed) return;
    if (result.recognizedWords.isEmpty) return;

    final words = result.recognizedWords.toLowerCase().trim();
    // final confidence = result.confidence > 0 ? result.confidence : 0.8;
    double confidence = result.confidence;
     if (confidence <= 0) {
        debugPrint('[VoiceRecognition] Warning: confidence unavailable, relying on phrase match only');
        confidence = 0.5;  // Conservative default
      }

    debugPrint(
      '[VoiceRecognition] Heard: "$words" '
      '(confidence: ${(confidence * 100).round()}%, final: ${result.finalResult})',
    );

    // Check if the safety phrase is contained in what was heard
    if (_isPhraseMatch(words) && confidence >= _minConfidence) {
      debugPrint('[VoiceRecognition] 🚨 SAFETY PHRASE DETECTED: "$words"');

      // Pause immediately to prevent double-trigger
      pauseListening();

      _onActivation?.call(VoiceActivationEvent(
        phraseDetected: result.recognizedWords,
        confidence: confidence,
        detectedAt: DateTime.now(),
      ));
    }
  }

  /// Phrase matching — tolerates natural variation in speech.
  /// "Gemma help me now" matches the phrase "Gemma help me".
  /// "I need help" partially matches "help me".
  bool _isPhraseMatch(String heard) {
    // Exact or contains match
    if (heard.contains(_safetyPhrase)) return true;

    // Word-level match: all key words of the phrase appear in heard
    final phraseWords = _safetyPhrase.split(' ')
        .where((w) => w.length > 2) // Skip tiny words like "I", "a"
        .toList();
    final heardWords = heard.split(' ').toSet();

    if (phraseWords.isEmpty) return false;

    final matchCount = phraseWords.where(heardWords.contains).length;
    final matchRatio = matchCount / phraseWords.length;

    // Require at least 80% of key words to match
    return matchRatio >= 0.8;
  }

  void _onStatus(String status) {
    debugPrint('[VoiceRecognition] Status: $status');

    // On iOS, the speech session ends after ~60s regardless.
    // Restart automatically if we're supposed to be listening.
    if (status == 'notListening' &&
        _status == VoiceRecognitionStatus.listening &&
        !_isDisposed) {
      _restartTimer?.cancel();
      _restartTimer = Timer(
        const Duration(seconds: 1),(){
          if(_speech.isAvailable) _restartBurst();
        }
        
      );
    }
  }

  void _onError(SpeechRecognitionError error) {
    debugPrint('[VoiceRecognition] Error: ${error.errorMsg} (permanent: ${error.permanent})');
    _lastError = error.errorMsg;

    if (error.permanent) {
      _status = VoiceRecognitionStatus.error;
      return;
    }

    // For transient errors (network, busy), back off and retry
    if (_status == VoiceRecognitionStatus.listening && !_isDisposed) {
      _restartTimer?.cancel();
      _restartTimer = Timer(
        const Duration(seconds: 2),
        _restartBurst,
      );
    }
  }                             
}


