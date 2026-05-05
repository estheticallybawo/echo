import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_service.dart';

/// Track C: Gemma Decision Engine
/// Uses Gemma threat assessments to dynamically drive escalation behavior
/// Makes system decisions based on threat confidence, user history, location patterns

class GemmaDecisionEngine {
  static final GemmaDecisionEngine _instance = 
      GemmaDecisionEngine._internal();

  factory GemmaDecisionEngine() {
    return _instance;
  }

  GemmaDecisionEngine._internal();

  final UserProfileService _userService = UserProfileService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Decision thresholds for threat escalation
  static const Map<String, int> threatConfidenceThresholds = {
    'kidnapping': 90,     // Escalate at 60% confidence
    'assault': 65,        // Escalate at 65% confidence
    'medical': 70,        // Escalate at 70% confidence
    'fire': 85,           // Escalate at 85% confidence
    'other': 75,          // Escalate at 75% confidence
  };

  /// Determine escalation action based on Gemma assessment
  /// Returns: escalation_recommend: "ESCALATE" | "MONITOR" | "DISMISS"
  Future<Map<String, dynamic>> makeEscalationDecision({
    required String incidentId,
    required String threatType,
    required double confidence,
    required String location,
    required String userThreatThreshold,
  }) async {
    try {
      print('🧠 Gemma Decision Engine analyzing: $threatType ($confidence%)');

      final user = _auth.currentUser;
      if (user == null) return {'decision': 'ERROR', 'reason': 'No user'};

      // Get user's threat history to check for patterns
      final threatHistory = await _userService.getThreatHistory(days: 90);
      
      // Count similar threats in past 90 days
      final similarThreats = threatHistory.where((t) => 
        t['threat_type'] == threatType
      ).length;

      // Check user's privacy settings
      final profile = await _userService.getUserProfile();
      final autoEscalateEnabled = profile?['auto_escalate_enabled'] ?? true;

      // Get threshold for this threat type
      final threshold = threatConfidenceThresholds[threatType] ?? 75;

      // Decision logic
      String decision = 'MONITOR';
      String reasoning = '';

      if (!autoEscalateEnabled) {
        decision = 'MONITOR';
        reasoning = 'User has auto-escalation disabled';
      } else if (confidence >= threshold) {
        decision = 'ESCALATE';
        reasoning = 
            'Confidence ($confidence%) meets threshold ($threshold%) for $threatType';
        
        // If user has history of similar threats, escalate more aggressively
        if (similarThreats > 2) {
          decision = 'ESCALATE_IMMEDIATE';
          reasoning += ' + Pattern detected ($similarThreats similar incidents)';
        }
      } else if (confidence >= threshold - 10) {
        // Borderline: monitor closely
        decision = 'MONITOR_CLOSE';
        reasoning = 'Borderline confidence - monitoring closely';
      } else {
        decision = 'DISMISS';
        reasoning = 'Confidence too low ($confidence% < ${threshold - 10}%)';
      }

      // Adjust based on user's threat sensitivity
      if (userThreatThreshold == 'high') {
        // High sensitivity: escalate sooner
        if (decision == 'MONITOR') decision = 'MONITOR_CLOSE';
        if (decision == 'MONITOR_CLOSE') decision = 'ESCALATE';
      } else if (userThreatThreshold == 'low') {
        // Low sensitivity: only escalate on very high confidence
        if (decision == 'ESCALATE' && confidence < 85) {
          decision = 'MONITOR_CLOSE';
        }
      }

      // Record decision to Firestore for audit trail
      await _recordDecision(
        incidentId: incidentId,
        threatType: threatType,
        confidence: confidence,
        decision: decision,
        reasoning: reasoning,
      );

      // Record to user's threat history
      await _userService.recordThreatToHistory(
        incidentId: incidentId,
        threatType: threatType,
        confidence: confidence,
        location: location,
      );

      print('✅ Decision: $decision');
      print('   Reason: $reasoning');

      return {
        'decision': decision,
        'reasoning': reasoning,
        'threat_type': threatType,
        'confidence': confidence,
        'pattern_count': similarThreats,
        'auto_escalate_enabled': autoEscalateEnabled,
        'user_threshold': userThreatThreshold,
      };
    } catch (e) {
      print('❌ Error in decision engine: $e');
      return {
        'decision': 'ERROR',
        'reason': e.toString(),
      };
    }
  }

  /// Recommend tier based on Gemma assessment + user history
  /// Returns: recommended_tier: 1 | 2 | 3
  Future<int> recommendTier({
    required String threatType,
    required double confidence,
    required int similarThreatCount,
  }) async {
    try {
      // Default escalation path
      int recommendedTier = 1;

      // High confidence threats skip to higher tier
      if (confidence > 85) {
        recommendedTier = 2;
      }
      if (confidence > 92) {
        recommendedTier = 3;
      }

      // Pattern detected: escalate further
      if (similarThreatCount > 3) {
        recommendedTier = (recommendedTier + 1).clamp(1, 3);
      }

      // Certain threat types should escalate higher
      if (threatType == 'kidnapping' || threatType == 'assault') {
        recommendedTier = recommendedTier.clamp(2, 3); // Min Tier 2
      }

      print('🎯 Recommended Tier: $recommendedTier (confidence: $confidence%)');
      return recommendedTier;
    } catch (e) {
      print('❌ Error recommending tier: $e');
      return 1; // Default to Tier 1
    }
  }

  /// Determine which contacts to alert based on CURRENT ESCALATION TIER
  /// Note: This method is now called by EscalationTimerService at specific intervals
  /// T+5s: Return Tier 1 only (tier_1_emergency)
  /// T+60s: Return Tier 2 (tier_2_extended)
  /// T+90s: Return Tier 3 (tier_3_public)
  /// 
  /// IMPORTANT: This method should NOT use confidence to determine tier!
  /// Tier determination is ONLY the responsibility of EscalationTimerService timing.
  /// Confidence is used to decide WHETHER to escalate, not WHEN to escalate.
  Future<List<String>> getContactsToAlert({
    required String threatType,
    required double confidence,
    required int currentTier,
  }) async {
    List<String> contactsToAlert = [];

    // Return contacts ONLY for the current tier and below
    // Tier 1 is default, activated at T+5s
    if (currentTier >= 1) {
      contactsToAlert.add('tier_1_emergency');
    }

    // Tier 2 extended network, activated at T+60s
    if (currentTier >= 2) {
      contactsToAlert.add('tier_2_extended');
    }

    // Tier 3 public/Echo feed, activated at T+90s
    if (currentTier >= 3) {
      contactsToAlert.add('tier_3_public');
    }

    print('✅ getContactsToAlert(tier=$currentTier) → ${contactsToAlert.toSet().toList()}');
    return contactsToAlert.toSet().toList(); // Remove duplicates
  }

  /// Generate custom alert message based on Gemma assessment
  String generateAlertMessage({
    required String threatType,
    required double confidence,
    required String location,
  }) {
    final confidenceLevel = _getConfidenceLevelText(confidence);
    
    final threats = {
      'kidnapping': '🚨 KIDNAPPING SUSPECTED',
      'assault': '⚠️ ASSAULT DETECTED',
      'medical': '🏥 MEDICAL EMERGENCY',
      'fire': '🔥 FIRE DETECTED',
      'other': '❗ EMERGENCY ALERT',
    };

    final emoji = threats[threatType] ?? '❗ EMERGENCY ALERT';

    return '''$emoji
$confidenceLevel confidence ($confidence%)
Location: $location
Status: ACTIVE & ESCALATING
Time: ${DateTime.now()}

If you know this person, contact them or emergency services immediately.''';
  }

  /// Get confidence level text
  String _getConfidenceLevelText(double confidence) {
    if (confidence >= 90) return '🔴 CRITICAL';
    if (confidence >= 80) return '🔴 HIGH';
    if (confidence >= 70) return '🟠 MEDIUM-HIGH';
    if (confidence >= 60) return '🟠 MEDIUM';
    return '🟡 LOW';
  }

  /// Record decision to Firestore for audit trail
  Future<void> _recordDecision({
    required String incidentId,
    required String threatType,
    required double confidence,
    required String decision,
    required String reasoning,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('incidents')
          .doc(incidentId)
          .collection('decisions')
          .add({
        'threat_type': threatType,
        'confidence': confidence,
        'decision': decision,
        'reasoning': reasoning,
        'decided_at': FieldValue.serverTimestamp(),
      });

      print('✅ Decision recorded to incident audit trail');
    } catch (e) {
      print('⚠️ Could not record decision: $e');
    }
  }

  /// Get user's current threat profile
  /// Returns aggregated threat data for dashboard
  Future<Map<String, dynamic>> getUserThreatProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final threatHistory = await _userService.getThreatHistory(days: 90);

      // Count threat types
      final threatCounts = <String, int>{};
      for (final threat in threatHistory) {
        final type = threat['threat_type'] as String? ?? 'unknown';
        threatCounts[type] = (threatCounts[type] ?? 0) + 1;
      }

      // Average confidence
      final avgConfidence = threatHistory.isNotEmpty
          ? threatHistory
                  .fold<double>(0, (sum, t) => sum + (t['confidence'] as double? ?? 0)) /
              threatHistory.length
          : 0;

      return {
        'incident_count': threatHistory.length,
        'threat_types': threatCounts,
        'avg_confidence': avgConfidence.toStringAsFixed(1),
        'most_common_threat': 
            threatCounts.isEmpty ? 'none' :
            threatCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key,
      };
    } catch (e) {
      print('❌ Error getting threat profile: $e');
      return {};
    }
  }
}
