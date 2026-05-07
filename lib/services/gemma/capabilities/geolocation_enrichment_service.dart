import 'package:cloud_firestore/cloud_firestore.dart';

class GeolocationEnrichmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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