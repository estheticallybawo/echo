import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'geolocation_enrichment_service.dart';
import 'package:echo/services/gemma/llama_threat_service.dart';

class EchoFeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeolocationEnrichmentService _geoService = GeolocationEnrichmentService();
  final LlamaThreatService _gemmaService = LlamaThreatService();

  /// Post an emergency to the Echo Feed (Tier 3 escalation)
  Future<void> postEmergencyToFeed({
    required String incidentId,
    required String userId,
    required String victimName,
    required String locationText,
    required double? latitude,
    required double? longitude,
    required Map<String, dynamic> threatAssessment,
  }) async {
    try {
      // 1. Enrich location
      final enriched = await _geoService.getEnrichedContext(
        locationText: locationText,
        lat: latitude,
        lon: longitude,
      );

      // 2. Generate feed post using Gemma
      final postText = await _gemmaService.generateEchoFeedPost(
        userInput: threatAssessment['summary'] ?? 'Emergency reported',
        threat: threatAssessment,
        location: locationText,
        policeHandle: enriched['localPolice']!,
        hotline: enriched['emergencyHotline']!,
      );

      // 3. Save to Firestore
      await _firestore.collection('echo_feed').add({
        'incidentId': incidentId,
        'userId': userId,
        'victimName': victimName,
        'location': locationText,
        'postText': postText,
        'threatType': threatAssessment['threat'],
        'confidence': threatAssessment['confidence'],
        'threatLevel': threatAssessment['threatLevel'],
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'shareCount': 0,
        'amplifiedBy': [],
        'policeHandle': enriched['localPolice'],
        'hotline': enriched['emergencyHotline'],
      });
      print('✅ Echo Feed post created for incident $incidentId');
    } catch (e) {
      print('❌ Failed to post to Echo Feed: $e');
      // Fallback: simple post without Gemma
      await _fallbackPost(incidentId, userId, victimName, locationText, threatAssessment);
    }
  }

  Future<void> _fallbackPost(
    String incidentId,
    String userId,
    String victimName,
    String locationText,
    Map<String, dynamic> threat,
  ) async {
    final fallbackText = '🚨 ${threat['threat']} alert near $locationText. If you have info, contact local police. #EchoAlert';
    await _firestore.collection('echo_feed').add({
      'incidentId': incidentId,
      'userId': userId,
      'victimName': victimName,
      'location': locationText,
      'postText': fallbackText,
      'threatType': threat['threat'],
      'confidence': threat['confidence'],
      'threatLevel': threat['threatLevel'],
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'active',
      'shareCount': 0,
      'amplifiedBy': [],
    });
  }
}