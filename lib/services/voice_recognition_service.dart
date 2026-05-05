import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceActivationEvent {
  final String phraseDetected;
  final double confidence;
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

class VoiceRecognitionService {
  final String _safetyPhrase;
  final double _minConfidence;
  final Duration _listenDuration;

  final SpeechToText _speech = SpeechToText();

  VoiceRecognitionStatus _status = VoiceRecognitionStatus.uninitialized;
  VoiceActivationCallback? _onActivation;
  Timer? _restartTimer;
  bool _isDisposed = false;
  bool _isPaused = false;
  String? _lastError;

  VoiceRecognitionService({
    required String safetyPhrase,
    double minConfidence = 0.70,
    Duration listenDuration = const Duration(seconds: 10),
  })  : _safetyPhrase = safetyPhrase.toLowerCase().trim(),
        _minConfidence = minConfidence,
        _listenDuration = listenDuration;

  VoiceRecognitionStatus get status => _status;
  bool get isListening => _status == VoiceRecognitionStatus.listening;
  String? get lastError => _lastError;

  Future<bool> initialize({
    required VoiceActivationCallback onActivation,
  }) async {
    _onActivation = onActivation;
    _status = VoiceRecognitionStatus.initializing;

    final available = await _speech.initialize(
      onError: _onError,
      onStatus: _onStatus,
    );

    if (!available) {
      _status = VoiceRecognitionStatus.error;
      _lastError = 'Speech recognition not available on this device';
      debugPrint('[VoiceRecognition] Not available on this device');
      return false;
    }

    _status = VoiceRecognitionStatus.paused;
    debugPrint('[VoiceRecognition] Initialised. Safety phrase: "$_safetyPhrase"');
    return true;
  }

  Future<void> startListening() async {
    if (_isDisposed || _status == VoiceRecognitionStatus.listening) return;
    if (!_speech.isAvailable) {
      debugPrint('[VoiceRecognition] Speech not available, cannot start');
      return;
    }

    _isPaused = false;
    _status = VoiceRecognitionStatus.listening;
    await _startBurst();
  }

  Future<void> pauseListening() async {
    _restartTimer?.cancel();
    _restartTimer = null;
    _isPaused = true;
    await _speech.stop();
    _status = VoiceRecognitionStatus.paused;
    debugPrint('[VoiceRecognition] Paused');
  }

  Future<void> resumeListening() async {
    if (_isDisposed || _status != VoiceRecognitionStatus.paused) return;
    _isPaused = false;
    _status = VoiceRecognitionStatus.listening;
    await _startBurst();
    debugPrint('[VoiceRecognition] Resumed');
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _restartTimer?.cancel();
    await _speech.stop();
    _status = VoiceRecognitionStatus.uninitialized;
    debugPrint('[VoiceRecognition] Disposed');
  }

  void simulateActivationForTest() {
    _onActivation?.call(VoiceActivationEvent(
      phraseDetected: _safetyPhrase,
      confidence: 1.0,
      detectedAt: DateTime.now(),
    ));
  }

  Future<void> _startBurst() async {
    if (_isDisposed || _status != VoiceRecognitionStatus.listening) return;

    try {
      await _speech.listen(
        onResult: _onResult,
        listenFor: _listenDuration,
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        localeId: null,
        listenMode: ListenMode.dictation,
      );

      _restartTimer?.cancel();
      final restartDelay = _listenDuration - const Duration(milliseconds: 500);
      _restartTimer = Timer(
        restartDelay.isNegative ? Duration.zero : restartDelay,
        _restartBurst,
      );
    } catch (error) {
      _lastError = error.toString();
      debugPrint('[VoiceRecognition] Burst start error: $error');
      _restartTimer = Timer(const Duration(seconds: 2), _restartBurst);
    }
  }

  Future<void> _restartBurst() async {
    if (_isDisposed || _status != VoiceRecognitionStatus.listening || _isPaused) {
      return;
    }

    await _speech.stop();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _startBurst();
  }

  void _onResult(SpeechRecognitionResult result) {
    if (_isDisposed || result.recognizedWords.isEmpty) return;

    final words = result.recognizedWords.toLowerCase().trim();
    var confidence = result.confidence;
    if (confidence <= 0) {
      confidence = 0.5;
    }

    debugPrint(
      '[VoiceRecognition] Heard: "$words" (confidence: ${(confidence * 100).round()}%, final: ${result.finalResult})',
    );

    if (confidence < _minConfidence) return;
    if (!_matchesSafetyPhrase(words)) return;

    _onActivation?.call(VoiceActivationEvent(
      phraseDetected: words,
      confidence: confidence,
      detectedAt: DateTime.now(),
    ));
    pauseListening();
  }

  bool _matchesSafetyPhrase(String words) {
    return words.contains(_safetyPhrase);
  }

  void _onStatus(String status) {
    if (_isDisposed) return;
    debugPrint('[VoiceRecognition] Status: $status');

    if (status == 'notListening' &&
        _status == VoiceRecognitionStatus.listening &&
        !_isPaused) {
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(milliseconds: 200), _restartBurst);
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (_isDisposed) return;

    _lastError = error.errorMsg;
    debugPrint('[VoiceRecognition] Error: ${error.errorMsg}');

    if (error.permanent) {
      _status = VoiceRecognitionStatus.error;
      return;
    }

    if (_status == VoiceRecognitionStatus.listening && !_isPaused) {
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(seconds: 1), _restartBurst);
    }
  }
}