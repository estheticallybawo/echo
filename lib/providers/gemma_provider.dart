import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gemma/llama_threat_service.dart';
import '../services/firestore_incident_service.dart';
import '../services/gemma/gemma_decision_engine.dart';
import '../services/escalation_timer_service.dart';

/// Provider that exposes all Gemma 4 capabilities to the UI:
/// - Threat assessment (text/voice)
/// - Spoken diversion message
/// - Post‑incident safety report
/// - Step‑by‑step emergency instructions
/// - (Optional) translation
class GemmaProvider extends ChangeNotifier {
  final LlamaThreatService _llamaThreatService;
  final FirestoreIncidentService _firestoreService = FirestoreIncidentService();
  final GemmaDecisionEngine _decisionEngine = GemmaDecisionEngine();

  bool isAnalyzing = false;
  Map<String, dynamic>? lastThreatAssessment;
  Map<String, dynamic>? lastDecision;
  String? error;
  String? lastIncidentId;

  // Cached results for new features
  String? _cachedDiversionMessage;
  String? _cachedSafetyReport;
  List<String>? _cachedSafetyInstructions;

  GemmaProvider({required LlamaThreatService llamaThreatService})
      : _llamaThreatService = llamaThreatService;

  // ----------------------------------------------------------------------
  // Location context (injected into threat assessment prompts)
  // ----------------------------------------------------------------------
  void setLocationContext(String location) {
    LlamaThreatService.setLocationContext(location);
  }

  void clearLocationContext() {
    LlamaThreatService.clearLocationContext();
  }

  // ----------------------------------------------------------------------
  // Threat assessment (original)
  // ----------------------------------------------------------------------
  Future<Map<String, dynamic>> analyzeThreatMock(String audioContext) async {
    isAnalyzing = true;
    error = null;
    notifyListeners();

    try {
      clearCachedResults();
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

  Future<Map<String, dynamic>> analyzeThreat(String audioContext) async {
    isAnalyzing = true;
    error = null;
    notifyListeners();

    try {
      clearCachedResults();
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

  // ----------------------------------------------------------------------
  // Spoken diversion message
  // ----------------------------------------------------------------------
  Future<String> getDiversionMessage() async {
    if (_cachedDiversionMessage != null) return _cachedDiversionMessage!;
    final message = await _llamaThreatService.generateDiversionMessage();
    _cachedDiversionMessage = message;
    return message;
  }

  // ----------------------------------------------------------------------
  // Post‑incident safety report
  // ----------------------------------------------------------------------
  Future<String> getSafetyReport({
    required String threatType,
    required int confidence,
    required String location,
    required List<String> actionsTaken,
  }) async {
    final report = await _llamaThreatService.generateSafetyReport(
      threatType: threatType,
      confidence: confidence,
      location: location,
      actionsTaken: actionsTaken,
    );
    _cachedSafetyReport = report;
    return report;
  }

  // ----------------------------------------------------------------------
  // Step‑by‑step instructions (based on last threat assessment)
  // ----------------------------------------------------------------------
  Future<List<String>> getSafetyInstructions() async {
    if (lastThreatAssessment == null) return ['Stay calm', 'Share your location'];
    if (_cachedSafetyInstructions != null) return _cachedSafetyInstructions!;
    final instructions = await _llamaThreatService.getSafetyInstructions(lastThreatAssessment!);
    _cachedSafetyInstructions = instructions;
    return instructions;
  }

  // ----------------------------------------------------------------------
  // Translation (optional, for future use)
  // ----------------------------------------------------------------------
  Future<String> translate(String text, String targetLanguage) async {
    return await _llamaThreatService.translate(text, targetLanguage);
  }

  // ----------------------------------------------------------------------
  // Firestore logging & escalation (unchanged)
  // ----------------------------------------------------------------------
  Future<void> logThreatToFirestore({
    required String contactId,
    required String location,
  }) async {
    // ... (your existing code – unchanged)
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

  Future<Map<String, dynamic>> makeEscalationDecision({
    required String userThreatThreshold,
    required String location,
  }) async {
    // ... (your existing code – unchanged)
    if (lastThreatAssessment == null || lastIncidentId == null) {
      return {'decision': 'ERROR', 'reason': 'No threat assessment available'};
    }
    try {
      final threatType = (lastThreatAssessment!['threat'] ?? 'unknown').toString();
      final confidence = (lastThreatAssessment!['confidence'] as num?)?.toDouble() ?? 0.0;
      lastDecision = await _decisionEngine.makeEscalationDecision(
        incidentId: lastIncidentId!,
        threatType: threatType,
        confidence: confidence,
        location: location,
        userThreatThreshold: userThreatThreshold,
      );
      final recommendedTier = await _decisionEngine.recommendTier(
        threatType: threatType,
        confidence: confidence,
        similarThreatCount: 0,
      );
      lastDecision!['recommended_tier'] = recommendedTier;
      notifyListeners();
      return lastDecision!;
    } catch (e) {
      error = 'Decision engine error: $e';
      notifyListeners();
      return {'decision': 'ERROR', 'reason': e.toString()};
    }
  }

  Future<List<String>> getContactsToNotify() async {

    if (lastThreatAssessment == null) return [];
    try {
      final threatType = (lastThreatAssessment!['threat'] ?? 'unknown').toString();
      final confidence = (lastThreatAssessment!['confidence'] as num?)?.toDouble() ?? 0.0;
      final escalationService = EscalationTimerService();
      final currentTier = escalationService.currentTier;
      return await _decisionEngine.getContactsToAlert(
        threatType: threatType,
        confidence: confidence,
        currentTier: currentTier,
      );
    } catch (e) {
      print('❌ Error getting contacts to notify: $e');
      return ['tier_1_emergency'];
    }
  }

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

  String generatePostPreview(String userName, String location) {
    if (lastThreatAssessment == null) return '';
    return _llamaThreatService.generateEmergencyPost(userName, location, lastThreatAssessment!);
  }

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

  // Helper to clear cached results (e.g., after new threat assessment)
  void clearCachedResults() {
    _cachedDiversionMessage = null;
    _cachedSafetyReport = null;
    _cachedSafetyInstructions = null;
  }
}