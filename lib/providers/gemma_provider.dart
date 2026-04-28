import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/llama_threat_service.dart';
import '../services/firestore_incident_service.dart';
import '../services/gemma_decision_engine.dart';

/// Track C: Gemma 4 Threat Assessment Provider
/// Week 1: Mocks Google AI Studio
/// Week 2+: Real Gemma 4 API calls + Ollama fallback
/// 
/// Integrates with GemmaDecisionEngine to make dynamic escalation decisions
/// based on threat assessment + user history + pattern analysis
class GemmaProvider extends ChangeNotifier {
  final LlamaThreatService _llamaThreatService;
  final FirestoreIncidentService _firestoreService = FirestoreIncidentService();
  final GemmaDecisionEngine _decisionEngine = GemmaDecisionEngine();
  
  bool isAnalyzing = false;
  Map<String, dynamic>? lastThreatAssessment;
  Map<String, dynamic>? lastDecision; // Track last escalation decision from engine
  String? error;
  String? lastIncidentId; // Track last logged incident
  
  GemmaProvider({required LlamaThreatService llamaThreatService})
      : _llamaThreatService = llamaThreatService;
  
  /// Week 1: Mock threat analysis (Days 1-2)
  Future<Map<String, dynamic>> analyzeThreatMock(String audioContext) async {
    isAnalyzing = true;
    error = null;
    notifyListeners();
    
    try {
      final result = await _llamaThreatService.analyzeThreatMock(audioContext);
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
      final result = await _llamaThreatService.analyzeThreat(audioContext);
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
  
  /// 🧠 Make escalation decision using Gemma Decision Engine
  /// 
  /// Uses threat assessment + user history + patterns to determine
  /// whether to escalate and which tier to recommend
  /// Returns decision with reasoning for audit trail
  Future<Map<String, dynamic>> makeEscalationDecision({
    required String userThreatThreshold,
    required String location,
  }) async {
    if (lastThreatAssessment == null || lastIncidentId == null) {
      return {'decision': 'ERROR', 'reason': 'No threat assessment available'};
    }

    try {
      final threatType = (lastThreatAssessment!['threat'] ?? 'unknown').toString();
      final confidence = (lastThreatAssessment!['confidence'] as num?)?.toDouble() ?? 0.0;

      // Get decision from engine
      lastDecision = await _decisionEngine.makeEscalationDecision(
        incidentId: lastIncidentId!,
        threatType: threatType,
        confidence: confidence,
        location: location,
        userThreatThreshold: userThreatThreshold,
      );

      // Recommend tier based on assessment
      final recommendedTier = await _decisionEngine.recommendTier(
        threatType: threatType,
        confidence: confidence,
        similarThreatCount: 0, // Will be calculated by decision engine
      );

      lastDecision!['recommended_tier'] = recommendedTier;

      notifyListeners();
      return lastDecision!;
    } catch (e) {
      error = 'Decision engine error: $e';
      notifyListeners();
      print('❌ Error in makeEscalationDecision: $e');
      return {'decision': 'ERROR', 'reason': e.toString()};
    }
  }
  
  /// Get contacts to notify based on threat severity
  Future<List<String>> getContactsToNotify() async {
    if (lastThreatAssessment == null) return [];
    
    try {
      final threatType = (lastThreatAssessment!['threat'] ?? 'unknown').toString();
      final confidence = (lastThreatAssessment!['confidence'] as num?)?.toDouble() ?? 0.0;

      return await _decisionEngine.getContactsToAlert(
        threatType: threatType,
        confidence: confidence,
      );
    } catch (e) {
      print('❌ Error getting contacts to notify: $e');
      return ['tier_1_emergency'];
    }
  }
  
  /// Generate custom alert message based on Gemma decision
  String generateAlertMessage(String location) {
    if (lastThreatAssessment == null) return '';
    
    final threatType = (lastThreatAssessment!['threat'] ?? 'unknown').toString();
    final confidence = (lastThreatAssessment!['confidence'] as num?)?.toDouble() ?? 0.0;

    return _decisionEngine.generateAlertMessage(
      threatType: threatType,
      confidence: confidence,
      location: location,
    );
  }
  
  /// Generate post preview from threat assessment
  /// Note: Requires userName and location
  String generatePostPreview(String userName, String location) {
    if (lastThreatAssessment == null) return '';
    return _llamaThreatService.generateEmergencyPost(userName, location, lastThreatAssessment!);
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
