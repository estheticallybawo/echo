import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_incident_service.dart';

/// Track C: Escalation Timer Service
/// Manages multi-tier escalation countdown (0-120+ seconds)
/// T+5s → Tier 1 SMS alert to inner circle
/// T+60s → Tier 2 escalation check (extended network)
/// T+90s → Tier 3 auto-post to Echo community feed
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
  String? _currentIncidentId;

  // Public getters
  bool get isRunning => _isRunning;
  int get secondsElapsed => _secondsElapsed;
  int get secondsRemaining => maxDuration - _secondsElapsed;
  int get maxDuration => 180; // 3 minutes max escalation (T+90s critical, plus buffer)
  double get progressPercentage => (_secondsElapsed / maxDuration) * 100;

  // Escalation tier status
  int get currentTier {
    if (_secondsElapsed < 30) return 1;
    if (_secondsElapsed < 90) return 2;
    return 3;
  }

  // Callbacks
  VoidCallback? onTierChanged;
  Function(int seconds)? onTick;
  Function()? onTier1Activate; // T+5s: Send SMS to inner circle
  Function()? onTier2Escalate; // T+60s: Escalate to Tier 2 (extended network)
  Function()? onTier3Escalate; // T+90s: Auto-post to Echo community feed

  /// Start escalation countdown (called after emergency activation)
  void startEscalation({
    required String incidentId,
    required VoidCallback onTier1Activate,
    required VoidCallback onTier2Escalate,
    required VoidCallback onTier3Escalate,
    Function(int seconds)? onTickCallback,
  }) {
    if (_isRunning) {
      print('⚠️ Escalation already running');
      return;
    }

    _currentIncidentId = incidentId;
    _secondsElapsed = 0;
    _isRunning = true;

    onTick = onTickCallback;
    this.onTier1Activate = onTier1Activate;
    this.onTier2Escalate = onTier2Escalate;
    this.onTier3Escalate = onTier3Escalate;

    print('⏱️ Escalation timer started ($_currentIncidentId)');
    print('   T+5s:  TIER 1 ACTIVATION - Send SMS to inner circle');
    print('   T+60s: TIER 2 ESCALATION - Escalate to extended network');
    print('   T+90s: TIER 3 AUTO-POST - Echo community feed auto-post');

    // Start 1-second tick timer
    _escalationTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      _secondsElapsed++;

      // Callback for UI updates
      onTick?.call(_secondsElapsed);

      // Tier 1 activation (T+5s) - Send SMS to inner circle
      if (_secondsElapsed == 5) {
        print('⏰ T+5s: TIER 1 ACTIVATION - Sending SMS to inner circle');
        this.onTier1Activate?.call();
      }

      // Tier 2 escalation (T+60s) - Escalate to extended network
      if (_secondsElapsed == 60) {
        print('⏰ T+60s: TIER 2 ESCALATION - Escalating to extended network');
        this.onTier2Escalate?.call();
      }

      // Tier 3 auto-post to Echo feed (T+90s)
      if (_secondsElapsed == 90) {
        print('⏰ T+90s: TIER 3 AUTO-POST - Posting to Echo community feed');
        await _handleTier3Escalation();
        this.onTier3Escalate?.call();
      }

      // Stop after max duration
      if (_secondsElapsed >= maxDuration) {
        print('⏱️ Escalation timer max duration reached (${maxDuration}s)');
        stopEscalation();
      }
    });
  }

  /// Stop escalation manually (user pressed "I am safe")
  void confirmSafety() {
    if (!_isRunning) return;

    print('✅ T+${_secondsElapsed}s: User confirmed safety - stopping escalation');
    stopEscalation();
  }

  /// Handle Tier 3 escalation (auto-post to Echo community feed)
  Future<void> _handleTier3Escalation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update incident in Firestore to mark Tier 3 escalation and auto-post to Echo feed
      if (_currentIncidentId != null) {
        await _firestoreService.updateIncidentStatus(
          userId: user.uid,
          incidentId: _currentIncidentId!,
          escalationStatus: 'TIER_3_ECHO_FEED_AUTO_POST',
        );
        print('✅ Tier 3: Auto-posted to Echo community feed');
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
    _currentIncidentId = null;
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
        return 'Tier 1: SMS sent to inner circle (${60 - _secondsElapsed}s until Tier 2)';
      case 2:
        return 'Tier 2: Extended network alerted (${90 - _secondsElapsed}s until Echo feed post)';
      case 3:
        return 'Tier 3: ACTIVE - Posted to Echo community feed';
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
      'progressPercentage': progressPercentage,
      'statusMessage': getStatusMessage(),
      'formattedTime': getFormattedTime(),
    };
  }
}
