import 'dart:async';
import 'dart:math' as math;

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
  final Duration _activationWindow;
  final Duration _duplicateDebounce;
  final int _maxTyposPerToken;
  final int _confidenceWindowSize;
  final double _confidenceUnstableStdDev;
  final double _unstableConfidencePenalty;

  final SpeechToText _speech = SpeechToText();
  final List<double> _recentConfidences = <double>[];

  VoiceRecognitionStatus _status = VoiceRecognitionStatus.uninitialized;
  VoiceActivationCallback? _onActivation;
  Timer? _restartTimer;
  Timer? _activationWindowTimer;
  bool _isDisposed = false;
  bool _isPaused = false;
  bool _alwaysListeningEnabled = true;
  String? _lastError;
  DateTime? _lastDetectionAt;
  String? _lastDetectionPhrase;
  int _triggerCount = 0;
  int _rejectedCount = 0;
  int _duplicateCount = 0;

  VoiceRecognitionService({
    required String safetyPhrase,
    double minConfidence = 0.70,
    Duration listenDuration = const Duration(seconds: 10),
    Duration activationWindow = const Duration(seconds: 7),
    Duration duplicateDebounce = const Duration(seconds: 2),
    int maxTyposPerToken = 1,
    int confidenceWindowSize = 8,
    double confidenceUnstableStdDev = 0.12,
    double unstableConfidencePenalty = 0.07,
  })  : _safetyPhrase = safetyPhrase.toLowerCase().trim(),
        _minConfidence = minConfidence,
        _listenDuration = listenDuration,
        _activationWindow = activationWindow,
        _duplicateDebounce = duplicateDebounce,
        _maxTyposPerToken = maxTyposPerToken,
        _confidenceWindowSize = confidenceWindowSize,
        _confidenceUnstableStdDev = confidenceUnstableStdDev,
        _unstableConfidencePenalty = unstableConfidencePenalty;

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
    if (_isDisposed || _status == VoiceRecognitionStatus.listening || !_alwaysListeningEnabled) return;
    if (kIsWeb) {
      debugPrint('[VoiceRecognition] Continuous hotword listening disabled on web demo builds');
      _status = VoiceRecognitionStatus.paused;
      return;
    }
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
    _activationWindowTimer?.cancel();
    _activationWindowTimer = null;
    _isPaused = true;
    await _speech.stop();
    _status = VoiceRecognitionStatus.paused;
    debugPrint('[VoiceRecognition] Paused');
  }

  Future<void> resumeListening() async {
    if (_isDisposed || _status != VoiceRecognitionStatus.paused || !_alwaysListeningEnabled) return;
    if (kIsWeb) {
      debugPrint('[VoiceRecognition] Resume ignored on web demo builds');
      return;
    }
    _isPaused = false;
    _status = VoiceRecognitionStatus.listening;
    await _startBurst();
    debugPrint('[VoiceRecognition] Resumed');
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _restartTimer?.cancel();
    _activationWindowTimer?.cancel();
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

  Future<void> setAlwaysListeningEnabled(bool enabled) async {
    _alwaysListeningEnabled = enabled;
    if (!enabled) {
      await pauseListening();
      debugPrint('[VoiceRecognition] Always-listening disabled by user');
    } else if (_status == VoiceRecognitionStatus.paused) {
      await resumeListening();
      debugPrint('[VoiceRecognition] Always-listening enabled by user');
    }
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
      if (!kIsWeb && !_isDisposed && !_isPaused) {
        _restartTimer = Timer(const Duration(seconds: 2), _restartBurst);
      } else {
        _status = VoiceRecognitionStatus.error;
      }
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
    _pushConfidence(confidence);
    final effectiveMinConfidence = _effectiveMinConfidence();

    debugPrint('[VoiceRecognition] Heard speech segment (confidence: ${(confidence * 100).round()}%, final: ${result.finalResult})');

    if (confidence < effectiveMinConfidence) {
      _logRejected(words, confidence, 'low-confidence(threshold=${effectiveMinConfidence.toStringAsFixed(2)})');
      return;
    }
    if (!_matchesSafetyPhrase(words)) {
      _logRejected(words, confidence, 'phrase-miss');
      return;
    }
    if (_isDuplicateDetection(words)) {
      _duplicateCount++;
      _logRejected(words, confidence, 'duplicate');
      return;
    }

    _triggerCount++;
    _lastDetectionAt = DateTime.now();
    _lastDetectionPhrase = words;
    _onActivation?.call(VoiceActivationEvent(
      phraseDetected: words,
      confidence: confidence,
      detectedAt: DateTime.now(),
    ));
    _openActivationWindow();
  }

  bool _matchesSafetyPhrase(String words) {
    final phraseTokens = _tokenize(_safetyPhrase);
    final wordTokens = _tokenize(words);
    if (phraseTokens.isEmpty || wordTokens.length < phraseTokens.length) {
      return false;
    }

    for (var start = 0; start <= wordTokens.length - phraseTokens.length; start++) {
      var tokenMismatchCount = 0;
      for (var i = 0; i < phraseTokens.length; i++) {
        final distance = _levenshtein(wordTokens[start + i], phraseTokens[i]);
        if (distance > _maxTyposPerToken) {
          tokenMismatchCount++;
          if (tokenMismatchCount > 0) {
            break;
          }
        }
      }
      if (tokenMismatchCount == 0) return true;
    }
    return false;
  }

  List<String> _tokenize(String source) {
    final normalized = source.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return normalized.split(RegExp(r'\s+')).where((token) => token.isNotEmpty).toList();
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      var current = i + 1;
      for (var j = 0; j < b.length; j++) {
        final insert = previous[j + 1] + 1;
        final delete = current + 1;
        final replace = previous[j] + (a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1);
        previous[j] = current;
        current = [insert, delete, replace].reduce((x, y) => x < y ? x : y);
      }
      previous[b.length] = current;
    }
    return previous[b.length];
  }

  bool _isDuplicateDetection(String words) {
    if (_lastDetectionAt == null || _lastDetectionPhrase == null) return false;
    final elapsed = DateTime.now().difference(_lastDetectionAt!);
    return elapsed <= _duplicateDebounce && words == _lastDetectionPhrase;
  }

  void _pushConfidence(double confidence) {
    _recentConfidences.add(confidence);
    if (_recentConfidences.length > _confidenceWindowSize) {
      _recentConfidences.removeAt(0);
    }
  }

  double _effectiveMinConfidence() {
    if (_recentConfidences.length < 3) return _minConfidence;
    final avg = _recentConfidences.reduce((a, b) => a + b) / _recentConfidences.length;
    final variance = _recentConfidences
            .map((value) => (value - avg) * (value - avg))
            .reduce((a, b) => a + b) /
        _recentConfidences.length;
    final stdDev = math.sqrt(variance);
    if (stdDev < _confidenceUnstableStdDev) return _minConfidence;
    return (_minConfidence + _unstableConfidencePenalty).clamp(0.0, 1.0);
  }

  void _openActivationWindow() {
    _activationWindowTimer?.cancel();
    _activationWindowTimer = Timer(_activationWindow, () {
      if (!_isDisposed && !_isPaused && _status == VoiceRecognitionStatus.listening) {
        pauseListening();
      }
    });
    debugPrint('[VoiceRecognition][Metrics] activation window opened for ${_activationWindow.inSeconds}s '
        '(triggers=$_triggerCount, rejected=$_rejectedCount, duplicates=$_duplicateCount)');
  }

  void _logRejected(String words, double confidence, String reason) {
    _rejectedCount++;
    debugPrint('[VoiceRecognition][Metrics] rejected "$words" confidence=${confidence.toStringAsFixed(2)} '
        'reason=$reason (triggers=$_triggerCount, rejected=$_rejectedCount, duplicates=$_duplicateCount)');
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
      if (!kIsWeb) {
        _restartTimer = Timer(const Duration(seconds: 1), _restartBurst);
      } else {
        _status = VoiceRecognitionStatus.error;
      }
    }
  }
}
