import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gemma_threat_assessment_service.dart';
import '../services/firestore_incident_service.dart';

/// Track C: Gemma 4 Threat Assessment Provider
/// Week 1: Mocks Google AI Studio
/// Week 2+: Real Gemma 4 API calls + Ollama fallback
class GemmaProvider extends ChangeNotifier {
  final GemmaThreatAssessmentService _gemmaService;
  final FirestoreIncidentService _firestoreService = FirestoreIncidentService();
  
  bool isAnalyzing = false;
  Map<String, dynamic>? lastThreatAssessment;
  String? error;
  String? lastIncidentId; // Track last logged incident
  
  GemmaProvider({required GemmaThreatAssessmentService gemmaService})
      : _gemmaService = gemmaService;
  
  /// Week 1: Mock threat analysis (Days 1-2)
  Future<Map<String, dynamic>> analyzeThreatMock(String audioContext) async {
    isAnalyzing = true;
    error = null;
    notifyListeners();
    
    try {
      final result = await _gemmaService.analyzeThreatMock(audioContext);
      lastThreatAssessment = result;
      isAnalyzing = false;
      notifyListeners();
      return result;
    } catch (e) {
      error = e.toString();
      isAnalyzing = false;
      notifyListeners();
      return {};
    }
  }
  
  /// Week 2+: Real Gemma 4 threat analysis
  Future<Map<String, dynamic>> analyzeThreat(String audioContext) async {
    isAnalyzing = true;
    error = null;
    notifyListeners();
    
    try {
      final result = await _gemmaService.analyzeThreat(audioContext);
      lastThreatAssessment = result;
      isAnalyzing = false;
      notifyListeners();
      return result;
    } catch (e) {
      error = e.toString();
      isAnalyzing = false;
      notifyListeners();
      return {};
    }
  }
  
  /// 🔥 Log threat assessment to Firestore
  /// 
  /// Called after Gemma analyzes threat, persists to real-time database
  /// Fires confirmation sound listeners when document is created
  Future<void> logThreatToFirestore({
    required String contactId,
    required String location,
  }) async {
    if (lastThreatAssessment == null) {
      error = 'No threat assessment to log';
      notifyListeners();
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        error = 'User not authenticated';
        notifyListeners();
        return;
      }

      final threatLevel = (lastThreatAssessment!['threatLevel'] ?? 'HIGH').toString().toUpperCase();
      final threatCategory = (lastThreatAssessment!['threat'] ?? 'unknown_threat').toString();
      final analysisJson = lastThreatAssessment.toString();

      // Log to Firestore
      lastIncidentId = await _firestoreService.logIncident(
        userId: user.uid,
        actionType: 'emergency_press',
        contactId: contactId,
        location: location,
        threatLevel: threatLevel,
        threatCategory: threatCategory,
        gemmaAnalysis: analysisJson,
      );

      error = null;
      notifyListeners();
      print('✅ Threat logged to Firestore: $lastIncidentId');
    } catch (e) {
      error = 'Failed to log threat: $e';
      notifyListeners();
      print('❌ Firestore logging error: $e');
    }
  }
  
  /// Generate post preview from threat assessment
  /// Note: Requires userName and location
  String generatePostPreview(String userName, String location) {
    if (lastThreatAssessment == null) return '';
    return _gemmaService.generateEmergencyPost(userName, location, lastThreatAssessment!);
  }
  
  /// Get real-time stream of incidents from Firestore
  /// 
  /// Used by incident_log_screen to display live incident updates
  /// Returns stream of incidents ordered by timestamp (newest first)
  Stream<List<IncidentModel>> getIncidentsStream() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ GemmaProvider: No authenticated user for incidents stream');
        return Stream.value([]);
      }
      return _firestoreService.getIncidentStream(user.uid);
    } catch (e) {
      print('❌ Error getting incidents stream: $e');
      return Stream.value([]);
    }
  }
}
