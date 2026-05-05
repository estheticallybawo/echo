import 'package:flutter/material.dart';
import '../services/escalation_timer_service.dart';
import '../theme.dart';

/// Escalation Countdown Widget - Track C
/// Displays real-time escalation timer during emergency
/// Shows tier progression and remaining time
class EscalationCountdownWidget extends StatefulWidget {
  final String incidentId;
  final VoidCallback onTier1Activate;
  final VoidCallback onTier2Escalate;
  final VoidCallback onTier1Nudge;
  final VoidCallback onTier3Escalate;
  final VoidCallback? onEscalationStop;

  const EscalationCountdownWidget({
    super.key,
    required this.incidentId,
    required this.onTier1Activate,
    required this.onTier2Escalate,
    required this.onTier1Nudge,
    required this.onTier3Escalate,
    this.onEscalationStop,
  });

  @override
  State<EscalationCountdownWidget> createState() =>
      _EscalationCountdownWidgetState();
}

class _EscalationCountdownWidgetState extends State<EscalationCountdownWidget>
    with TickerProviderStateMixin {
  late EscalationTimerService _timerService;
  late AnimationController _pulseController;
  late AnimationController _tierChangeController;

  @override
  void initState() {
    super.initState();
    _timerService = EscalationTimerService();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _tierChangeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Start the escalation timer
    _timerService.startEscalation(
      incidentId: widget.incidentId,
      onTier1Activate: widget.onTier1Activate,
      onTier2Escalate: widget.onTier2Escalate,
      onTier3Escalate: widget.onTier3Escalate,
    );

    // Listen for updates
    setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tierChangeController.dispose();
    super.dispose();
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1:
        return const Color(0xFF06B6D4); // Cyan
      case 2:
        return const Color(0xFFF59E0B); // Amber
      case 3:
        return const Color(0xFFEF4444); // Red
      default:
        return EchoColors.primary;
    }
  }

  String _getTierLabel(int tier) {
    switch (tier) {
      case 1:
        return 'TIER 1: Inner Circle Alerted';
      case 2:
        return 'TIER 2: Extended Network Active';
      case 3:
        return 'TIER 3: Public Amplification';
      default:
        return 'Standby';
    }
  }

  String _getTimeRemaining() {
    final remaining = _timerService.secondsRemaining;
    final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final tier = _timerService.currentTier;
        final tierColor = _getTierColor(tier);
        final progress = _timerService.progressPercentage / 100;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tier Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tierColor.withOpacity(0.3),
                  width: 2,
                ),
                color: tierColor.withOpacity(0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tier Label
                  Text(
                    _getTierLabel(tier),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tierColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Countdown Timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTimeRemaining(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: tierColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                      // Pulse indicator
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.2)
                            .animate(_pulseController),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tierColor,
                            boxShadow: [
                              BoxShadow(
                                color: tierColor.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: tierColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tier Timeline
            _buildTierTimeline(tier, tierColor),
            const SizedBox(height: 16),

            // Status Message
            _buildStatusMessage(tier),
            const SizedBox(height: 12),

            // Stop Escalation Button
            ElevatedButton(
              onPressed: () {
                _timerService.stopEscalation();
                widget.onEscalationStop?.call();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'I am safe, stop escalation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTierTimeline(int currentTier, Color tierColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tierTimelineItem('T+5s', 'Tier 1', currentTier >= 1),
          _tierTimelineConnector(currentTier > 1),
          _tierTimelineItem('T+30s', 'Tier 2', currentTier >= 2),
          _tierTimelineConnector(currentTier > 2),
          _tierTimelineItem('T+90s', 'Tier 3', currentTier >= 3),
        ],
      ),
    );
  }

  Widget _tierTimelineItem(String time, String tier, bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _getTierColor(int.parse(tier.split(' ')[1])) : EchoColors.neutral.withOpacity(0.2),
            border: Border.all(
              color: isActive ? _getTierColor(int.parse(tier.split(' ')[1])) : EchoColors.textTertiary,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              tier.split(' ')[1],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : EchoColors.textTertiary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? EchoColors.textPrimary : EchoColors.textTertiary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _tierTimelineConnector(bool isActive) {
    return Container(
      width: 20,
      height: 2,
      color: isActive ? _getTierColor(2) : EchoColors.neutral.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildStatusMessage(int tier) {
    final messages = {
      1: 'Inner circle emergency contacts have been notified via WhatsApp',
      2: 'Extended network is being alerted. Help is on the way',
      3: 'Your location is now public. Maximum visibility for assistance',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _getTierColor(tier).withOpacity(0.1),
      ),
      child: Text(
        messages[tier] ?? '',
        style: TextStyle(
          fontSize: 12,
          color: _getTierColor(tier),
          height: 1.5,
        ),
      ),
    );
  }
}
