import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum DistressLevel {
  none,
  low,
  medium,
  high,
  critical,
}

class TranscriptionSegment {
  final String text;
  final double? confidence;
  final double? startSeconds;
  final double? endSeconds;

  const TranscriptionSegment({
    required this.text,
    this.confidence,
    this.startSeconds,
    this.endSeconds,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'confidence': confidence,
        'start_seconds': startSeconds,
        'end_seconds': endSeconds,
      };
}

class ProviderTranscriptionResult {
  final String transcript;
  final bool available;
  final double? confidence;
  final List<TranscriptionSegment> segments;
  final String provider;

  const ProviderTranscriptionResult({
    required this.transcript,
    required this.available,
    this.confidence,
    this.segments = const [],
    this.provider = 'none',
  });

  const ProviderTranscriptionResult.unavailable({String provider = 'none'})
      : transcript = '',
        available = false,
        confidence = null,
        segments = const [],
        provider = provider;
}

abstract class TranscriptionProvider {
  Future<ProviderTranscriptionResult> transcribe({
    required Float64List audioData,
    required int sampleRateHz,
    required String locale,
    required Map<String, dynamic> context,
  });
}

class WavAudioEncoder {
  const WavAudioEncoder._();

  static Uint8List encodePcm16(Float64List audioData, int sampleRateHz) {
    final pcm = Int16List(audioData.length);
    for (var i = 0; i < audioData.length; i++) {
      final sample = (audioData[i].clamp(-1.0, 1.0) * 32767).round();
      pcm[i] = sample;
    }

    final dataLength = pcm.length * 2;
    final buffer = BytesBuilder();

    void writeString(String value) => buffer.add(ascii.encode(value));
    void write32(int value) {
      final bytes = Uint8List(4);
      bytes.buffer.asByteData().setUint32(0, value, Endian.little);
      buffer.add(bytes);
    }

    void write16(int value) {
      final bytes = Uint8List(2);
      bytes.buffer.asByteData().setUint16(0, value, Endian.little);
      buffer.add(bytes);
    }

    writeString('RIFF');
    write32(36 + dataLength);
    writeString('WAVE');
    writeString('fmt ');
    write32(16);
    write16(1);
    write16(1);
    write32(sampleRateHz);
    write32(sampleRateHz * 2);
    write16(2);
    write16(16);
    writeString('data');
    write32(dataLength);
    buffer.add(pcm.buffer.asUint8List());

    return buffer.toBytes();
  }
}

class GemmaAudioUnderstandingProvider implements TranscriptionProvider {
  static const String defaultProxyUrl = String.fromEnvironment(
    'GEMMA_AUDIO_PROXY_URL',
    defaultValue: 'http://localhost:8788/audio/analyze',
  );

  final http.Client _client;
  final String proxyUrl;

  GemmaAudioUnderstandingProvider({
    http.Client? client,
    String proxyUrl = defaultProxyUrl,
  })  : _client = client ?? http.Client(),
        proxyUrl = proxyUrl.trim();

  @override
  Future<ProviderTranscriptionResult> transcribe({
    required Float64List audioData,
    required int sampleRateHz,
    required String locale,
    required Map<String, dynamic> context,
  }) async {
    if (proxyUrl.isEmpty) {
      return const ProviderTranscriptionResult.unavailable(
        provider: 'gemma_audio',
      );
    }

    final wavBytes = WavAudioEncoder.encodePcm16(audioData, sampleRateHz);
    final prompt =
        (context['gemma_audio_prompt'] as String?)?.trim().isNotEmpty == true
            ? (context['gemma_audio_prompt'] as String).trim()
            : 'Listen to this emergency audio. Return a concise safety summary, any words you can identify, the threat level, and the recommended next action.';

    final response = await _client
        .post(
          Uri.parse(proxyUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'audio_base64': base64Encode(wavBytes),
            'format': 'wav',
            'sample_rate_hz': sampleRateHz,
            'locale': locale,
            'prompt': prompt,
            'context': context,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gemma audio proxy failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractContent(decoded);

    return ProviderTranscriptionResult(
      transcript: content,
      available: content.isNotEmpty,
      confidence: (decoded['confidence'] as num?)?.toDouble(),
      provider: (decoded['provider'] as String?) ?? 'gemma_audio',
    );
  }

  String _extractContent(Map<String, dynamic> decoded) {
    for (final key in ['transcript', 'summary', 'analysis', 'content', 'text']) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }
}

class TranscriptionResult {
  final String transcript;
  final bool transcriptAvailable;
  final String transcriptProvider;
  final double? transcriptConfidence;
  final List<TranscriptionSegment> transcriptSegments;
  final DistressLevel distressLevel;
  final double confidence;
  final List<String> distressSignals;
  final String audioDescription;
  final String emotionalState;
  final double audioSeconds;
  final bool policeRecommended;

  const TranscriptionResult({
    required this.transcript,
    required this.transcriptAvailable,
    required this.transcriptProvider,
    required this.transcriptSegments,
    required this.distressLevel,
    required this.confidence,
    required this.distressSignals,
    required this.audioDescription,
    required this.emotionalState,
    required this.audioSeconds,
    required this.policeRecommended,
    this.transcriptConfidence,
  });

  bool get shouldAlert =>
      distressLevel == DistressLevel.medium ||
      distressLevel == DistressLevel.high ||
      distressLevel == DistressLevel.critical;

  bool get isCritical =>
      distressLevel == DistressLevel.critical && confidence >= 0.80;

  @override
  String toString() {
    return 'TranscriptionResult(distress: $distressLevel, confidence: ${(confidence * 100).round()}%, transcriptAvailable: $transcriptAvailable, police: $policeRecommended, emotion: $emotionalState)';
  }

  Map<String, dynamic> toMap() => {
        'transcript': transcript,
        'transcript_available': transcriptAvailable,
        'transcript_provider': transcriptProvider,
        'transcript_confidence': transcriptConfidence,
        'transcript_segments': transcriptSegments.map((s) => s.toMap()).toList(),
        'distress_level': distressLevel.name,
        'confidence': confidence,
        'distress_signals': distressSignals,
        'audio_description': audioDescription,
        'emotional_state': emotionalState,
        'audio_seconds': audioSeconds,
        'police_recommended': policeRecommended,
      };
}

class SpeechTranscriptionService {
  bool _isInitialised = false;
  final List<TranscriptionProvider> _providers;
  final Duration _sttTimeout;
  bool _saveVoiceSnippets = false;

  SpeechTranscriptionService({
    List<TranscriptionProvider>? providers,
    Duration sttTimeout = const Duration(minutes: 12),
  })  : _providers = providers ?? [GemmaAudioUnderstandingProvider()],
        _sttTimeout = sttTimeout;

  Future<bool> initialize() async {
    _isInitialised = true;
    debugPrint('[Transcription] Initialised (Gemma audio-context/acoustic mode)');
    return true;
  }

  Future<TranscriptionResult> transcribeAndAnalyse({
    required Float64List audioData,
    required int sampleRateHz,
    required Map<String, dynamic> context,
  }) async {
    if (!_isInitialised) await initialize();

    final durationSeconds = audioData.length / sampleRateHz;
    final locale = (context['locale'] as String?) ?? 'en_US';
    final workingAudio = Float64List.fromList(audioData);
    final features = _extractAcousticFeatures(audioData, sampleRateHz);
    final sttResult = await _transcribeWithFallback(
      audioData: audioData,
      sampleRateHz: sampleRateHz,
      locale: locale,
      context: context,
    );
    debugPrint(
      '[Transcription] Analysing ${durationSeconds.toStringAsFixed(1)}s audio segment',
    );

    if (!_saveVoiceSnippets) {
      for (var i = 0; i < workingAudio.length; i++) {
        workingAudio[i] = 0.0;
      }
    }

    return _buildResultFromFeatures(
      features,
      durationSeconds,
      sttResult,
    );
  }

  Future<ProviderTranscriptionResult> _transcribeWithFallback({
    required Float64List audioData,
    required int sampleRateHz,
    required String locale,
    required Map<String, dynamic> context,
  }) async {
    if (_providers.isEmpty) {
      debugPrint(
        '[Transcription] No external STT provider configured; using audio features and Gemma-ready WAV context.',
      );
      return const ProviderTranscriptionResult.unavailable(
        provider: 'audio_context',
      );
    }

    for (final provider in _providers) {
      try {
        final result = await provider
            .transcribe(
              audioData: audioData,
              sampleRateHz: sampleRateHz,
              locale: locale,
              context: context,
            )
            .timeout(_sttTimeout);

        if (result.available && result.transcript.isNotEmpty) {
          return result;
        }
      } on TimeoutException {
        debugPrint(
          '[Transcription] Audio provider timed out. Falling back to acoustic-only mode.',
        );
      } catch (error) {
        debugPrint(
          '[Transcription] Audio provider failed: $error. Falling back to acoustic-only mode.',
        );
      }
    }

    return const ProviderTranscriptionResult.unavailable();
  }

  Map<String, double> _extractAcousticFeatures(
    Float64List audio,
    int sampleRate,
  ) {
    if (audio.isEmpty) {
      return {
        'rms_mean': 0,
        'rms_max': 0,
        'zcr_mean': 0,
        'spectral_centroid': 0,
      };
    }

    final frameSize = (0.025 * sampleRate).round();
    final rmsValues = <double>[];

    for (var i = 0; i + frameSize <= audio.length; i += frameSize) {
      var sumSq = 0.0;
      for (var j = i; j < i + frameSize; j++) {
        sumSq += audio[j] * audio[j];
      }
      rmsValues.add(sumSq / frameSize);
    }

    final rmsMean = rmsValues.isEmpty
        ? 0.0
        : rmsValues.reduce((a, b) => a + b) / rmsValues.length;
    final rmsMax = rmsValues.isEmpty
        ? 0.0
        : rmsValues.reduce((a, b) => a > b ? a : b);

    var zcrCount = 0;
    for (var i = 1; i < audio.length; i++) {
      if ((audio[i] >= 0) != (audio[i - 1] >= 0)) zcrCount++;
    }
    final zcrMean = audio.length > 1 ? zcrCount / (audio.length - 1) : 0.0;
    final spectralCentroid = zcrMean * sampleRate / 2;

    return {
      'rms_mean': rmsMean,
      'rms_max': rmsMax,
      'zcr_mean': zcrMean,
      'spectral_centroid': spectralCentroid,
    };
  }

  TranscriptionResult _buildResultFromFeatures(
    Map<String, double> features,
    double durationSeconds,
    ProviderTranscriptionResult sttResult,
  ) {
    final rms = features['rms_mean'] ?? 0.0;
    final rmsMax = features['rms_max'] ?? 0.0;
    final zcr = features['zcr_mean'] ?? 0.0;
    final centroid = features['spectral_centroid'] ?? 0.0;

    final signals = <String>[];
    var distressScore = 0;

    if (rms > 0.02) {
      signals.add('elevated RMS energy (${rms.toStringAsFixed(4)})');
      distressScore++;
    }
    if (rmsMax > 0.10) {
      signals.add('high peak energy - possible raised voice or screaming');
      distressScore++;
    }
    if (zcr > 0.10) {
      signals.add(
        'high zero-crossing rate - possible irregular breathing or distress vocalisation',
      );
      distressScore++;
    }
    if (centroid > 4000) {
      signals.add(
        'high spectral centroid (${centroid.toStringAsFixed(0)}Hz) - possible pitch elevation',
      );
      distressScore++;
    }

    final level = switch (distressScore) {
      0 => DistressLevel.none,
      1 => DistressLevel.low,
      2 => DistressLevel.medium,
      3 => DistressLevel.high,
      _ => DistressLevel.critical,
    };

    final durationFactor = (durationSeconds / 5.0).clamp(0.3, 1.0);
    final confidence = (distressScore / 4.0 * durationFactor).clamp(0.1, 0.95);

    return TranscriptionResult(
      transcript: sttResult.transcript,
      transcriptAvailable: sttResult.available,
      transcriptProvider: sttResult.provider,
      transcriptConfidence: sttResult.confidence,
      transcriptSegments: sttResult.segments,
      distressLevel: level,
      confidence: confidence,
      distressSignals: signals,
      audioDescription:
          '${durationSeconds.toStringAsFixed(1)}s audio. Acoustic profile: RMS=${rms.toStringAsFixed(4)}, ZCR=${zcr.toStringAsFixed(4)}, centroid=${centroid.toStringAsFixed(0)}Hz.',
      emotionalState: distressScore >= 2 ? 'distressed' : 'unknown',
      audioSeconds: durationSeconds,
      policeRecommended:
          level == DistressLevel.high || level == DistressLevel.critical,
    );
  }

  void dispose() {
    _isInitialised = false;
    debugPrint('[Transcription] Disposed');
  }

  void setSaveVoiceSnippetsEnabled(bool enabled) {
    _saveVoiceSnippets = enabled;
  }
}
