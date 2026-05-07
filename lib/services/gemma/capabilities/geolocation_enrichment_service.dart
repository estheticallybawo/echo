import 'package:cloud_firestore/cloud_firestore.dart';

/// Geolocation enrichment service for threat analysis.
/// Provides location context for threat prompts and fetches regional emergency contacts.
class GeolocationEnrichmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _locationContext;

  /// Set the location context to be included in threat analysis prompts.
  /// Useful for providing regional emergency services information to Gemma 4.
  static void setLocationContext(String location) {
    _locationContext = location;
    print('📍 Location context set: $location');
  }

  /// Get the current location context.
  static String? getLocationContext() => _locationContext;

  /// Clear the location context.
  static void clearLocationContext() {
    _locationContext = null;
    print('📍 Location context cleared');
  }

  /// Check if location context is available.
  static bool hasLocationContext() => _locationContext != null && _locationContext!.isNotEmpty;

  /// Update location context (useful for real-time location tracking).
  static void updateLocationContext(String newLocation) {
    _locationContext = newLocation;
    print('📍 Location context updated: $newLocation');
  }

  /// Fetch local authority handles and hotline based on location name or lat/lon.
  Future<Map<String, String>> getEnrichedContext({
    required String locationText,
    double? lat,
    double? lon,
  }) async {
    final normalized = locationText.toLowerCase();
    try {
      // Try exact match first
      final doc = await _firestore.collection('location_data').doc(normalized).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'localPolice': data['emergencyContacts']?['police'] ?? '@PoliceNG',
          'localFire': data['emergencyContacts']?['fire'] ?? '@FireServiceNG',
          'localAmbulance': data['emergencyContacts']?['ambulance'] ?? '@NEMA',
          'emergencyHotline': data['emergencyContacts']?['hotline'] ?? '112',
        };
      }
      // Fallback to default Nigeria
      return {
        'localPolice': '@PoliceNG',
        'localFire': '@FireServiceNG',
        'localAmbulance': '@NEMA',
        'emergencyHotline': '112',
      };
    } catch (e) {
      return {
        'localPolice': '@PoliceNG',
        'localFire': '@FireServiceNG',
        'localAmbulance': '@NEMA',
        'emergencyHotline': '112',
      };
    }
  }
}