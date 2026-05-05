import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Track C: User Profile Service
/// Manages user-specific data persistence across sessions
/// Stores: profile info, emergency contacts, preferences, threat history

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();

  factory UserProfileService() {
    return _instance;
  }

  UserProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// User profile document structure
  static const String usersCollection = 'users';
  static const String contactsSubcollection = 'emergency_contacts';
  static const String threatHistorySubcollection = 'threat_history';

  /// Initialize user profile on first login
  Future<void> initializeUserProfile({
    required String fullName,
    required String phone,
    required String emergencyEmail,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return;
      }

      final userDoc = _firestore.collection(usersCollection).doc(user.uid);
      
      // Check if profile already exists
      final exists = await userDoc.get();
      if (exists.exists) {
        print('✅ User profile already exists');
        return;
      }

      // Create new user profile
      await userDoc.set({
        'uid': user.uid,
        'full_name': fullName,
        'phone': phone,
        'emergency_email': emergencyEmail,
        'onboarding_completed': true,
        'created_at': FieldValue.serverTimestamp(),
        'last_updated': FieldValue.serverTimestamp(),
        'threat_threshold': 'none', // User's default threat sensitivity
        'auto_escalate_enabled': true, // Auto-escalate to Tier 3 if true
        'notification_preferences': {
          'sms_alerts': true,
          'whatsapp_alerts': true,
          'email_alerts': false,
        },
        'privacy_settings': {
          'share_location_with_contacts': true,
          'allow_public_posts': true,
          'store_incident_history': true,
        }
      });

      print('✅ User profile created: $fullName');
    } catch (e) {
      print('❌ Error initializing user profile: $e');
    }
  }

  /// Add emergency contact for user
  Future<void> addEmergencyContact({
    required String contactName,
    required String phone,
    required String relationship,
    String? whatsappGroup,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .collection(contactsSubcollection)
          .add({
        'name': contactName,
        'phone': phone,
        'relationship': relationship,
        'whatsapp_group': whatsappGroup,
        'added_at': FieldValue.serverTimestamp(),
        'is_active': true,
      });

      print('✅ Emergency contact added: $contactName');
    } catch (e) {
      print('❌ Error adding emergency contact: $e');
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .get();

      return doc.data();
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Get user's emergency contacts
  Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .collection(contactsSubcollection)
          .where('is_active', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error fetching emergency contacts: $e');
      return [];
    }
  }

  /// Update user threat threshold based on history
  /// Higher threshold = more alerts needed before escalating
  Future<void> updateThreatThreshold(String newThreshold) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .update({'threat_threshold': newThreshold});

      print('✅ Threat threshold updated: $newThreshold');
    } catch (e) {
      print('❌ Error updating threat threshold: $e');
    }
  }

  /// Record threat to user's history for pattern analysis
  Future<void> recordThreatToHistory({
    required String incidentId,
    required String threatType,
    required double confidence,
    required String location,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .collection(threatHistorySubcollection)
          .add({
        'incident_id': incidentId,
        'threat_type': threatType,
        'confidence': confidence,
        'location': location,
        'recorded_at': FieldValue.serverTimestamp(),
      });

      print('✅ Threat recorded to history: $threatType');
    } catch (e) {
      print('❌ Error recording threat: $e');
    }
  }

  /// Get user's threat history for pattern analysis
  Future<List<Map<String, dynamic>>> getThreatHistory({int days = 30}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .collection(threatHistorySubcollection)
          .where('recorded_at',
              isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('recorded_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error fetching threat history: $e');
      return [];
    }
  }

  /// Stream user profile changes in real-time
  Stream<Map<String, dynamic>?> watchUserProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection(usersCollection)
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Update user's privacy settings
  Future<void> updatePrivacySettings({
    required bool shareLocation,
    required bool allowPublicPosts,
    required bool storeIncidentHistory,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .update({
        'privacy_settings.share_location_with_contacts': shareLocation,
        'privacy_settings.allow_public_posts': allowPublicPosts,
        'privacy_settings.store_incident_history': storeIncidentHistory,
      });

      print('✅ Privacy settings updated');
    } catch (e) {
      print('❌ Error updating privacy settings: $e');
    }
  }

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    try {
      final profile = await getUserProfile();
      return profile?['onboarding_completed'] ?? false;
    } catch (e) {
      print('❌ Error checking onboarding status: $e');
      return false;
    }
  }
}
