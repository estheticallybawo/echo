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

  static const String _elevenLabsProxyUrl = String.fromEnvironment(
    'ELEVENLABS_PROXY_URL',
    defaultValue: '',
  );
  static const String _defaultVoiceId = String.fromEnvironment(
    'ELEVENLABS_VOICE_ID',
    defaultValue: 'pNInz6obpgDQGcFmaJgB',
  );
  String? _sessionToken;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _cloudProcessingEnabled = false;

  /// Configure an ephemeral backend-issued token for cloud TTS.
  /// Do not pass long-lived provider API keys to the client.
  void configureCloudTtsSession({
    required String sessionToken,
    String? voiceId,
  }) {
    _sessionToken = sessionToken.trim().isEmpty ? null : sessionToken.trim();
    if (voiceId != null && voiceId.trim().isNotEmpty) {
      _selectedVoiceId = voiceId.trim();
    }
  }

  void setCloudProcessingEnabled(bool enabled) {
    _cloudProcessingEnabled = enabled;
  }

  String _selectedVoiceId = _defaultVoiceId;

  /// Initialize TTS engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(0.92);
      await _flutterTts.setSpeechRate(0.46);

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
        debugPrint('🔊 Local TTS playback started');
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
    if (!_cloudProcessingEnabled) {
      return false;
    }

    final token = _sessionToken;
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      if (_elevenLabsProxyUrl.isEmpty) {
        debugPrint(
          '⚠️ ElevenLabs proxy URL is not configured; using local TTS fallback',
        );
        return false;
      }

      final response = await http.post(
        Uri.parse(_elevenLabsProxyUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'audio/mpeg',
        },
        body:
            '{"text":${_jsonEscape(text)},"voice_id":${_jsonEscape(_selectedVoiceId)},"model_id":"eleven_multilingual_v2","voice_settings":{"stability":0.72,"similarity_boost":0.82,"style":0.08,"use_speaker_boost":true}}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '⚠️ ElevenLabs request failed: ${response.statusCode} ${response.body}',
        );
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
      debugPrint('🔊 Cloud TTS playback completed');
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
