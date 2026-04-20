import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme.dart';

/// Shows download progress with real-time feedback
class AIModelDownloadProgress extends StatefulWidget {
  final Function(double) onProgress;
  final VoidCallback onComplete;

  const AIModelDownloadProgress({
    required this.onProgress,
    required this.onComplete,
    super.key,
  });

  @override
  State<AIModelDownloadProgress> createState() =>
      _AIModelDownloadProgressState();
}

class _AIModelDownloadProgressState extends State<AIModelDownloadProgress> {
  late Timer _timer;
  final Stopwatch _stopwatch = Stopwatch();
  double _progress = 0.0;
  double _speed = 0.0; // MB/s
  int _downloaded = 0; // MB
  final int _total = 2600; // MB (2.6GB)
  Duration _remainingTime = const Duration(minutes: 0);

  @override
  void initState() {
    super.initState();
    _simulateDownload();
  }

  void _simulateDownload() {
    _stopwatch
      ..reset()
      ..start();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_progress < 1.0) {
        // Simulate realistic download curve (faster at start, slower at end)
        final increment = ((1.0 - _progress) * 0.015) + 0.001;
        setState(() {
          _progress += increment;
          _downloaded = (_progress * _total).toInt();

          final elapsedSeconds = _stopwatch.elapsedMilliseconds / 1000.0;
          if (elapsedSeconds > 0) {
            _speed = _downloaded / elapsedSeconds;
          }

          if (_speed > 0) {
            final secondsRemaining = (_total - _downloaded) / _speed;
            _remainingTime = Duration(seconds: secondsRemaining.toInt());
          }
        });
        widget.onProgress(_progress.clamp(0.0, 1.0));
      } else {
        timer.cancel();
        _stopwatch.stop();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated circular progress
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, progress, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular progress
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: EchoColors.surfaceSecondary,
                        valueColor: AlwaysStoppedAnimation(
                          EchoColors.primary,
                        ),
                      ),
                    ),
                    // Center percentage
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Status text
            Text(
              '⏳ Downloading...',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),

            // Download size info
            Text(
              '$_downloaded MB / $_total MB',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EchoColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),

            // Linear progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: EchoColors.surfaceSecondary,
                valueColor: AlwaysStoppedAnimation(EchoColors.primary),
              ),
            ),
            const SizedBox(height: 16),

            // Speed and time remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Speed',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: EchoColors.textTertiary,
                          ),
                    ),
                    Text(
                      '${_speed.toStringAsFixed(1)} MB/s',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Est. Time',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: EchoColors.textTertiary,
                          ),
                    ),
                    Text(
                      _remainingTime.inMinutes > 0
                          ? '${_remainingTime.inMinutes}m ${_remainingTime.inSeconds % 60}s'
                          : '${_remainingTime.inSeconds}s',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EchoColors.surfaceTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: EchoColors.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keep app open or switch away. Download will continue.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: EchoColors.textTertiary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
