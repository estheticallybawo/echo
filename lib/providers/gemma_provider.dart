import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gemma/llama_config.dart';
import '../services/gemma/llama_threat_service.dart';
import '../services/firestore_incident_service.dart';
import '../services/gemma/gemma_decision_engine.dart';
import '../services/escalation_timer_service.dart';
import 'dart:convert';
import '../services/gemma_dual_service.dart';
import '../services/model_options.dart';
import '../models/chat_message.dart';

/// Provider that exposes all Gemma 4 capabilities to the UI:
/// - Threat assessment (text/voice)
/// - Spoken diversion message
/// - Post‑incident safety report
/// - Step‑by‑step emergency instructions
/// - Chat functionality
/// - (Optional) translation
class GemmaProvider extends ChangeNotifier {
  final LlamaThreatService _llamaThreatService;
  final FirestoreIncidentService _firestoreService = FirestoreIncidentService();
  final GemmaDecisionEngine _decisionEngine = GemmaDecisionEngine();
  final GemmaDualService _dualService;

  bool _useOnDevice = false; // Toggle between server and on-device mode

  bool isAnalyzing = false;
  Map<String, dynamic>? lastThreatAssessment;
  Map<String, dynamic>? lastDecision;
  String? error;
  String? lastIncidentId;

  // Cached results for new features
  String? _cachedDiversionMessage;
  String? _cachedSafetyReport;
  List<String>? _cachedSafetyInstructions;

  // Model health tracking
  bool isModelHealthy = false;
  bool isCheckingModel = false;
  String modelHealthMessage = 'Unknown';

  // Emergency session tracking for post-incident reporting
  DateTime? _emergencyStartTime;
  DateTime? _emergencyEndTime;
  int _tiersTriggered = 0;

  // Chat functionality
  List<ChatMessage> messages = [];
  bool isLoading = false;

  GemmaProvider({
    required LlamaThreatService llamaThreatService,
    String? serverUrl,
  }) : _llamaThreatService = llamaThreatService,
       _dualService = GemmaDualService(serverUrl: serverUrl) {
    _initializeDualService();
  }

  Future<void> _initializeDualService() async {
    await _dualService.initialize();
    _useOnDevice = _dualService.mode == GemmaMode.onDevice;
    notifyListeners();
  }

  // Toggle between server and on-device mode
  void setUseOnDevice(bool useOnDevice) {
    _useOnDevice = useOnDevice;
    notifyListeners();
  }

  bool get useOnDevice => _useOnDevice;

  bool get isOnDevice => _dualService.mode == GemmaMode.onDevice;

  Future<void> switchToOnDevice() async {
    await _dualService.switchToOnDevice();
    _useOnDevice = true;
    notifyListeners();
  }

  Future<void> switchToServer() async {
    await _dualService.switchToServer();
    _useOnDevice = false;
    notifyListeners();
  }

  // ----------------------------------------------------------------------
  // Location context (injected into threat assessment prompts)
  // ----------------------------------------------------------------------
  void setLocationContext(String location) {
    _llamaThreatService.setLocationContext(location);
  }

  void clearLocationContext() {
    _llamaThreatService.clearLocationContext();
  }

  /// Analyze threat from voice transcription text
  Future<Map<String, dynamic>> assessThreat(String transcribedText) async {
    isAnalyzing = true;
    error = null;
    notifyListeners();

    try {
      clearCachedResults();
      final result = await _dualService.complete(
        'Analyze this text for threat level and provide a JSON response with "threat", "confidence", and "threatLevel": $transcribedText',
        systemPrompt: 'You are a threat analysis AI. Respond only with valid JSON containing threat assessment.'
      );
      
      // Parse the JSON response
      final Map<String, dynamic> parsedResult = jsonDecode(result);
      lastThreatAssessment = parsedResult;
      isAnalyzing = false;
      notifyListeners();
      return parsedResult;
    } catch (e) {
      error = e.toString();
      isAnalyzing = false;
      notifyListeners();
      return {};
    }
  }

  // ----------------------------------------------------------------------
  // Chat functionality
  // ----------------------------------------------------------------------
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    messages.add(ChatMessage(text: message, isUser: true));
    isLoading = true;
    notifyListeners();

    try {
      final response = await _dualService.complete(message);
      messages.add(ChatMessage(text: response, isUser: false));
    } catch (e) {
      messages.add(ChatMessage(text: 'Sorry, I encountered an error: $e', isUser: false));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    messages.clear();
    notifyListeners();
  }

  // ----------------------------------------------------------------------
  // Spoken diversion message
  // ----------------------------------------------------------------------
  Future<String> getDiversionMessage() async {
    if (_cachedDiversionMessage != null) return _cachedDiversionMessage!;
    final message = await _dualService.complete(
      'Generate a short, calming diversion message for someone in a threatening situation.',
      systemPrompt: 'You are a calming AI assistant. Provide brief, reassuring messages.'
    );
    _cachedDiversionMessage = message;
    return message;
  }

  /// Verify the underlying model server is reachable and ready.
  Future<bool> verifyModelHealth() async {
    isCheckingModel = true;
    modelHealthMessage = 'Checking model connectivity...';
    notifyListeners();

    try {
      if (_dualService.mode == GemmaMode.onDevice) {
        // For on-device, check if model is loaded
        await _dualService.complete('test', systemPrompt: 'test');
        isModelHealthy = true;
        modelHealthMessage = 'On-device Gemma is ready';
      } else {
        // For server mode, check server health
        final healthy = await LlamaConfig.isServerHealthy();
        isModelHealthy = healthy;
        modelHealthMessage = healthy ? 'Gemma is online' : 'Gemma is unavailable';
      }
    } catch (e) {
      isModelHealthy = false;
      modelHealthMessage = _dualService.mode == GemmaMode.onDevice 
          ? 'On-device Gemma failed to initialize' 
          : 'Gemma is unavailable';
    }
    
    isCheckingModel = false;
    notifyListeners();
    return isModelHealthy;
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
    if (_cachedSafetyReport != null) return _cachedSafetyReport!;
    
    final prompt = '''
Generate a brief post-incident safety report for this emergency:
- Threat Type: $threatType
- Confidence: ${confidence}%
- Location: $location
- Actions Taken: ${actionsTaken.join(', ')}

Include:
1. What happened (in 1 sentence)
2. Response actions taken
3. One recommendation for future safety
Keep it warm, supportive, and actionable.
''';

    final report = await _dualService.complete(prompt, systemPrompt: 'You are a supportive safety assistant providing post-incident reports.');
    _cachedSafetyReport = report;
    return report;
  }

  // ----------------------------------------------------------------------
  // Step‑by‑step instructions (based on last threat assessment)
  // ----------------------------------------------------------------------
  Future<List<String>> getSafetyInstructions() async {
    if (lastThreatAssessment == null) return ['Stay calm',  'Echo is Listening and Sharing your location'];
    if (_cachedSafetyInstructions != null) return _cachedSafetyInstructions!;
    
    final threatType = lastThreatAssessment!['threat'] ?? 'unknown';
    final instructions = await _dualService.complete(
      'Provide 3-5 step-by-step safety instructions for someone facing a $threatType threat. Number them clearly.',
      systemPrompt: 'You are a safety assistant. Provide clear, actionable safety instructions.'
    );
    
    // Split by numbers or lines
    _cachedSafetyInstructions = instructions.split('\n').where((line) => line.trim().isNotEmpty).toList();
    return _cachedSafetyInstructions!;
  }

  // ----------------------------------------------------------------------
  // Emergency session tracking (for post-incident reporting)
  // ----------------------------------------------------------------------
  void startEmergencySession() {
    _emergencyStartTime = DateTime.now();
    _emergencyEndTime = null;
    _tiersTriggered = 0;
    _cachedSafetyReport = null;
    clearCachedResults();
    print('🚨 Emergency session started at $_emergencyStartTime');
  }

  void recordTierActivation(int tierNumber) {
    _tiersTriggered = tierNumber > _tiersTriggered ? tierNumber : _tiersTriggered;
    print('📊 Tier $tierNumber activated. Max tier reached: $_tiersTriggered');
  }

  /// Generate a comprehensive post-incident report with timing and recommendations.
  /// Call this after the user marks themselves safe.
  Future<String> generatePostIncidentReport({
    required String location,
    List<String>? actionsTaken,
  }) async {
    if (_emergencyStartTime == null) {
      return 'No emergency session recorded.';
    }

    _emergencyEndTime = DateTime.now();
    final duration = _emergencyEndTime!.difference(_emergencyStartTime!);
    final durationMinutes = duration.inSeconds ~/ 60;
    final durationSeconds = duration.inSeconds % 60;

    // Build tier progression text
    final tierProgression = _tiersTriggered == 0
        ? 'No tiers activated'
        : _tiersTriggered == 1
            ? 'Tier 1 only (inner circle SMS)'
            : _tiersTriggered == 2
                ? 'Tier 1 + Tier 2 (extended network)'
                : 'Full escalation (Tier 1-3, including public feed)';

    final threatType = lastThreatAssessment?['threat'] ?? 'unknown';
    final confidence = lastThreatAssessment?['confidence'] ?? 0;
    final actions = actionsTaken?.join(', ') ?? 'Safety confirmed';

    final prompt =
        'Generate a brief post-incident safety report (max 100 words) for this emergency:\n'
        '- Threat Type: $threatType\n'
        '- Confidence: $confidence%\n'
        '- Duration: ${durationMinutes}m ${durationSeconds}s\n'
        '- Escalation: $tierProgression\n'
        '- Location: $location\n'
        '- Resolution: $actions\n'
        'Include:\n'
        '1. What happened (in 1 sentence)\n'
        '2. Response actions taken\n'
        '3. One recommendation for future safety\n'
        'Keep it warm, supportive, and actionable.';

    try {
      final report = await _dualService.complete(prompt, systemPrompt: 'Generate a warm, supportive post-incident safety report.');
      _cachedSafetyReport = report;
      notifyListeners();
      return report;
    } catch (e) {
      print('❌ generatePostIncidentReport error: $e');
      // Fallback report
      return 'Emergency resolved safely. Duration: ${durationMinutes}m ${durationSeconds}s. '
          'Escalation: $tierProgression. '
          'You handled this well. Consider adding more trusted contacts for faster support next time.';
    }
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