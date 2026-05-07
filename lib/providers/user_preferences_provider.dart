import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';
import '../services/gemma/gemma_decision_engine.dart';

/// Track C: User Preferences Provider
/// Manages user-specific settings and profile data
/// Integrates with UserProfileService and GemmaDecisionEngine for dynamic app behavior

class UserPreferencesProvider extends ChangeNotifier {
  final UserProfileService _userProfileService = UserProfileService();
  final GemmaDecisionEngine _decisionEngine = GemmaDecisionEngine();

  // User profile data
  String? _userId;
  String? _fullName;
  String? _phone;
  String? _emergencyEmail;
  bool _onboardingComplete = false;
  String _threatThreshold = 'medium';
  bool _autoEscalateEnabled = true;
  
  // Notification preferences
  bool _smsAlertsEnabled = true;
  bool _whatsappAlertsEnabled = true;
  bool _emailAlertsEnabled = false;

  // Privacy settings
  bool _shareLocationWithContacts = true;
  bool _allowPublicPosts = true;
  bool _storeIncidentHistory = true;

  // Emergency contacts
  List<Map<String, dynamic>> _emergencyContacts = [];

  // User threat profile
  Map<String, dynamic> _threatProfile = {};

  // Getters
  String? get userId => _userId;
  String? get fullName => _fullName;
  String? get phone => _phone;
  String? get emergencyEmail => _emergencyEmail;
  bool get onboardingComplete => _onboardingComplete;
  String get threatThreshold => _threatThreshold;
  bool get autoEscalateEnabled => _autoEscalateEnabled;

  bool get smsAlertsEnabled => _smsAlertsEnabled;
  bool get whatsappAlertsEnabled => _whatsappAlertsEnabled;
  bool get emailAlertsEnabled => _emailAlertsEnabled;

  bool get shareLocationWithContacts => _shareLocationWithContacts;
  bool get allowPublicPosts => _allowPublicPosts;
  bool get storeIncidentHistory => _storeIncidentHistory;

  List<Map<String, dynamic>> get emergencyContacts => _emergencyContacts;
  Map<String, dynamic> get threatProfile => _threatProfile;

  /// Initialize user profile on first app launch or re-login
  Future<void> initializeUserProfile() async {
    try {
      print('🔄 Loading user profile...');
      
      final profile = await _userProfileService.getUserProfile();
      if (profile != null) {
        _userId = profile['uid'];
        _fullName = profile['full_name'];
        _phone = profile['phone'];
        _emergencyEmail = profile['emergency_email'];
        _onboardingComplete = profile['onboarding_completed'] ?? false;
        _threatThreshold = profile['threat_threshold'] ?? 'medium';
        _autoEscalateEnabled = profile['auto_escalate_enabled'] ?? true;

        // Load notification preferences
        final notifPrefs = profile['notification_preferences'] ?? {};
        _smsAlertsEnabled = notifPrefs['sms_alerts'] ?? true;
        _whatsappAlertsEnabled = notifPrefs['whatsapp_alerts'] ?? true;
        _emailAlertsEnabled = notifPrefs['email_alerts'] ?? false;

        // Load privacy settings
        final privacySettings = profile['privacy_settings'] ?? {};
        _shareLocationWithContacts = privacySettings['share_location_with_contacts'] ?? true;
        _allowPublicPosts = privacySettings['allow_public_posts'] ?? true;
        _storeIncidentHistory = privacySettings['store_incident_history'] ?? true;

        print('✅ User profile loaded: $_fullName');
      } else {
        print('⚠️ No user profile found - onboarding required');
        _onboardingComplete = false;
      }

      // Load emergency contacts
      await loadEmergencyContacts();

      // Load threat profile
      await loadThreatProfile();

      notifyListeners();
    } catch (e) {
      print('❌ Error initializing user profile: $e');
    }
  }

  /// Create new user profile during onboarding
  Future<void> createUserProfile({
    required String fullName,
    required String phone,
    required String emergencyEmail,
  }) async {
    try {
      await _userProfileService.initializeUserProfile(
        fullName: fullName,
        phone: phone,
        emergencyEmail: emergencyEmail,
      );

      _fullName = fullName;
      _phone = phone;
      _emergencyEmail = emergencyEmail;
      _onboardingComplete = true;

      notifyListeners();
      print('✅ User profile created');
    } catch (e) {
      print('❌ Error creating user profile: $e');
    }
  }

  /// Add emergency contact
  Future<void> addEmergencyContact({
    required String contactName,
    required String phone,
    required String relationship,
    String? whatsappGroup,
  }) async {
    try {
      await _userProfileService.addEmergencyContact(
        contactName: contactName,
        phone: phone,
        relationship: relationship,
        whatsappGroup: whatsappGroup,
      );

      await loadEmergencyContacts();
      notifyListeners();
      print('✅ Emergency contact added');
    } catch (e) {
      print('❌ Error adding emergency contact: $e');
    }
  }

  /// Load emergency contacts
  Future<void> loadEmergencyContacts() async {
    try {
      _emergencyContacts = await _userProfileService.getEmergencyContacts();
      notifyListeners();
    } catch (e) {
      print('❌ Error loading emergency contacts: $e');
    }
  }

  /// Update threat threshold (user's sensitivity to threats)
  Future<void> setThreatThreshold(String newThreshold) async {
    try {
      await _userProfileService.updateThreatThreshold(newThreshold);
      _threatThreshold = newThreshold;
      notifyListeners();
      print('✅ Threat threshold updated: $newThreshold');
    } catch (e) {
      print('❌ Error updating threat threshold: $e');
    }
  }

  /// Toggle auto-escalation
  Future<void> setAutoEscalate(bool enabled) async {
    try {
      // Note: In real implementation, add this to UserProfileService
      _autoEscalateEnabled = enabled;
      notifyListeners();
      print('✅ Auto-escalation ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('❌ Error toggling auto-escalation: $e');
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    bool? smsAlerts,
    bool? whatsappAlerts,
    bool? emailAlerts,
  }) async {
    try {
      if (smsAlerts != null) _smsAlertsEnabled = smsAlerts;
      if (whatsappAlerts != null) _whatsappAlertsEnabled = whatsappAlerts;
      if (emailAlerts != null) _emailAlertsEnabled = emailAlerts;

      notifyListeners();
      print('✅ Notification preferences updated');
    } catch (e) {
      print('❌ Error updating notification preferences: $e');
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings({
    required bool shareLocation,
    required bool allowPublicPosts,
    required bool storeIncidentHistory,
  }) async {
    try {
      await _userProfileService.updatePrivacySettings(
        shareLocation: shareLocation,
        allowPublicPosts: allowPublicPosts,
        storeIncidentHistory: storeIncidentHistory,
      );

      _shareLocationWithContacts = shareLocation;
      _allowPublicPosts = allowPublicPosts;
      _storeIncidentHistory = storeIncidentHistory;

      notifyListeners();
      print('✅ Privacy settings updated');
    } catch (e) {
      print('❌ Error updating privacy settings: $e');
    }
  }

  /// Load user's threat profile for dashboard/stats
  Future<void> loadThreatProfile() async {
    try {
      _threatProfile = await _decisionEngine.getUserThreatProfile();
      notifyListeners();
      print('✅ Threat profile loaded');
    } catch (e) {
      print('❌ Error loading threat profile: $e');
    }
  }

  /// Get recommendation for current user's threat level
  Future<String> getUserThreatLevelRecommendation() async {
    try {
      final incidentCount = _threatProfile['incident_count'] ?? 0;
      
      if (incidentCount > 5) {
        return 'HIGH: Consider enabling high-sensitivity alerting';
      } else if (incidentCount > 2) {
        return 'MEDIUM: Your threat frequency is moderate';
      } else if (incidentCount > 0) {
        return 'LOW: Limited threat history, consider standard settings';
      } else {
        return 'NO_DATA: No incidents recorded yet';
      }
    } catch (e) {
      return 'ERROR: Could not determine threat level';
    }
  }

  /// Check if user is ready for emergency activation
  /// (Has completed onboarding, has emergency contacts, etc.)
  Future<bool> isReadyForEmergency() async {
    try {
      final hasContacts = _emergencyContacts.isNotEmpty;
      final isOnboarded = _onboardingComplete;
      
      return hasContacts && isOnboarded;
    } catch (e) {
      print('❌ Error checking emergency readiness: $e');
      return false;
    }
  }

  /// Export user's threat profile as summary
  String getThreatProfileSummary() {
    return '''
Threat Profile Summary:
- Total Incidents: ${_threatProfile['incident_count'] ?? 0}
- Most Common Threat: ${_threatProfile['most_common_threat'] ?? 'None'}
- Threat Types: ${_threatProfile['threat_types'] ?? {}}
- Average Confidence: ${_threatProfile['avg_confidence'] ?? 'N/A'}%
''';
  }
}
