
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

/// Simple TTS wrapper service for speaking diversion and other safety messages
class TTSService {
  static final TTSService _instance = TTSService._internal();

  factory TTSService() {
    return _instance;
  }

  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const String _elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1/text-to-speech';
  static const String _defaultVoiceId = String.fromEnvironment(
    'ELEVENLABS_VOICE_ID',
    defaultValue: '21m00Tcm4TlvDq8ikWAM',
  );
  static const String _apiKeyFromEnvironment = String.fromEnvironment(
    'ELEVENLABS_API_KEY',
    defaultValue: '',
  );

  String? _apiKey = _apiKeyFromEnvironment.isEmpty ? null : _apiKeyFromEnvironment;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Configure ElevenLabs at runtime if you do not want to use --dart-define.
  void configureElevenLabs({
    required String apiKey,
    String? voiceId,
  }) {
    _apiKey = apiKey.trim().isEmpty ? null : apiKey.trim();
    if (voiceId != null && voiceId.trim().isNotEmpty) {
      _selectedVoiceId = voiceId.trim();
    }
  }

  String _selectedVoiceId = _defaultVoiceId;

  /// Initialize TTS engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(0.8);  // Deeper, more authoritative voice
      await _flutterTts.setSpeechRate(0.4);  // Slower, clearer speech
      await _flutterTts.setVolume(1.0);  // Full volume

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

      final playedViaElevenLabs = await _speakWithElevenLabs(text);
      if (!playedViaElevenLabs) {
        await _flutterTts.speak(text);
        debugPrint('🔊 Local TTS: Speaking "$text"');
      }
    } catch (e) {
      _isSpeaking = false;
      debugPrint('❌ TTS speak error: $e');
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
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
    debugPrint('ℹ️ TTS resume is not supported by this FlutterTts version');
  }

  Future<bool> _speakWithElevenLabs(String text) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_elevenLabsBaseUrl/text-to-speech/$_selectedVoiceId/stream'),
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
          'Accept': 'audio/mpeg',
        },
        body: '{"text":${_jsonEscape(text)},"model_id":"eleven_multilingual_v2","voice_settings":{"stability":0.4,"similarity_boost":0.8,"style":0.2,"use_speaker_boost":true}}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('⚠️ ElevenLabs request failed: ${response.statusCode} ${response.body}');
        return false;
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        debugPrint('⚠️ ElevenLabs returned empty audio');
        return false;
      }

      await _audioPlayer.play(BytesSource(Uint8List.fromList(bytes)));
      await _audioPlayer.onPlayerComplete.first;
      _isSpeaking = false;
      debugPrint('🔊 ElevenLabs: Speaking "$text"');
      return true;
    } catch (e) {
      debugPrint('⚠️ ElevenLabs TTS failed, falling back to local TTS: $e');
      return false;
    }
  }

  String _jsonEscape(String value) {
    return '"${value.replaceAll(r'\\', r'\\\\').replaceAll('"', r'\\"').replaceAll('\n', r'\\n')}"';
  }
}
