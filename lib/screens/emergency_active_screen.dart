// ignore_for_file: deprecated_member_use, duplicate_ignore, unused_field

import 'package:flutter/material.dart';
import 'dart:async';
import '../theme.dart';

class EmergencyActiveScreen extends StatefulWidget {
  const EmergencyActiveScreen({super.key});

  @override
  State<EmergencyActiveScreen> createState() => _EmergencyActiveScreenState();
}

class _EmergencyActiveScreenState extends State<EmergencyActiveScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _timerController;
  late Timer _elapsedTimer;
  int _elapsedSeconds = 0;

  // Simulated Gemma 4 AI stream
  late Stream<String> _aiAnalysisStream;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Elapsed timer
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });

    // Simulate Gemma 4 AI analysis stream
    _aiAnalysisStream = _generateAIAnalysis();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _elapsedTimer.cancel();
    super.dispose();
  }

  /// Simulate streaming text from Gemma 4 AI
  Stream<String> _generateAIAnalysis() async* {
    final analysisText = '''User location: Confirmed. 
Recording: Active (audio + metadata).
Proximity alerts: 3 contacts notified.
Police dispatch: Queued for operator.
Real-time analysis: Assessing environment audio for threat patterns...''';

    for (int i = 0; i < analysisText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      yield analysisText.substring(0, i + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Active'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Recording Timer with Pulsing Ring
              _buildRecordingTimer(),
              const SizedBox(height: 32),

              // Live Status Column
              _buildLiveStatusColumn(),
              const SizedBox(height: 32),

              // Gemma 4 AI Analysis Card
              _buildAIAnalysisCard(),
              const SizedBox(height: 32),

              // Cancel Button
              _buildCancelButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Recording timer with pulsing ring animation
  Widget _buildRecordingTimer() {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    final timerText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 200,
        height: 200,
            
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: GuardianColors.warning.withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 20,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing ring
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: GuardianColors.warning,
                  width: 3,
                ),
              ),
            ),

            // Inner circle
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GuardianColors.warning.withOpacity(0.1),
                border: Border.all(
                  color: GuardianColors.warning.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'RECORDING',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: GuardianColors.warning,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timerText,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: GuardianColors.warning,
                      fontWeight: FontWeight.w700,
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

  /// Live status column showing recording/location/alert states
  Widget _buildLiveStatusColumn() {
    const statusItems = [
      {
        'icon': Icons.mic,
        'label': 'Audio Recording',
        'status': 'ACTIVE',
        'color': GuardianColors.success,
      },
      {
        'icon': Icons.location_on_outlined,
        'label': 'Location',
        'status': 'LOCKED',
        'color': GuardianColors.primary,
      },
      {
        'icon': Icons.notifications_active_outlined,
        'label': 'Alerts Sent',
        'status': '3 CONTACTS',
        'color': GuardianColors.primary,
      },
      {
        'icon': Icons.phone_in_talk_outlined,
        'label': 'Police Dispatch',
        'status': 'PENDING',
        'color': GuardianColors.warning,
      },
    ];

    return Column(
      children: statusItems.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
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
                Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['label'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: GuardianColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  item['status'] as String,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: item['color'] as Color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Gemma 4 AI Analysis Card with progressive text typing
  Widget _buildAIAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GuardianColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GuardianColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                color: GuardianColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Gemma 4 Analysis',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: GuardianColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // StreamBuilder for progressive text
          StreamBuilder<String>(
            stream: _aiAnalysisStream,
            initialData: '',
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: GuardianColors.textSecondary,
                  height: 1.6,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Cancel Emergency Button
  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: GuardianColors.surfaceSecondary,
              title: Text(
                'Cancel Emergency?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: GuardianColors.textPrimary,
                ),
              ),
              content: Text(
                'Are you sure? Recording and alerts will stop.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: GuardianColors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Keep Recording'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/home');
                  },
                  child: Text(
                    'Cancel Emergency',
                    style: TextStyle(color: GuardianColors.warning),
                  ),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.close),
        label: const Text('STOP EMERGENCY'),
        style: ElevatedButton.styleFrom(
          backgroundColor: GuardianColors.warning.withOpacity(0.15),
          foregroundColor: GuardianColors.warning,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
