import 'package:hive_flutter/hive_flutter.dart';

/// Local storage service for offline-first data persistence
/// Uses Hive for web/mobile compatibility
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  // Box names
  static const String usersBoxName = 'users';
  static const String contactsBoxName = 'contacts';
  static const String incidentsBoxName = 'incidents';
  static const String preferencesBoxName = 'preferences';

  // Lazy-loaded boxes
  late Box _usersBox;
  late Box _contactsBox;
  late Box _incidentsBox;
  late Box _preferencesBox;

  bool _initialized = false;

  /// Initialize Hive and all boxes
  /// Must be called once at app startup (e.g., in main.dart)
  Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Open boxes
    _usersBox = await Hive.openBox(usersBoxName);
    _contactsBox = await Hive.openBox(contactsBoxName);
    _incidentsBox = await Hive.openBox(incidentsBoxName);
    _preferencesBox = await Hive.openBox(preferencesBoxName);

    _initialized = true;
  }

  // ==================== USERS BOX ====================
  /// Save current user (local demo UID + basic info).
  Future<void> setCurrentUser({
    required String uid,
    required String email,
    required String? displayName,
  }) async {
    final existing = getUserByUid(uid) ?? getCurrentUser();
    final existingDisplayName = existing?['displayName'] as String?;
    final existingCreatedAt = existing?['createdAt'] as String?;
    final incomingDisplayName = displayName?.trim() ?? '';
    final user = {
      'uid': uid,
      'email': email,
      'displayName': incomingDisplayName.isNotEmpty
          ? incomingDisplayName
          : (existingDisplayName ?? ''),
      'createdAt': existingCreatedAt ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await _usersBox.put('current_user', user);
    await _usersBox.put('user_$uid', user);
  }

  /// Get current user UID (used to isolate all user data)
  String? getCurrentUserUid() {
    return getCurrentUser()?['uid'] as String?;
  }

  /// Get full current user data
  Map<String, dynamic>? getCurrentUser() {
    final user = _usersBox.get('current_user');
    return _asStringMap(user);
  }

  Map<String, dynamic>? getUserByUid(String uid) {
    final user = _usersBox.get('user_$uid');
    return _asStringMap(user);
  }

  /// Clear user on logout
  Future<void> clearCurrentUser() async {
    await _usersBox.delete('current_user');
    // TODO: Clear user-specific data (contacts, incidents)
  }

  // ==================== CONTACTS BOX ====================
  /// Get user's emergency contacts
  /// Key: "contacts_${userId}"
  List<Map<String, dynamic>> getContacts(String userId) {
    final key = 'contacts_$userId';
    final data = _contactsBox.get(key);
    if (data is List) {
      return data.map(_asStringMap).whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Add emergency contact
  Future<void> addContact(
    String userId, {
    required String name,
    required String phoneNumber,
  }) async {
    final key = 'contacts_$userId';
    final contacts = getContacts(userId);
    contacts.add({
      'id': DateTime.now().millisecondsSinceEpoch, // Simple unique ID
      'name': name,
      'phoneNumber': phoneNumber,
      'addedAt': DateTime.now().toIso8601String(),
    });
    await _contactsBox.put(key, contacts);
  }

  /// Remove emergency contact
  Future<void> removeContact(String userId, int contactId) async {
    final key = 'contacts_$userId';
    final contacts = getContacts(userId);
    contacts.removeWhere((c) => c['id'] == contactId);
    await _contactsBox.put(key, contacts);
  }

  /// Update emergency contact
  Future<void> updateContact(
    String userId,
    int contactId, {
    required String name,
    required String phoneNumber,
  }) async {
    final key = 'contacts_$userId';
    final contacts = getContacts(userId);
    final index = contacts.indexWhere((c) => c['id'] == contactId);
    if (index >= 0) {
      contacts[index] = {
        'id': contactId,
        'name': name,
        'phoneNumber': phoneNumber,
        'addedAt': contacts[index]['addedAt'],
      };
      await _contactsBox.put(key, contacts);
    }
  }

  // ==================== INCIDENTS BOX ====================
  /// Get user's incidents
  /// Key: "incidents_${userId}"
  List<Map<String, dynamic>> getIncidents(String userId) {
    final key = 'incidents_$userId';
    final data = _incidentsBox.get(key);
    if (data is List) {
      return data.map(_asStringMap).whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Create new incident record
  Future<int> createIncident(
    String userId, {
    required String? audioPath,
    required double? threatLevel,
    required String? transcription,
  }) async {
    final key = 'incidents_$userId';
    final incidents = getIncidents(userId);
    final incidentId = DateTime.now().millisecondsSinceEpoch;

    incidents.add({
      'id': incidentId,
      'userId': userId,
      'audioPath': audioPath,
      'threatLevel': threatLevel,
      'transcription': transcription,
      'createdAt': DateTime.now().toIso8601String(),
      'isSafe': false,
      'markedSafeAt': null,
      'analyzed': false,
    });

    await _incidentsBox.put(key, incidents);
    return incidentId;
  }

  /// Mark incident as safe (ends emergency)
  Future<void> markIncidentSafe(String userId, int incidentId) async {
    final key = 'incidents_$userId';
    final incidents = getIncidents(userId);
    final index = incidents.indexWhere((i) => i['id'] == incidentId);
    if (index >= 0) {
      incidents[index]['isSafe'] = true;
      incidents[index]['markedSafeAt'] = DateTime.now().toIso8601String();
      await _incidentsBox.put(key, incidents);
    }
  }

  /// Mark incident as analyzed (threat analysis complete)
  Future<void> markIncidentAnalyzed(
    String userId,
    int incidentId, {
    required double threatLevel,
    required String analysis,
  }) async {
    final key = 'incidents_$userId';
    final incidents = getIncidents(userId);
    final index = incidents.indexWhere((i) => i['id'] == incidentId);
    if (index >= 0) {
      incidents[index]['analyzed'] = true;
      incidents[index]['threatLevel'] = threatLevel;
      incidents[index]['analysis'] = analysis;
      incidents[index]['analyzedAt'] = DateTime.now().toIso8601String();
      await _incidentsBox.put(key, incidents);
    }
  }

  /// Get single incident by ID
  Map<String, dynamic>? getIncident(String userId, int incidentId) {
    final incidents = getIncidents(userId);
    try {
      return incidents.firstWhere((i) => i['id'] == incidentId);
    } catch (e) {
      return null;
    }
  }

  // ==================== PREFERENCES BOX ====================
  /// Save app preferences
  Future<void> setPreference(String key, dynamic value) async {
    await _preferencesBox.put(key, value);
  }

  /// Get app preference
  dynamic getPreference(String key, {dynamic defaultValue}) {
    return _preferencesBox.get(key, defaultValue: defaultValue);
  }

  /// Save user-specific preference (e.g., language, theme)
  Future<void> setUserPreference(
    String userId,
    String key,
    dynamic value,
  ) async {
    await _preferencesBox.put('${userId}_$key', value);
  }

  /// Get user-specific preference
  dynamic getUserPreference(String userId, String key, {dynamic defaultValue}) {
    return _preferencesBox.get('${userId}_$key', defaultValue: defaultValue);
  }

  // ==================== CLEANUP ====================
  /// Close all boxes (call at app shutdown if needed)
  Future<void> close() async {
    await Hive.close();
  }

  /// Clear all data (for testing or logout)
  Future<void> clearAll() async {
    await _usersBox.clear();
    await _contactsBox.clear();
    await _incidentsBox.clear();
    await _preferencesBox.clear();
  }

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }
}
