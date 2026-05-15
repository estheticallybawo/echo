import 'package:cloud_firestore/cloud_firestore.dart';
import 'capabilities/geolocation_enrichment_service.dart';
import 'package:echo/services/gemma/llama_threat_service.dart';

class EchoFeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeolocationEnrichmentService _geoService =
      GeolocationEnrichmentService();
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
    final publicLocation = _publicLocationLabel(locationText);

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
        location: publicLocation,
        policeHandle: enriched['localPolice']!,
        hotline: enriched['emergencyHotline']!,
      );

      // 3. Save to Firestore
      await _firestore.collection('echo_feed').add({
        'incidentId': incidentId,
        'userId': userId,
        'victimName': victimName,
        'location': publicLocation,
        'postText': postText,
        'threatType': threatAssessment['threat'],
        'confidence': threatAssessment['confidence'],
        'threatLevel': threatAssessment['threatLevel'],
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'shareCount': 0,
        'amplifiedBy': [],
        'privacyNote': 'Exact location link hidden from public feed.',
        'policeHandle': enriched['localPolice'],
        'hotline': enriched['emergencyHotline'],
      });
      // ignore: avoid_print
      print('✅ Echo Feed post created for incident $incidentId');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Failed to post to Echo Feed: $e');
      // Fallback: simple post without Gemma
      await _fallbackPost(
        incidentId,
        userId,
        victimName,
        publicLocation,
        threatAssessment,
      );
    }
  }

  String _publicLocationLabel(String locationText) {
    final trimmed = locationText.trim();
    if (trimmed.isEmpty) return 'area withheld';

    final hasLink =
        trimmed.contains('http://') ||
        trimmed.contains('https://') ||
        trimmed.toLowerCase().contains('maps.google');
    final hasCoordinates = RegExp(
      r'-?\d{1,3}\.\d+[, ]+\s*-?\d{1,3}\.\d+',
    ).hasMatch(trimmed);
    if (hasLink || hasCoordinates) return 'area withheld';

    final parts = trimmed
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length <= 2) return trimmed;
    return parts.take(2).join(', ');
  }

  Future<void> _fallbackPost(
    String incidentId,
    String userId,
    String victimName,
    String locationText,
    Map<String, dynamic> threat,
  ) async {
    final fallbackText =
        '🚨 ${threat['threat']} alert near $locationText. If you have info, contact local police. #EchoAlert';
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
      'privacyNote': 'Exact location link hidden from public feed.',
    });
  }
}
