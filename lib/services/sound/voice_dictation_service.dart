import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceDictationService {
  final SpeechToText _speech;
  bool _isInitialized = false;
  String _latestWords = '';
  String? _lastError;

  VoiceDictationService({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  String get latestWords => _latestWords.trim();
  String? get lastError => _lastError;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    final available = await _speech.initialize(
      onError: _onError,
      onStatus: (status) => debugPrint('[VoiceDictation] Status: $status'),
    );
    _isInitialized = available;
    if (!available) {
      _lastError = 'Speech recognition is not available';
    }
    return available;
  }

  Future<bool> start({String? localeId}) async {
    final ready = await initialize();
    if (!ready || _speech.isListening) return false;

    _latestWords = '';
    _lastError = null;
    try {
      await _speech.listen(
        onResult: _onResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(milliseconds: 1200),
        partialResults: true,
        localeId: localeId,
        listenMode: ListenMode.dictation,
      );
      return true;
    } catch (error) {
      _lastError = error.toString();
      debugPrint('[VoiceDictation] Start failed: $error');
      return false;
    }
  }

  Future<String> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    return latestWords;
  }

  Future<void> dispose() async {
    await _speech.stop();
  }

  void _onResult(SpeechRecognitionResult result) {
    if (result.recognizedWords.trim().isEmpty) return;
    _latestWords = result.recognizedWords.trim();
    debugPrint(
      '[VoiceDictation] Heard ${_latestWords.length} chars (final: ${result.finalResult})',
    );
  }

  void _onError(SpeechRecognitionError error) {
    _lastError = '${error.errorMsg}${error.permanent ? ' (permanent)' : ''}';
    debugPrint('[VoiceDictation] Error: $_lastError');
  }
}
