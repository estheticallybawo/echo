import 'package:flutter/material.dart';
import '../services/firestore_incident_service.dart';
import 'escalation_countdown_widget.dart';

/// Emergency Button Handler - Track C
/// Coordinates emergency activation with escalation timer
class EmergencyButtonHandler {
  static Future<void> handleEmergencyTrigger({
    required BuildContext context,
    required String userId,
    required String userLocation,
    required Function(String incidentId) onIncidentCreated,
  }) async {
    try {
      // Step 1: Create incident in Firestore
      final firestoreService = FirestoreIncidentService();
      final incidentId = await firestoreService.logIncident(
        userId: userId,
        actionType: 'emergency_button',
        contactId: 'primary_contact', // Will be updated by escalation service
        location: userLocation,
        threatLevel: 'CRITICAL',
        threatCategory: 'emergency_activation',
        gemmaAnalysis: 'User manually triggered emergency',
      );

      // Step 2: Notify caller that incident was created
      onIncidentCreated(incidentId);

      // Step 3: Show escalation countdown UI
      if (context.mounted) {
        _showEscalationBottomSheet(
          context,
          incidentId: incidentId,
          userId: userId,
          location: userLocation,
          firestoreService: firestoreService,
        );
      }
    } catch (e) {
      print('❌ Error handling emergency: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static void _showEscalationBottomSheet(
    BuildContext context, {
    required String incidentId,
    required String userId,
    required String location,
    required FirestoreIncidentService firestoreService,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EscalationCountdownWidget(
              incidentId: incidentId,
              onTier1Activate: () {
                print('📢 Tier 1 activation: Inner circle alerted');
                // Additional analytics/logging here
              },
              onTier2Escalate: () {
                print('📢 Tier 2 escalation: Extended network');
                // Additional analytics/logging here
              },
              onTier1Nudge: () {
                print('📢 Tier 1 nudge sent');
                // Additional analytics/logging here
              },
              onTier3Escalate: () {
                print('📢 Tier 3 auto-post to X');
                // Additional analytics/logging here
              },
              onEscalationStop: () {
                print('✅ Escalation stopped by user');
              },
            ),
          ),
        ),
      ),
    );
  }
}
