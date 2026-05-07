import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_incident_service.dart';
import 'echo feed/echo_feed_service.dart';

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

  FirestoreIncidentService? _firestoreService;

  // Timer state
  Timer? _escalationTimer;
  int _secondsElapsed = 0;
  bool _isRunning = false;

  // Escalation tracking
  String? _currentIncidentId;
  
  // Distress-adjustable thresholds
  int _tier1Threshold = 5;    // T+5s: SMS alert
  int _tier2Threshold = 60;   // T+60s: Extended network
  int _tier3Threshold = 90;   // T+90s: Echo feed auto-post

  // Public getters
  bool get isRunning => _isRunning;
  int get secondsElapsed => _secondsElapsed;
  int get secondsRemaining => maxDuration - _secondsElapsed;
  int get maxDuration => 180; // 3 minutes max escalation (T+90s critical, plus buffer)
  double get progressPercentage => (_secondsElapsed / maxDuration) * 100;

  // Escalation tier status
  int get currentTier {
    if (_secondsElapsed < _tier2Threshold) return 1;
    if (_secondsElapsed < _tier3Threshold) return 2;
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

    // Reset thresholds to defaults at the start of each emergency session.
    _tier1Threshold = 5;
    _tier2Threshold = 60;
    _tier3Threshold = 90;

    onTick = onTickCallback;
    this.onTier1Activate = onTier1Activate;
    this.onTier2Escalate = onTier2Escalate;
    this.onTier3Escalate = onTier3Escalate;

    print('⏱️ Escalation timer started ($_currentIncidentId)');
    print('   T+${_tier1Threshold}s:  TIER 1 ACTIVATION - Send SMS to inner circle');
    print('   T+${_tier2Threshold}s: TIER 2 ESCALATION - Escalate to extended network');
    print('   T+${_tier3Threshold}s: TIER 3 AUTO-POST - Echo community feed auto-post');

    // Start 1-second tick timer
    _escalationTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      _secondsElapsed++;

      // Callback for UI updates
      onTick?.call(_secondsElapsed);

      // Tier 1 activation (T+Xs) - Send SMS to inner circle
      if (_secondsElapsed == _tier1Threshold) {
        print('⏰ T+${_tier1Threshold}s: TIER 1 ACTIVATION - Sending SMS to inner circle');
        this.onTier1Activate?.call();
      }

      // Tier 2 escalation (T+Xs) - Escalate to extended network
      if (_secondsElapsed == _tier2Threshold) {
        print('⏰ T+${_tier2Threshold}s: TIER 2 ESCALATION - Escalating to extended network');
        this.onTier2Escalate?.call();
      }

      // Tier 3 auto-post to Echo feed (T+Xs)
      if (_secondsElapsed == _tier3Threshold) {
        print('⏰ T+${_tier3Threshold}s: TIER 3 AUTO-POST - Posting to Echo community feed');
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

    // Get incident data from Firestore (matches FirestoreIncidentService collection path)
    final incidentDoc = await _firestore
        .collection('incidents')
        .doc(user.uid)
        .collection('logs')
        .doc(_currentIncidentId)
        .get();
    final data = incidentDoc.data();
    if (data == null) return;

    final threatAssessment = jsonDecode(data['gemma_analysis'] ?? '{}');
    final location = data['location'] ?? 'unknown';
    // Note: latitude/longitude not stored in IncidentModel; pass null (feed service handles it)
    final lat = null;
    final lon = null;

    final feedService = EchoFeedService();
    await feedService.postEmergencyToFeed(
      incidentId: _currentIncidentId!,
      userId: user.uid,
      victimName: user.displayName ?? 'User',
      locationText: location,
      latitude: lat,
      longitude: lon,
      threatAssessment: threatAssessment,
    );
    print('✅ Tier 3 escalation: Echo Feed post created for incident $_currentIncidentId');
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
        return 'Tier 1: SMS sent to inner circle (${_tier2Threshold - _secondsElapsed}s until Tier 2)';
      case 2:
        return 'Tier 2: Extended network alerted (${_tier3Threshold - _secondsElapsed}s until Echo feed post)';
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

  /// Apply distress-based timer adjustments (speeds up escalation)
  void applyDistressAdjustment({double speedupMultiplier = 0.33}) {
    if (!_isRunning) return;
    
    // Reduce thresholds by the multiplier (e.g., 0.33 = 1/3 of original time)
    final originalTier2 = _tier2Threshold;
    final originalTier3 = _tier3Threshold;
    
    _tier2Threshold = (originalTier2 * speedupMultiplier).toInt().clamp(5, originalTier2);
    _tier3Threshold = (originalTier3 * speedupMultiplier).toInt().clamp(10, originalTier3);
    
    print('⚠️ DISTRESS ADJUSTMENT APPLIED');
    print('   Tier 2: ${originalTier2}s → ${_tier2Threshold}s');
    print('   Tier 3: ${originalTier3}s → ${_tier3Threshold}s');
  }
}
