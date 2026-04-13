import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_incident_service.dart';

/// Track C: Escalation Timer Service
/// Manages multi-tier escalation countdown (0-120+ seconds)
/// T+60s → Tier 2 escalation check
/// T+90s → Follow-up nudge to Tier 1
/// T+120s → Tier 3 auto-post to Twitter
class EscalationTimerService {
  static final EscalationTimerService _instance = EscalationTimerService._internal();

  factory EscalationTimerService() {
    return _instance;
  }

  EscalationTimerService._internal();

  final FirestoreIncidentService _firestoreService = FirestoreIncidentService();

  // Timer state
  Timer? _escalationTimer;
  int _secondsElapsed = 0;
  bool _isRunning = false;

  // Escalation tracking
  bool _tier1Confirmed = false;
  bool _tier2Confirmed = false;
  DateTime? _emergencyStartTime;
  String? _currentIncidentId;

  // Public getters
  bool get isRunning => _isRunning;
  int get secondsElapsed => _secondsElapsed;
  int get secondsRemaining => maxDuration - _secondsElapsed;
  int get maxDuration => 300; // 5 minutes max escalation
  double get progressPercentage => (_secondsElapsed / maxDuration) * 100;

  // Escalation tier status
  int get currentTier {
    if (_secondsElapsed < 60) return 1;
    if (_secondsElapsed < 120) return 2;
    return 3;
  }

  // Callbacks
  VoidCallback? onTierChanged;
  Function(int seconds)? onTick;
  Function()? onTier1CheckPoint;
  Function()? onTier2CheckPoint;
  Function()? onTier3Escalate;

  /// Start escalation countdown (called after emergency activation)
  void startEscalation({
    required String incidentId,
    required VoidCallback onTier2Escalate,
    required VoidCallback onTier3Escalate,
    VoidCallback? onTier1Nudge,
    Function(int seconds)? onTickCallback,
  }) {
    if (_isRunning) {
      print('⚠️ Escalation already running');
      return;
    }

    _currentIncidentId = incidentId;
    _emergencyStartTime = DateTime.now();
    _secondsElapsed = 0;
    _tier1Confirmed = false;
    _tier2Confirmed = false;
    _isRunning = true;

    onTick = onTickCallback;
    onTier2CheckPoint = onTier2Escalate;
    onTier3Escalate = onTier3Escalate;
    onTier1CheckPoint = onTier1Nudge;

    print('⏱️ Escalation timer started (${_currentIncidentId})');
    print('   T+60s: Tier 2 escalation check');
    print('   T+90s: Tier 1 follow-up nudge');
    print('   T+120s: Tier 3 auto-post to Twitter');

    // Start 1-second tick timer
    _escalationTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      _secondsElapsed++;

      // Callback for UI updates
      onTick?.call(_secondsElapsed);

      // Tier 1 checkpoint (T+60s) - Escalate to Tier 2
      if (_secondsElapsed == 60 && !_tier1Confirmed) {
        print('⏰ T+60s: Tier 2 escalation triggered (no Tier 1 confirmation)');
        onTier2CheckPoint?.call();
      }

      // Tier 1 nudge (T+90s) - Send follow-up message
      if (_secondsElapsed == 90 && !_tier1Confirmed) {
        print('⏰ T+90s: Sending follow-up nudge to Tier 1 contacts');
        onTier1CheckPoint?.call();
      }

      // Tier 3 checkpoint (T+120s) - Auto-post to Twitter
      if (_secondsElapsed == 120 && !_tier1Confirmed && !_tier2Confirmed) {
        print('⏰ T+120s: Tier 3 auto-escalation (no confirmation from Tier 1 or 2)');
        await _handleTier3Escalation();
        onTier3Escalate?.call();
      }

      // Stop after max duration
      if (_secondsElapsed >= maxDuration) {
        print('⏱️ Escalation timer max duration reached (${maxDuration}s)');
        stopEscalation();
      }
    });
  }

  /// Mark contact action confirmed (stops escalation)
  void confirmContactAction() {
    if (!_isRunning) return;

    if (_secondsElapsed < 60) {
      _tier1Confirmed = true;
      print('✅ T+${_secondsElapsed}s: Tier 1 contact confirmed - stopping escalation');
    } else if (_secondsElapsed < 120) {
      _tier2Confirmed = true;
      print('✅ T+${_secondsElapsed}s: Tier 2 contact confirmed - stopping escalation');
    }

    // Stop timer if any contact confirms
    if (_tier1Confirmed || _tier2Confirmed) {
      stopEscalation();
    }
  }

  /// Handle Tier 3 escalation (prepare for Twitter auto-post)
  Future<void> _handleTier3Escalation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update incident in Firestore to mark Tier 3 escalation
      if (_currentIncidentId != null) {
        await _firestoreService.updateIncidentStatus(
          userId: user.uid,
          incidentId: _currentIncidentId!,
          escalationStatus: 'TIER_3_ESCALATION',
        );
        print('✅ Tier 3 marker written to Firestore');
      }
    } catch (e) {
      print('❌ Error in Tier 3 escalation: $e');
    }
  }

  /// Stop escalation countdown (user pressed "I am safe")
  void stopEscalation() {
    if (!_isRunning) return;

    _escalationTimer?.cancel();
    _isRunning = false;

    print('⏹️ Escalation timer stopped');
    print('   Duration: ${_secondsElapsed}s');
    print('   Tier reached: $currentTier');

    // Reset state
    _secondsElapsed = 0;
    _tier1Confirmed = false;
    _tier2Confirmed = false;
    _currentIncidentId = null;
    _emergencyStartTime = null;
  }

  /// Get human-readable time remaining
  String getFormattedTime() {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Get escalation status message
  String getStatusMessage() {
    if (!_isRunning) return 'Idle';

    switch (currentTier) {
      case 1:
        return 'Tier 1: Sending to inner circle (${60 - _secondsElapsed}s until escalation)';
      case 2:
        return 'Tier 2: Extended network alerted (${120 - _secondsElapsed}s until Twitter post)';
      case 3:
        return 'Tier 3: ACTIVE - Location now public on Twitter';
      default:
        return 'Unknown tier';
    }
  }

  /// Debug: Get full status
  Map<String, dynamic> getDebugStatus() {
    return {
      'isRunning': _isRunning,
      'secondsElapsed': _secondsElapsed,
      'currentTier': currentTier,
      'tier1Confirmed': _tier1Confirmed,
      'tier2Confirmed': _tier2Confirmed,
      'progressPercentage': progressPercentage,
      'statusMessage': getStatusMessage(),
      'formattedTime': getFormattedTime(),
    };
  }
}
