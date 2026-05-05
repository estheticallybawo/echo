import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class AudioBuffer {
  static const int maxDurationSeconds = 30;
  static const int sampleRateHz = 16000;
  static const int maxSamples = maxDurationSeconds * sampleRateHz;

  final List<double> _samples = [];
  DateTime? _bufferStart;

  void appendPcm(Uint8List pcmBytes) {
    final newSamples = <double>[];
    for (var i = 0; i < pcmBytes.length - 1; i += 2) {
      var sample = pcmBytes[i] | (pcmBytes[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      newSamples.add(sample / 32768.0);
    }

    _samples.addAll(newSamples);

    if (_samples.length > maxSamples) {
      final excess = _samples.length - maxSamples;
      _samples.removeRange(0, excess);
      _bufferStart = _bufferStart?.add(
        Duration(microseconds: (excess / sampleRateHz * 1000000).round()),
      );
    }

    _bufferStart ??= DateTime.now();
  }

  Float64List getAudio({Duration? maxDuration}) {
    var sampleCount = _samples.length;
    if (maxDuration != null) {
      final maxSamplesForDuration =
          (maxDuration.inMilliseconds * sampleRateHz / 1000).round();
      sampleCount = sampleCount.clamp(0, maxSamplesForDuration);
    }

    final start = (_samples.length - sampleCount).clamp(0, _samples.length);
    return Float64List.fromList(_samples.sublist(start));
  }

  Duration get currentDuration =>
      Duration(milliseconds: (_samples.length / sampleRateHz * 1000).round());

  bool get hasAudio => _samples.length >= sampleRateHz;

  DateTime? get bufferStart => _bufferStart;

  void clear() {
    _samples.clear();
    _bufferStart = null;
  }

  double secondsBeforeEvent(DateTime eventTime) {
    if (_bufferStart == null) return 0;
    return eventTime.difference(_bufferStart!).inMilliseconds / 1000.0;
  }
}

enum RecorderStatus {
  uninitialized,
  ready,
  recording,
  paused,
  error,
}

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioBuffer buffer = AudioBuffer();

  RecorderStatus _status = RecorderStatus.uninitialized;
  StreamSubscription<Uint8List>? _recordStreamSubscription;

  RecorderStatus get status => _status;
  bool get isRecording => _status == RecorderStatus.recording;

  Future<bool> initialize() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _status = RecorderStatus.error;
      debugPrint('[AudioRecorder] Microphone permission denied');
      return false;
    }

    _status = RecorderStatus.ready;
    debugPrint('[AudioRecorder] Initialised');
    return true;
  }

  Future<void> startRecording() async {
    if (_status != RecorderStatus.ready && _status != RecorderStatus.paused) {
      return;
    }

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 16000 * 16,
      ),
    );

    await _recordStreamSubscription?.cancel();
    _recordStreamSubscription = stream.listen(
      buffer.appendPcm,
      onError: (error) => debugPrint('[AudioRecorder] Stream error: $error'),
    );

    _status = RecorderStatus.recording;
    debugPrint('[AudioRecorder] Recording started at 16kHz mono PCM');
  }

  Future<void> stopRecording() async {
    await _recordStreamSubscription?.cancel();
    _recordStreamSubscription = null;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    _status = RecorderStatus.ready;
    debugPrint('[AudioRecorder] Stopped | buffer: ${buffer.currentDuration.inSeconds}s');
  }

  Future<void> pauseRecording() async {
    if (_status != RecorderStatus.recording) return;
    await _recorder.pause();
    _status = RecorderStatus.paused;
    debugPrint('[AudioRecorder] Paused');
  }

  Future<void> resumeRecording() async {
    if (_status != RecorderStatus.paused) return;
    await _recorder.resume();
    _status = RecorderStatus.recording;
    debugPrint('[AudioRecorder] Resumed');
  }

  Future<void> dispose() async {
    await _recordStreamSubscription?.cancel();
    _recordStreamSubscription = null;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    await _recorder.dispose();
    buffer.clear();

    debugPrint('[AudioRecorder] Disposed');
  }
}