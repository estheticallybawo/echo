// Track C: Firestore Incident Service
// Real-time incident logging to Firestore (replaces deleted Isar database)

import 'package:cloud_firestore/cloud_firestore.dart';

/// Incident data model for Firestore storage
/// 
/// Firestore Collection: /incidents/{userId}/logs/{incidentId}
/// 
/// Schema:
/// {
///   "action_type": "emergency_press",  // Type of action triggered
///   "timestamp": Timestamp,             // When incident occurred
///   "contact_id": "contact_123",        // Which contact triggered it
///   "location": "12.34, 56.78",         // GPS coordinates
///   "threat_level": "HIGH",             // Gemma assessment: LOW, MEDIUM, HIGH, CRITICAL
///   "threat_category": "domestic_abuse", // Gemma assessment: domestic_abuse, robbery, etc.
///   "gemma_analysis": "...",            // Full Gemma threat response
///   "escalation_status": "NOT_STARTED", // NOT_STARTED, PENDING, ESCALATED, CANCELLED
///   "escalation_time": Timestamp,       // When escalation triggered (if any)
///   "user_id": "user_xyz",              // Owner of incident
///   "confirmation_status": "PENDING"    // PENDING, CONFIRMED, DISMISSED
/// }
class IncidentModel {
  final String id;
  final String actionType;
  final DateTime timestamp;
  final String contactId;
  final String location;
  final String threatLevel;
  final String? threatCategory;
  final String? gemmaAnalysis;
  final String escalationStatus;
  final DateTime? escalationTime;
  final String userId;
  final String confirmationStatus;

  IncidentModel({
    required this.id,
    required this.actionType,
    required this.timestamp,
    required this.contactId,
    required this.location,
    required this.threatLevel,
    this.threatCategory,
    this.gemmaAnalysis,
    this.escalationStatus = 'NOT_STARTED',
    this.escalationTime,
    required this.userId,
    this.confirmationStatus = 'PENDING',
  });

  /// Convert model to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'action_type': actionType,
      'timestamp': timestamp,
      'contact_id': contactId,
      'location': location,
      'threat_level': threatLevel,
      'threat_category': threatCategory,
      'gemma_analysis': gemmaAnalysis,
      'escalation_status': escalationStatus,
      'escalation_time': escalationTime,
      'user_id': userId,
      'confirmation_status': confirmationStatus,
    };
  }

  /// Create model from Firestore document
  factory IncidentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return IncidentModel(
      id: doc.id,
      actionType: data['action_type'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      contactId: data['contact_id'] ?? '',
      location: data['location'] ?? '',
      threatLevel: data['threat_level'] ?? 'UNKNOWN',
      threatCategory: data['threat_category'],
      gemmaAnalysis: data['gemma_analysis'],
      escalationStatus: data['escalation_status'] ?? 'NOT_STARTED',
      escalationTime: data['escalation_time'] != null
          ? (data['escalation_time'] as Timestamp).toDate()
          : null,
      userId: data['user_id'] ?? '',
      confirmationStatus: data['confirmation_status'] ?? 'PENDING',
    );
  }
}

/// Firestore Incident Service
/// 
/// Provides CRUD operations for incident logging and real-time listeners
/// Used by emergency_active_screen to log threats, confirmation_sound_service to listen for updates
class FirestoreIncidentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for current user's incidents
  CollectionReference<Map<String, dynamic>> _getIncidentsCollection(
    String userId,
  ) =>
      _firestore.collection('incidents').doc(userId).collection('logs');

  /// 📝 Log a new incident to Firestore
  /// 
  /// Called after Gemma threat assessment to persist incident
  /// Returns incident ID for reference
  Future<String> logIncident({
    required String userId,
    required String actionType,
    required String contactId,
    required String location,
    required String threatLevel,
    String? threatCategory,
    String? gemmaAnalysis,
  }) async {
    try {
      final incident = IncidentModel(
        id: '', // Firestore will generate
        actionType: actionType,
        timestamp: DateTime.now(),
        contactId: contactId,
        location: location,
        threatLevel: threatLevel,
        threatCategory: threatCategory,
        gemmaAnalysis: gemmaAnalysis,
        userId: userId,
        escalationStatus: 'NOT_STARTED',
        confirmationStatus: 'PENDING',
      );

      final docRef = await _getIncidentsCollection(userId).add(
        incident.toFirestore(),
      );

      print('✅ Incident logged: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error logging incident: $e');
      rethrow;
    }
  }

  /// 🔄 Get real-time stream of incidents for a user
  /// 
  /// Used by confirmation_sound_service and incident_timeline UI
  /// Stream auto-updates when new incidents added to Firestore
  Stream<List<IncidentModel>> getIncidentStream(String userId) {
    return _getIncidentsCollection(userId)
        .orderBy('timestamp', descending: true)
        .limit(50) // Last 50 incidents
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IncidentModel.fromFirestore(doc))
          .toList();
    });
  }

  /// 👂 Listen to a specific incident document (for confirmation sounds)
  /// 
  /// Watches a single incident for updates (e.g., escalation status change)
  /// Triggers confirmation sound when escalation_status changes
  Stream<IncidentModel> listenToIncident(String userId, String incidentId) {
    return _getIncidentsCollection(userId)
        .doc(incidentId)
        .snapshots()
        .map((doc) => IncidentModel.fromFirestore(doc));
  }

  /// ✏️ Update incident escalation status
  /// 
  /// Called by escalation_timer_service when countdown expires
  /// Or by user action to cancel/confirm escalation
  Future<void> updateIncident(
    String userId,
    String incidentId, {
    String? escalationStatus,
    String? confirmationStatus,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (escalationStatus != null) {
        updateData['escalation_status'] = escalationStatus;
        updateData['escalation_time'] = DateTime.now();
      }
      if (confirmationStatus != null) {
        updateData['confirmation_status'] = confirmationStatus;
      }

      await _getIncidentsCollection(userId).doc(incidentId).update(updateData);
      print('✅ Incident updated: $incidentId');
    } catch (e) {
      print('❌ Error updating incident: $e');
      rethrow;
    }
  }

  /// 📊 Get recent incidents (for incident timeline UI)
  /// 
  /// One-time query (not real-time) for displaying incident history
  Future<List<IncidentModel>> getRecentIncidents(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _getIncidentsCollection(userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => IncidentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error fetching recent incidents: $e');
      rethrow;
    }
  }

  /// 🔍 Query incidents by threat level
  /// 
  /// Used to filter critical threats for review
  Future<List<IncidentModel>> getIncidentsByThreatLevel(
    String userId,
    String threatLevel,
  ) async {
    try {
      final snapshot = await _getIncidentsCollection(userId)
          .where('threat_level', isEqualTo: threatLevel)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => IncidentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error querying incidents by threat level: $e');
      rethrow;
    }
  }

  /// 🗑️ Delete an incident
  /// 
  /// Called when user dismisses an incident or clears history
  Future<void> deleteIncident(String userId, String incidentId) async {
    try {
      await _getIncidentsCollection(userId).doc(incidentId).delete();
      print('✅ Incident deleted: $incidentId');
    } catch (e) {
      print('❌ Error deleting incident: $e');
      rethrow;
    }
  }
}
