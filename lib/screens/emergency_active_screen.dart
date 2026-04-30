// ignore_for_file: deprecated_member_use, duplicate_ignore, unused_field

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../theme.dart';
import '../providers/gemma_provider.dart';
import '../providers/social_media_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../services/firestore_incident_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmergencyActiveScreen extends StatefulWidget {
  final Map<String, dynamic>? threatAnalysis;
  final String? emergencyDescription;
  final String? userLocation;

  const EmergencyActiveScreen({
    this.threatAnalysis,
    this.emergencyDescription,
    this.userLocation,
    super.key,
  });

  @override
  State<EmergencyActiveScreen> createState() => _EmergencyActiveScreenState();
}

class _EmergencyActiveScreenState extends State<EmergencyActiveScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _timerController;
  late Timer _elapsedTimer;
  int _elapsedSeconds = 0;
  late Stream<String> _aiAnalysisStream;

  // Threat analysis data from Gemma
  late Map<String, dynamic> threatData;
  late double confidence;
  late String threatType;
  late String threatLevel;

  // Auto-posting state tracking
  bool _isPostingEnabled = true; // Auto-post if consent/settings allow
  bool _isPosting = false;
  bool _postSuccess = false;
  String? _postError;
  String? _lastIncidentId;
  int _postTimestamp = 0;
  
  // Configuration
  static const double AUTO_POST_CONFIDENCE_THRESHOLD = 0.70; // 70% confidence minimum
  final FirestoreIncidentService _firestoreService = FirestoreIncidentService();

  double _safeConfidenceValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  @override
  void initState() {
    super.initState();

    // Extract threat data from widget arguments
    threatData = widget.threatAnalysis ?? {
      'threat': 'Unknown',
      'confidence': 0,
      'threatLevel': 'low',
      'summary': 'Unable to assess threat',
    };

    confidence = _safeConfidenceValue(threatData['confidence']);
    threatType = threatData['threat']?.toString() ?? 'Unknown';
    threatLevel = threatData['threatLevel']?.toString() ?? 'low';

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

    // Simulate Gemma 4 AI analysis stream with real data
    _aiAnalysisStream = _generateAIAnalysis();

    // 🚀 **PHASE 3A: AUTO-POSTING TRIGGER**
    // Wire the validated inference path with auto-posting logic
    _initializeAutoPosting();
  }

  /// Initialize auto-posting flow
  /// Triggers if confidence >= threshold; requires Firestore logging before X post
  Future<void> _initializeAutoPosting() async {
    final preferences = context.read<UserPreferencesProvider>();
    final socialMediaProvider = context.read<SocialMediaProvider>();
    _isPostingEnabled =
        preferences.allowPublicPosts && socialMediaProvider.autoPostEnabled;

    if (!_isPostingEnabled) {
      _updatePostingState(false, error: 'Auto-post is disabled by your preferences.');
      return;
    }

    // Validate threat assessment exists
    if (threatData.isEmpty || threatData['confidence'] == null) {
      _updatePostingState(false, error: 'No threat assessment available');
      return;
    }

    final confidencePercent = (confidence / 100);

    // Gate 1: Check confidence threshold
    if (confidencePercent < AUTO_POST_CONFIDENCE_THRESHOLD) {
      print('⏭️ Confidence ${(confidencePercent * 100).toStringAsFixed(0)}% below auto-post threshold (${AUTO_POST_CONFIDENCE_THRESHOLD * 100})%');
      _updatePostingState(false);
      return;
    }

    print('✅ Threat confidence ${(confidencePercent * 100).toStringAsFixed(0)}% meets auto-post threshold');

    // Gate 2: Log to Firestore BEFORE posting
    await _logThreatToFirestore();

    // Gate 3: Only post if Firestore logging succeeded
    if (_lastIncidentId != null && _postError == null) {
      await _postToSocialMedia();
    }
  }

  /// Log threat assessment to Firestore before posting
  /// This ensures we have an audit trail and incident ID before going public
  Future<void> _logThreatToFirestore() async {
    try {
      setState(() => _isPosting = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final threatLevel = (threatData['threatLevel'] ?? 'HIGH').toString().toUpperCase();
      final threatCategory = (threatData['threat'] ?? 'unknown_threat').toString();
      final analysisJson = threatData.toString();
      final location = widget.userLocation ?? 'Location not available';

      // Log incident to Firestore
      _lastIncidentId = await _firestoreService.logIncident(
        userId: user.uid,
        actionType: 'emergency_auto_post',
        contactId: user.email ?? 'unknown',
        location: location,
        threatLevel: threatLevel,
        threatCategory: threatCategory,
        gemmaAnalysis: analysisJson,
      );

      print('✅ Incident logged to Firestore: $_lastIncidentId');
    } catch (e) {
      print('❌ Firestore logging failed: $e');
      _updatePostingState(false, error: 'Failed to log incident: $e');
    }
  }

  /// Post emergency alert to social media (X)
  /// Only called after Firestore logging succeeds
  Future<void> _postToSocialMedia() async {
    try {
      setState(() => _isPosting = true);

      final gemmaProvider = context.read<GemmaProvider>();
      final socialMediaProvider = context.read<SocialMediaProvider>();

      // Set Gemma provider's last assessment so SocialMediaProvider can use it
      gemmaProvider.lastThreatAssessment = threatData;
      gemmaProvider.lastIncidentId = _lastIncidentId;

      // Post to X
      final posted = await socialMediaProvider.postEmergencyAlert(
        userName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
        audioContext: widget.emergencyDescription ?? 'Emergency detected',
        location: widget.userLocation ?? 'Location not available',
        precomputedThreatAssessment: threatData,
      );

      if (posted) {
        print('✅ Emergency alert posted to X');
        _postTimestamp = DateTime.now().millisecondsSinceEpoch;
        _updatePostingState(true);
      } else {
        throw Exception('Failed to post to X');
      }
    } catch (e) {
      print('❌ Social media posting failed: $e');
      _updatePostingState(false, error: 'Failed to post: $e');
    }
  }

  /// Update posting state and rebuild UI
  void _updatePostingState(bool success, {String? error}) {
    if (mounted) {
      setState(() {
        _isPosting = false;
        _postSuccess = success;
        _postError = error;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _elapsedTimer.cancel();
    super.dispose();
  }

  /// Generate AI analysis text from real Gemma data
  Stream<String> _generateAIAnalysis() async* {
    final analysisText = '''Threat Assessment Complete:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: $threatType
Confidence: ${confidence.toStringAsFixed(0)}%
Level: ${threatLevel.toUpperCase()}
━━━━━━━━━━━━━━━━━━━━━━━━━━━
${threatData['summary'] ?? 'Threat detected - escalation in progress'}

Location: Confirmed & LOCKED
Police: Queued for dispatch
Contacts: 3 notified (Tier 1)
Social: Queued for amplification
''';

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

  /// Threat Confidence Gauge
  Widget _buildEmotionGauge() {
    double threatConfidence = confidence;
    bool isCritical = threatConfidence >= 85;
    bool isHigh = threatConfidence >= 65;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCritical
            ? EchoColors.warning.withOpacity(0.1)
            : isHigh
            ? EchoColors.primary.withOpacity(0.1)
            : EchoColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical
              ? EchoColors.warning.withOpacity(0.5)
              : isHigh
              ? EchoColors.primary.withOpacity(0.3)
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
                Icons.warning_amber_rounded,
                color: isCritical
                    ? EchoColors.warning
                    : isHigh
                    ? EchoColors.primary
                    : EchoColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Threat Confidence',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: EchoColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${threatConfidence.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isCritical
                      ? EchoColors.warning
                      : isHigh
                      ? EchoColors.primary
                      : EchoColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Threat confidence bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: threatConfidence / 100,
              minHeight: 24,
              backgroundColor: EchoColors.textSecondary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                threatConfidence < 60
                    ? EchoColors.success
                    : threatConfidence < 80
                    ? EchoColors.primary
                    : EchoColors.warning,
              ),
              semanticsLabel: 'Threat Confidence',
            ),
          ),
          const SizedBox(height: 12),

          // Status text
          Text(
            isCritical
                ? '🚨 CRITICAL THREAT - Automatic escalation active'
                : isHigh
                ? '⚠️ High threat level confirmed'
                : '⚠️ Moderate threat - Monitoring escalation',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isCritical
                  ? EchoColors.warning
                  : isHigh
                  ? EchoColors.primary
                  : EchoColors.textSecondary,
              fontWeight: isCritical ? FontWeight.w600 : FontWeight.w400,
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
    // PLACEHOLDER: Developers will replace with EscalationManager stream
    int secondsUntilTier2 = 18; // Countdown from 30s
    bool isTier1Active = secondsUntilTier2 > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EchoColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTier1Active
              ? EchoColors.primary.withOpacity(0.3)
              : EchoColors.success.withOpacity(0.3),
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
                color: EchoColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Escalation Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: EchoColors.textPrimary,
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
                        value: (30 - secondsUntilTier2) / 30,
                        minHeight: 8,
                        backgroundColor: EchoColors.textSecondary
                            .withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          EchoColors.warning,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${secondsUntilTier2}s',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: EchoColors.warning,
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
            status: isTier1Active ? 'STANDBY' : 'ACTIVATED',
            contacts: '5-10 extended contacts',
            isActive: !isTier1Active,
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
  /// Shows auto-post confirmation to X/social media
  /// **PHASE 3: WIRED TO REAL AUTO-POSTING FLOW**
  /// Shows real status: pending → success/error
  Widget _buildSocialPostStatus() {
    // Show pending state while posting
    if (_isPosting) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EchoColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: EchoColors.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(EchoColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Publishing Emergency Alert',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: EchoColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Logging incident and posting to social media...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: EchoColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Show error state
    if (_postError != null) {
      final isPreferenceError = _postError!.contains('disabled by your preferences');
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EchoColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: EchoColors.warning.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: EchoColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  isPreferenceError ? 'Auto-Post Disabled' : 'Auto-Post Failed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: EchoColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _postError ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: EchoColors.warning,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPreferenceError
                  ? 'Enable public posting in preferences to allow automatic posting.'
                  : 'Manual posting may be required. Emergency services have been notified.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: EchoColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Show success state
    if (_postSuccess) {
      final postTime = DateTime.fromMillisecondsSinceEpoch(_postTimestamp);
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
                    'Threat: ${threatType.toUpperCase()} | Confidence: ${(confidence).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EchoColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Posted to X • Emergency services notified • Help needed',
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
                Text(
                  'Incident: ${_lastIncidentId?.substring(0, 8) ?? "—"}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: EchoColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Show default state (confidence below threshold)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EchoColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EchoColors.textSecondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: EchoColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Social Media Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: EchoColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Confidence level (${(confidence).toStringAsFixed(0)}%) is below auto-post threshold (70%).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: EchoColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Emergency services have been notified. You can manually post if needed.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: EchoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
