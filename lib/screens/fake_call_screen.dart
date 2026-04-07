import 'package:flutter/material.dart';
import 'dart:async';
import '../theme.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  bool _callActive = false;
  int _callDuration = 0;
  late Timer _callTimer;

  @override
  void dispose() {
    if (_callActive) {
      _callTimer.cancel();
    }
    super.dispose();
  }

  void _startFakeCall() {
    setState(() {
      _callActive = true;
      _callDuration = 0;
    });

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  void _endFakeCall() {
    setState(() {
      _callActive = false;
    });
    if (_callActive) {
      _callTimer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_callActive) {
      return _buildActiveCallScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fake Call'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instant Escape',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Fake an incoming call to leave discreetly',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: GuardianColors.textTertiary,
              ),
            ),
            const SizedBox(height: 48),

            // Caller options
            Text(
              'Choose Caller',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...['Mom', 'Sister', 'Best Friend', 'Work'].map((caller) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    _startFakeCall();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GuardianColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: GuardianColors.textPrimary.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GuardianColors.surfaceTertiary,
                          ),
                          child: const Center(
                            child: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                caller,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Call in 2 seconds',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: GuardianColors.textTertiary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 48),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GuardianColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it works',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...[
                    'Fake call appears immediately',
                    'Answer to hear pre-recorded greeting',
                    'Create an exit from unsafe situation',
                    'No notification to caller',
                  ].map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check,
                              color: GuardianColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: GuardianColors.textSecondary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the active fake call screen
  Widget _buildActiveCallScreen() {
    final minutes = _callDuration ~/ 60;
    final seconds = _callDuration % 60;
    final durationText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: GuardianColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GuardianColors.surfaceSecondary,
              ),
              child: const Center(
                child: Icon(Icons.person, size: 60),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Mom',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: GuardianColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              durationText,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: GuardianColors.textSecondary,
              ),
            ),
            const SizedBox(height: 80),

            // End call button
            GestureDetector(
              onTap: _endFakeCall,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GuardianColors.warning,
                ),
                child: const Center(
                  child: Icon(Icons.call_end, color: Colors.white, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
