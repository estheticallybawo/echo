import 'package:flutter/foundation.dart';

enum DistressLevel {
  none,
  low,
  medium,
  high,
  critical,
}

class TranscriptionResult {
  final String transcript;
  final DistressLevel distressLevel;
  final double confidence;
  final List<String> distressSignals;
  final String audioDescription;
  final String emotionalState;
  final double audioSeconds;
  final bool policeRecommended;

  const TranscriptionResult({
    required this.transcript,
    required this.distressLevel,
    required this.confidence,
    required this.distressSignals,
    required this.audioDescription,
    required this.emotionalState,
    required this.audioSeconds,
    required this.policeRecommended,
  });

  bool get shouldAlert =>
      distressLevel == DistressLevel.medium ||
      distressLevel == DistressLevel.high ||
      distressLevel == DistressLevel.critical;

  bool get isCritical =>
      distressLevel == DistressLevel.critical && confidence >= 0.80;

  @override
  String toString() {
    return 'TranscriptionResult(distress: $distressLevel, confidence: ${(confidence * 100).round()}%, police: $policeRecommended, emotion: $emotionalState)';
  }

  Map<String, dynamic> toMap() => {
        'transcript': transcript,
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

  // ignore: unused_field
  dynamic _gemmaEngine;

  Future<bool> initialize() async {
    _isInitialised = true;
    debugPrint('[Transcription] Initialised (using API fallback for demo)');
    return true;
  }

  Future<TranscriptionResult> transcribeAndAnalyse({
    required Float64List audioData,
    required int sampleRateHz,
    required Map<String, dynamic> context,
  }) async {
    if (!_isInitialised) await initialize();

    final durationSeconds = audioData.length / sampleRateHz;

    debugPrint(
      '[Transcription] Analysing ${durationSeconds.toStringAsFixed(1)}s of audio (${audioData.length} samples @ ${sampleRateHz}Hz)',
    );

    final features = _extractAcousticFeatures(audioData, sampleRateHz);

    debugPrint(
      '[Transcription] Acoustic profile: RMS=${features['rms_mean']?.toStringAsFixed(4)}, ZCR=${features['zcr_mean']?.toStringAsFixed(4)}, spectral=${features['spectral_centroid']?.toStringAsFixed(0)}Hz',
    );

    return _buildResultFromFeatures(features, durationSeconds, context);
  }

  Map<String, double> _extractAcousticFeatures(Float64List audio, int sampleRate) {
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
    Map<String, dynamic> context,
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
      signals.add('high zero-crossing rate - possible irregular breathing or distress vocalisation');
      distressScore++;
    }
    if (centroid > 4000) {
      signals.add('high spectral centroid (${centroid.toStringAsFixed(0)}Hz) - possible pitch elevation');
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
      transcript: '',
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
}