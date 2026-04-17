// ignore_for_file: deprecated_member_use, duplicate_ignore, unused_field

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/gemma_provider.dart';
import '../providers/social_media_provider.dart';
import '../services/escalation_timer_service.dart';
import '../services/confirmation_sound_service.dart';

class EmergencyActiveScreen extends StatefulWidget {
  const EmergencyActiveScreen({super.key});

  @override
  State<EmergencyActiveScreen> createState() => _EmergencyActiveScreenState();
}

class _EmergencyActiveScreenState extends State<EmergencyActiveScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Timer _elapsedTimer;
  int _elapsedSeconds = 0;

  // Escalation Timer Service
  final EscalationTimerService _escalationTimer = EscalationTimerService();
  
  // Confirmation Sound Service
  final ConfirmationSoundService _confirmationSoundService = ConfirmationSoundService();
  
  int _tierCountdown = 0;

  // Simulated Gemma 4 AI stream
  late Stream<String> _aiAnalysisStream;

  String? _currentIncidentId; // Track incident ID for escalation timer

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

    // Defer Gemma analysis and escalation timer to after build phase
    // This prevents "setState() during build" errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startGemmaAnalysisDeferred());
    });
  }
  /// Start the escalation timer with callbacks and proper incident ID
  void _startEscalationTimer(String incidentId) {
    final gemmaProvider = context.read<GemmaProvider>();
    final socialMediaProvider = context.read<SocialMediaProvider>();
    
    _escalationTimer.startEscalation(
      incidentId: incidentId,
      onTier1Activate: () {
        print('🚨 TIER 1 ACTIVATION - Sending WhatsApp to inner circle');
        // Play confirmation sound for Tier 1 activation
        unawaited(_confirmationSoundService.confirmTierCompletion(1));
        if (mounted) setState(() {});
        
        // TODO: Send WhatsApp messages to Tier 1 contacts with:
        // - Gemma threat summary
        // - Live location link
        // - First 30s audio clip
        // - 3 action buttons (Confirm Safe / Contact Details / Emergency Call)
      },
      onTier2Escalate: () {
        print('🚨 TIER 2 ESCALATION TRIGGERED');
        // Play confirmation sound for Tier 2
        unawaited(_confirmationSoundService.confirmTierCompletion(2));
        if (mounted) setState(() {});
        
        // TODO: Send WhatsApp messages to Tier 2 (extended network) with:
        // - Updated threat assessment
        // - Current live location
        // - Action buttons
      },
      onTier1Nudge: () {
        print('🔔 TIER 1 FOLLOW-UP NUDGE SENT');
        // Play confirmation sound for Tier 1 nudge
        unawaited(_confirmationSoundService.confirmTierCompletion(1));
        if (mounted) setState(() {});
        
        // TODO: Send follow-up WhatsApp to Tier 1 if still no confirmation
      },
      onTier3Escalate: () async {
        print('🚨 TIER 3 AUTO-POST TRIGGERED');
        // Play confirmation sound for Tier 3
        unawaited(_confirmationSoundService.confirmTierCompletion(3));
        if (mounted) setState(() {});
        
        // Trigger Twitter auto-post (Track C)
        try {
          await socialMediaProvider.tier3AutoEscalate(
            threatLevel: 'CRITICAL',
            threatCategory: 'escalation_tier_3',
            lat: 6.5244,
            lon: 3.3792,
            additionalContext: 'Emergency escalated to Tier 3 - no confirmation from Tier 1 or 2',
          );
        } catch (e) {
          print('❌ Tier 3 auto-escalation failed: $e');
        }
      },
      onTickCallback: (seconds) {
        if (mounted) {
          setState(() {
            _tierCountdown = seconds;
          });
        }
      },
    );
  }

  /// Deferred Gemma analysis - called after build phase to avoid setState during build
  Future<void> _startGemmaAnalysisDeferred() async {
    const sampleTranscript =
        'Help me, someone is forcing me into a car near Adeola Odeku. I am scared and cannot move freely.';
    const sampleContactId = 'contact_emergency_001';
    const sampleLocation = '6.5244, 3.3792'; // Adeola Odeku, Lagos

    final gemmaProvider = context.read<GemmaProvider>();
    
    // Analyze threat
    final result = await gemmaProvider.analyzeThreat(sampleTranscript);

    if (!mounted || result.isEmpty) {
      return;
    }

    // 🔥 Log threat to Firestore after analysis
    try {
      await gemmaProvider.logThreatToFirestore(
        contactId: sampleContactId,
        location: sampleLocation,
      );
      print('✅ Logged to Firestore, real-time listeners notified');
      
      // Capture incident ID and start escalation timer with correct ID
      final incidentId = gemmaProvider.lastIncidentId;
      if (incidentId != null && mounted) {
        _currentIncidentId = incidentId;
        // Start escalation timer AFTER incident is logged
        _startEscalationTimer(incidentId);
      }
    } catch (e) {
      print('⚠️ Firestore logging failed: $e');
    }

    // Update AI analysis stream
    if (mounted) {
      setState(() {
        _aiAnalysisStream = _streamGemmaSummary(result);
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _elapsedTimer.cancel();
    _escalationTimer.stopEscalation();
    unawaited(_confirmationSoundService.dispose());
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

  Stream<String> _streamGemmaSummary(Map<String, dynamic> analysis) async* {
    final threat = (analysis['threat'] ?? 'Unknown').toString();
    final confidence = (analysis['confidence'] ?? 'N/A').toString();
    final action = (analysis['action'] ?? 'Escalate to emergency responders').toString();
    final summary = (analysis['summary'] ?? 'Emergency context detected.').toString();
    final threatLevel = (analysis['threatLevel'] ?? 'high').toString();

    final rendered = '''Threat: $threat\nConfidence: $confidence%\nThreat level: $threatLevel\nAction: $action\nSummary: $summary''';

    for (int i = 0; i < rendered.length; i++) {
      await Future.delayed(const Duration(milliseconds: 18));
      yield rendered.substring(0, i + 1);
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
              const SizedBox(height: 24),

              // WOW FACTOR #1: Emotion Detection Gauge (Track A)
              _buildEmotionGauge(),
              const SizedBox(height: 32),

              // Live Status Column
              _buildLiveStatusColumn(),
              const SizedBox(height: 24),

              // WOW FACTOR #2: Escalation Timer (Track B)
              _buildEscalationTimerCard(),
              const SizedBox(height: 32),

              // Gemma 4 AI Analysis Card
              _buildAIAnalysisCard(),
              const SizedBox(height: 24),

              // Social Media Post Status (Track C)
              _buildSocialPostStatus(),
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
    final timerText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

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
              color: EchoColors.warning.withOpacity(0.4),
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
                border: Border.all(color: EchoColors.warning, width: 3),
              ),
            ),

            // Inner circle
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EchoColors.warning.withOpacity(0.1),
                border: Border.all(
                  color: EchoColors.warning.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'RECORDING',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: EchoColors.warning,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timerText,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: EchoColors.warning,
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
        'color': EchoColors.success,
      },
      {
        'icon': Icons.location_on_outlined,
        'label': 'Location',
        'status': 'LOCKED',
        'color': EchoColors.primary,
      },
      {
        'icon': Icons.notifications_active_outlined,
        'label': 'Alerts Sent',
        'status': '3 CONTACTS',
        'color': EchoColors.primary,
      },
      {
        'icon': Icons.phone_in_talk_outlined,
        'label': 'Police Dispatch',
        'status': 'PENDING',
        'color': EchoColors.warning,
      },
    ];

    return Column(
      children: statusItems.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EchoColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: EchoColors.textPrimary.withOpacity(0.08),
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
                      color: EchoColors.textSecondary,
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
        color: EchoColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EchoColors.primary.withOpacity(0.2),
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
                color: EchoColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Gemma 4 Analysis',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: EchoColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Consumer<GemmaProvider>(
            builder: (context, gemmaProvider, child) {
              if (gemmaProvider.isAnalyzing) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: EchoColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Analyzing live emergency context...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              if (gemmaProvider.error != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Gemma unavailable, using fallback guidance.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EchoColors.warning,
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),

          // StreamBuilder for progressive text
          StreamBuilder<String>(
            stream: _aiAnalysisStream,
            initialData: '',
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: EchoColors.textSecondary,
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
              backgroundColor: EchoColors.surfaceSecondary,
              title: Text(
                'Cancel Emergency?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: EchoColors.textPrimary,
                ),
              ),
              content: Text(
                'Are you sure? Recording and alerts will stop.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: EchoColors.textSecondary,
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
                    style: TextStyle(color: EchoColors.warning),
                  ),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.close),
        label: const Text('STOP EMERGENCY'),
        style: ElevatedButton.styleFrom(
          backgroundColor: EchoColors.warning.withOpacity(0.15),
          foregroundColor: EchoColors.warning,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // ========================================
  // NEW WIDGETS FOR DEVELOPER IMPLEMENTATION
  // ========================================

  /// WOW FACTOR #1: Emotion Detection Gauge (Track A - Dev 1)
  /// Shows real-time fear/panic level from voice analysis
  /// Developer: Wire EmotionDetectionService stream here
  Widget _buildEmotionGauge() {
    // PLACEHOLDER: Developers will replace with EmotionDetectionService stream
    double emotionLevel = 45; // 0-100, where 100 = panic
    bool isPanic = emotionLevel > 70;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPanic
            ? EchoColors.warning.withOpacity(0.1)
            : EchoColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPanic
              ? EchoColors.warning.withOpacity(0.5)
              : EchoColors.primary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart,
                color: isPanic
                    ? EchoColors.warning
                    : EchoColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Emotion Level',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: EchoColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${emotionLevel.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isPanic
                      ? EchoColors.warning
                      : EchoColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Gauge bar showing emotion level
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: emotionLevel / 100,
              minHeight: 24,
              backgroundColor: EchoColors.textSecondary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                emotionLevel < 30
                    ? EchoColors.success
                    : emotionLevel < 70
                    ? EchoColors.primary
                    : EchoColors.warning,
              ),
              semanticsLabel: 'Fear Level',
            ),
          ),
          const SizedBox(height: 12),

          // Status text
          Text(
            isPanic
                ? '🚨 PANIC DETECTED - Auto-contacting police...'
                : emotionLevel > 50
                ? '⚠️ High stress detected'
                : '✅ Monitoring stress levels',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isPanic
                  ? EchoColors.warning
                  : EchoColors.textSecondary,
              fontWeight: isPanic ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Escalation Timer (Track B - Dev 2)
  /// Shows 2-tier escalation: Tier 1 (0-30s) → Tier 2
  /// Developer: Wire EscalationManager FSM stream here
  Widget _buildEscalationTimerCard() {
    // Get live data from EscalationTimerService
    int secondsUntilTier2 = 60 - _escalationTimer.secondsElapsed;
    int secondsUntilTier3 = 120 - _escalationTimer.secondsElapsed;
    bool isTier1Active = _escalationTimer.currentTier == 1;
    bool isTier2Active = _escalationTimer.currentTier == 2;
    bool isTier3Active = _escalationTimer.currentTier == 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EchoColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTier3Active
              ? EchoColors.warning.withOpacity(0.5)
              : isTier2Active
              ? EchoColors.primary.withOpacity(0.3)
              : EchoColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline,
                color: isTier3Active ? EchoColors.warning : EchoColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Escalation Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: EchoColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'T+${_escalationTimer.secondsElapsed}s',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: EchoColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tier 1 Status
          _buildTierRow(
            tier: 'TIER 1',
            status: isTier1Active ? 'ACTIVE' : 'COMPLETED',
            contacts: '3 contacts notified',
            isActive: isTier1Active,
            context: context,
          ),
          const SizedBox(height: 12),

          // Countdown timer for Tier 2
          if (isTier1Active) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _escalationTimer.secondsElapsed / 60,
                        minHeight: 8,
                        backgroundColor: EchoColors.textSecondary
                            .withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          EchoColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${secondsUntilTier2}s to Tier 2',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: EchoColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tier 2 Status
          _buildTierRow(
            tier: 'TIER 2',
            status: isTier2Active ? 'ACTIVE' : (isTier1Active ? 'STANDBY' : 'COMPLETED'),
            contacts: '5-10 extended contacts',
            isActive: isTier2Active,
            context: context,
          ),
          
          const SizedBox(height: 12),

          // Countdown timer for Tier 3
          if (isTier1Active || isTier2Active) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _escalationTimer.secondsElapsed / 120,
                        minHeight: 8,
                        backgroundColor: EchoColors.textSecondary
                            .withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isTier2Active ? EchoColors.warning : EchoColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isTier2Active ? '${secondsUntilTier3}s to Twitter' : '${secondsUntilTier3}s',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isTier2Active ? EchoColors.warning : EchoColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tier 3 Status
          _buildTierRow(
            tier: 'TIER 3',
            status: isTier3Active ? '🚨 ACTIVE - TWITTER' : (isTier1Active || isTier2Active ? 'STANDBY' : 'COMPLETED'),
            contacts: 'Public safety alert',
            isActive: isTier3Active,
            context: context,
          ),
        ],
      ),
    );
  }

  /// Helper: Tier status row
  Widget _buildTierRow({
    required String tier,
    required String status,
    required String contacts,
    required bool isActive,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? EchoColors.primary.withOpacity(0.1)
            : EchoColors.textSecondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? EchoColors.primary.withOpacity(0.3)
              : EchoColors.textSecondary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isActive
                ? EchoColors.primary
                : EchoColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: EchoColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  contacts,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EchoColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isActive
                  ? EchoColors.primary
                  : EchoColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Social Media Post Status (Track C - Dev 3)
  /// Shows auto-post confirmation to Twitter/social media
  /// Developer: Wire SocialMediaPostingService stream here
  Widget _buildSocialPostStatus() {
    // PLACEHOLDER: Developers will replace with StreamBuilder wrapping SocialMediaPostingService
    // Example implementation:
    // StreamBuilder<SocialPostStatus>(
    //   stream: socialMediaService.postStatusStream(),
    //   builder: (context, snapshot) { ... }
    // )

    final postTime = DateTime.now();

    // Default: Show success state
    // Developers: Replace with state from SocialMediaPostingService stream
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EchoColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EchoColors.success.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: EchoColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'Emergency Alert Posted',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: EchoColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Post preview box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EchoColors.textSecondary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚨 EMERGENCY ALERT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: EchoColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Posted to Twitter • Emergency services notified • Help needed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EchoColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Post metadata
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: EchoColors.textTertiary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Posted ${postTime.toString().substring(11, 16)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: EchoColors.textTertiary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Open post in browser or copy URL
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening post...')),
                  );
                },
                child: Text(
                  'View Post',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: EchoColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
