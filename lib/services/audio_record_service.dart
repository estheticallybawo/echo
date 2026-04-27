// lib/services/audio_recorder_service.dart

// ─────────────────────────────────────────────────────────────────────────────
//
// WHAT THIS FILE DOES
// ───────────────────
// Records microphone audio continuously in the background and maintains a
// rolling buffer of the last 30 seconds. When an emergency is activated,
// GemmaAnalysisService pulls the buffer and sends it to Gemma 4 E2B for
// distress analysis.
//
// WHY A PRE-ACTIVATION BUFFER?
// ────────────────────────────
// By the time the safety phrase is detected, the threatening event has
// already started. A 30-second rolling buffer means Guardian captures
// audio from BEFORE the phrase was spoken — including the lead-up to
// the emergency. Gemma 4 E2B analyses this context to improve accuracy.
//
// AUDIO SPECS
// ───────────
// Sample rate : 16,000 Hz (Gemma 4 E2B/E4B requirement)
// Channels    : mono (Gemma 4 processes single audio channel)
// Encoding    : 16-bit PCM (Flutter's record package default)
// Buffer size : 30 seconds = 480,000 samples at 16kHz
// Token cost  : 25 tokens/second × 30s = 750 tokens (Gemma 4 limit)
//
// PRIVACY
// ───────
// Audio never leaves the device unless the user explicitly activates an
// emergency. The buffer is in-memory only — nothing written to disk.
// Buffer is cleared when emergency is resolved.
//
// PUBSPEC DEPENDENCIES
// ─────────────────────
// record: ^5.1.0
// path_provider: ^2.1.0
// permission_handler: ^11.3.0
//
// ANDROID MANIFEST
// ─────────────────
// <uses-permission android:name="android.permission.RECORD_AUDIO"/>
// Must also be used with GuardianForegroundService to record in background.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// ─────────────────────────────────────────────────────────────────────────────
// AUDIO BUFFER
// ─────────────────────────────────────────────────────────────────────────────

/// A rolling in-memory buffer of raw 16kHz mono PCM audio samples.
///
/// Maintains at most [maxDurationSeconds] of audio. When full, oldest
/// samples are discarded (ring buffer behaviour via list truncation).
///
/// Used by GemmaAnalysisService to get the pre-activation audio clip
/// that Gemma 4 E2B analyses for distress signals.
class AudioBuffer {
  /// Maximum audio retained in the buffer. Matches Gemma 4's 30s audio limit.
  static const int maxDurationSeconds = 30;

  /// 16,000 Hz required by Gemma 4 E2B/E4B audio encoder.
  static const int sampleRateHz = 16000;

  /// Maximum samples: 30s × 16,000 samples/s = 480,000 samples.
  static const int maxSamples = maxDurationSeconds * sampleRateHz;

  /// Internal ring buffer. New samples are appended; old ones removed from front.
  final List<double> _samples = [];

  /// Wall-clock time of the first sample currently in the buffer.
  /// Used to calculate timestamp alignment with VoiceActivationEvent.
  DateTime? _bufferStart;

  /// Append new PCM samples to the buffer.
  ///
  /// Accepts raw 16-bit PCM bytes (from Flutter's record package) and
  /// converts to normalised float64 in range [-1.0, 1.0].
  ///
  /// If buffer would exceed [maxSamples], oldest samples are discarded.
  void appendPcm(Uint8List pcmBytes) {
    // Flutter record package gives us 16-bit little-endian PCM bytes.
    // Two bytes per sample → convert to normalised float.
    final newSamples = <double>[];
    for (int i = 0; i < pcmBytes.length - 1; i += 2) {
      // Reconstruct 16-bit signed integer from two bytes (little-endian).
      int sample = pcmBytes[i] | (pcmBytes[i + 1] << 8);
      // Sign-extend: values > 32767 are negative.
      if (sample > 32767) sample -= 65536;
      // Normalise to [-1.0, 1.0].
      newSamples.add(sample / 32768.0);
    }

    _samples.addAll(newSamples);

    // Trim to maxSamples — discard oldest audio.
    if (_samples.length > maxSamples) {
      final excess = _samples.length - maxSamples;
      _samples.removeRange(0, excess);
      // Adjust buffer start time to reflect discarded samples.
      _bufferStart = _bufferStart?.add(
        Duration(microseconds: (excess / sampleRateHz * 1e6).round()),
      );
    }

    // Set buffer start time on first append.
    _bufferStart ??= DateTime.now();
  }

  /// Get a copy of the buffered audio as a Float64List.
  ///
  /// Returns up to [maxDuration] seconds of the most recent audio.
  /// Gemma 4 expects a float array at 16kHz mono.
  Float64List getAudio({Duration? maxDuration}) {
    int sampleCount = _samples.length;

    if (maxDuration != null) {
      final maxSamplesForDuration = (maxDuration.inMilliseconds * sampleRateHz / 1000).round();
      sampleCount = sampleCount.clamp(0, maxSamplesForDuration);
    }

    // Return most recent [sampleCount] samples.
    final start = (_samples.length - sampleCount).clamp(0, _samples.length);
    return Float64List.fromList(_samples.sublist(start));
  }

  /// Duration of audio currently in the buffer.
  Duration get currentDuration => Duration(
    milliseconds: (_samples.length / sampleRateHz * 1000).round(),
  );

  /// True if there is enough audio for meaningful Gemma analysis (≥1 second).
  bool get hasAudio => _samples.length >= sampleRateHz;

  /// Timestamp of the first sample in the buffer. Null if buffer is empty.
  DateTime? get bufferStart => _bufferStart;

  /// Clear the buffer. Called after emergency is resolved to protect privacy.
  void clear() {
    _samples.clear();
    _bufferStart = null;
  }

  /// How many seconds ago does the buffer start relative to [referenceTime]?
  ///
  /// Used by GemmaAnalysisService to understand how far back the audio goes
  /// relative to when the safety phrase was detected.
  double secondsBeforeEvent(DateTime eventTime) {
    if (_bufferStart == null) return 0;
    return eventTime.difference(_bufferStart!).inMilliseconds / 1000.0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECORDER SERVICE
// ─────────────────────────────────────────────────────────────────────────────

/// States of the audio recorder.
enum RecorderStatus {
  /// Recorder has not been initialised.
  uninitialized,

  /// Permission granted, ready to record.
  ready,

  /// Actively recording and buffering audio.
  recording,

  /// Paused — used during UI interactions that need the mic (e.g. onboarding).
  paused,

  /// Permanent failure — permission denied or hardware error.
  error,
}

/// Guardian's audio capture service.
///
/// Continuously records microphone audio into [AudioBuffer] in the background.
/// When an emergency activates, GemmaAnalysisService reads the buffer to
/// get the pre-activation audio for Gemma 4 E2B distress analysis.
///
/// Must be used inside GuardianForegroundService on Android to record
/// when the app is in the background (required by Android 8+).
///
/// Typical usage:
/// ```dart
/// final recorder = AudioRecorderService();
/// await recorder.initialize();
/// await recorder.startRecording();
///
/// // On emergency:
/// final audioData = recorder.buffer.getAudio();
/// // Pass audioData to GemmaAnalysisService.analyseDistress()
///
/// // On emergency resolved:
/// recorder.buffer.clear();
/// ```
class AudioRecorderService {
  final AudioRecord _recorder = AudioRecord();

  RecorderStatus _status = RecorderStatus.uninitialized;

  /// The rolling audio buffer. Read by GemmaAnalysisService on emergency.
  final AudioBuffer buffer = AudioBuffer();

  /// Timer that periodically flushes audio data from the recorder into buffer.
  Timer? _flushTimer;

  /// Temporary file path used for streaming PCM from the record package.
  String? _tempFilePath;

  RecorderStatus get status => _status;
  bool get isRecording => _status == RecorderStatus.recording;

  /// Initialise the recorder and request microphone permission.
  ///
  /// Returns false if permission is denied. In that case, voice activation
  /// still works for safety phrase detection but Gemma analysis will have
  /// no audio to work with — the emergency pipeline still fires.
  Future<bool> initialize() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _status = RecorderStatus.error;
      debugPrint('[AudioRecorder] Microphone permission denied');
      return false;
    }

    // Create temp file path for streaming audio.
    final tempDir = await getTemporaryDirectory();
    _tempFilePath = '${tempDir.path}/guardian_buffer.pcm';

    _status = RecorderStatus.ready;
    debugPrint('[AudioRecorder] Initialised');
    return true;
  }

  /// Start continuous background recording into the rolling buffer.
  ///
  /// Records at 16kHz mono PCM — matching Gemma 4 E2B's audio requirements.
  /// Flushes audio to [buffer] every 500ms.
  Future<void> startRecording() async {
    if (_status != RecorderStatus.ready && _status != RecorderStatus.paused) return;

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits, // raw PCM, no compression
        sampleRate: 16000,               // Gemma 4 requirement
        numChannels: 1,                  // mono — Gemma 4 processes single channel
        bitRate: 16000 * 16,             // 16kHz × 16-bit
      ),
      path: _tempFilePath!,
    );

    _status = RecorderStatus.recording;

    // Flush recorded audio to buffer every 500ms.
    // This gives us ~500ms segments to work with, which is fine for
    // Gemma's 25-token/second audio encoding.
    _flushTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _flushToBuffer(),
    );

    debugPrint('[AudioRecorder] Recording started at 16kHz mono PCM');
  }

  /// Flush accumulated PCM data from the recorder into the AudioBuffer.
  ///
  /// Called periodically by [_flushTimer]. Reads whatever the recorder
  /// has written to the temp file since the last flush.
  Future<void> _flushToBuffer() async {
    if (_tempFilePath == null) return;

    try {
      final file = File(_tempFilePath!);
      if (!await file.exists()) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      // Append to rolling buffer.
      buffer.appendPcm(bytes);

      // Clear the temp file after reading — prevents unbounded growth.
      await file.writeAsBytes([]);

    } catch (e) {
      debugPrint('[AudioRecorder] Flush error: $e');
    }
  }

  /// Stop recording. Buffer contents are preserved for Gemma analysis.
  ///
  /// Call this when the emergency pipeline no longer needs new audio.
  /// Buffer is cleared separately via buffer.clear() after analysis.
  Future<void> stopRecording() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    _status = RecorderStatus.ready;
    debugPrint('[AudioRecorder] Stopped | '
        'buffer: ${buffer.currentDuration.inSeconds}s');
  }

  /// Temporarily pause recording (e.g. during voice onboarding page).
  Future<void> pauseRecording() async {
    if (_status != RecorderStatus.recording) return;
    _flushTimer?.cancel();
    await _recorder.pause();
    _status = RecorderStatus.paused;
    debugPrint('[AudioRecorder] Paused');
  }

  /// Resume recording after a pause.
  Future<void> resumeRecording() async {
    if (_status != RecorderStatus.paused) return;
    await _recorder.resume();
    _status = RecorderStatus.recording;
    _flushTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _flushToBuffer(),
    );
    debugPrint('[AudioRecorder] Resumed');
  }

  /// Release resources. Call when app is closing.
  Future<void> dispose() async {
    _flushTimer?.cancel();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _recorder.dispose();
    buffer.clear();

    // Clean up temp file.
    if (_tempFilePath != null) {
      final file = File(_tempFilePath!);
      if (await file.exists()) await file.delete();
    }

    debugPrint('[AudioRecorder] Disposed');
  }
}