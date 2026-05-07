import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Simple TTS wrapper service for speaking diversion and other safety messages
class TTSService {
  static final TTSService _instance = TTSService._internal();

  factory TTSService() {
    return _instance;
  }

  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Initialize TTS engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);

      // Listen for completion
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _isInitialized = true;
      debugPrint('✅ TTS service initialized');
      return true;
    } catch (e) {
      debugPrint('❌ TTS initialization error: $e');
      return false;
    }
  }

  /// Speak text immediately
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) {
      debugPrint('⚠️ TTS: Empty text, skipping');
      return;
    }

    try {
      _isSpeaking = true;
      await _flutterTts.speak(text);
      debugPrint('🔊 TTS: Speaking "$text"');
    } catch (e) {
      _isSpeaking = false;
      debugPrint('❌ TTS speak error: $e');
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('❌ TTS stop error: $e');
    }
  }

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Pause speech
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('❌ TTS pause error: $e');
    }
  }

  /// Resume speech
  Future<void> resume() async {
    try {
      await _flutterTts.resume();
    } catch (e) {
      debugPrint('❌ TTS resume error: $e');
    }
  }
}
