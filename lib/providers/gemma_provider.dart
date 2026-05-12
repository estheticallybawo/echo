import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:http/http.dart' as http;
import '../services/firestore_incident_service.dart';
import '../services/gemma_decision_engine.dart';
import '../services/escalation_timer_service.dart';
import '../models/chat_message.dart';


class GemmaProvider extends ChangeNotifier {
  final FirestoreIncidentService _firestoreService = FirestoreIncidentService();
  final GemmaDecisionEngine _decisionEngine = GemmaDecisionEngine();

  // State
  bool _isInitialized = false;
  InferenceModel? _model;
  bool isAnalyzing = false;
  Map<String, dynamic>? lastThreatAssessment;
  Map<String, dynamic>? lastDecision;
  String? error;
  String? lastIncidentId;

  // Chat
  List<ChatMessage> messages = [];
  bool isLoading = false;

  // Caches
  String? _cachedDiversionMessage;
  String? _cachedSafetyReport;
  List<String>? _cachedSafetyInstructions;

  // Emergency session tracking
  DateTime? _emergencyStartTime;
  DateTime? _emergencyEndTime;
  int _tiersTriggered = 0;

  // Model configuration - use a lightweight model that works on <4GB RAM
  // Note: This URL points to a .task file (MediaPipe format) which is what flutter_gemma expects
  static const String _offlineModelUrl = 
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task?download=true';
  
  // Hugging Face token – set via --dart-define=HUGGINGFACE_TOKEN=...
  static const String _hfToken = String.fromEnvironment('HUGGINGFACE_TOKEN');
  
  // Gemma API key for cloud fallback (optional)
   static const String _gemmaApiKey = String.fromEnvironment('GEMMA_API_KEY');

  // ----------------------------------------------------------------------
  // Initialization (corrected API)
  // ----------------------------------------------------------------------

  Future<void> initialize({String? modelUrl, String? manualToken}) async {
    if (_isInitialized) return;
    final effectiveToken = manualToken ?? _hfToken;

    if (effectiveToken.isEmpty) {
      error = 'Missing token';
      notifyListeners();
      return;
    }

    try {
      final urlToUse = modelUrl ?? _offlineModelUrl;
      
      // Install model if not already present (downloads once)
      print('📦 Installing model from: $urlToUse');
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      )
      .fromNetwork(
        urlToUse,
        token: effectiveToken,
        foreground: true, // Use foreground service for large downloads
      )
      .withProgress((progress) {
        print('📦 Download progress: %{progress.percentage}%');
      })
      .install();

      // Get the active model instance (no separate loadModel method needed)
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 512,          // lower = faster, less RAM
        preferredBackend: PreferredBackend.gpu,
      );

      _isInitialized = true;
      print('✅ Gemma model ready (offline, on-device)');
      error = null;
      notifyListeners();
    } catch (e) {
      error = 'Model init failed: $e';
      print('❌ $error');
      _isInitialized = false;
      notifyListeners();
    }
  }

  bool get isInitialized => _isInitialized;



  // ----------------------------------------------------------------------
  // Core inference (local + cloud fallback)
  // ----------------------------------------------------------------------




Future<String> _callGemmaAPI(String prompt, {String? systemInstruction}) async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_gemmaApiKey';

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      if (systemInstruction != null && systemInstruction.isNotEmpty)
        'system_instruction': {'parts': [{'text': systemInstruction}]},
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        'temperature': 0.2,
        'topP': 0.95,
        'topK': 40,
        'maxOutputTokens': 500,
      }
    }),
  ).timeout(const Duration(seconds: 10));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    }
    throw Exception('No candidates returned from API.');
  } else {
    throw Exception('Gemini API error: ${response.statusCode} ${response.body}');
  }
}




 Future<String> _complete(String prompt, {String? systemInstruction}) async {
  if (!_isInitialized || _model == null) {
    // Fallback if model is not ready (e.g., during first-time download)
    return await _callGemmaAPI(prompt, systemInstruction: systemInstruction);
  }

  try {
    final fullPrompt = systemInstruction != null
        ? '$systemInstruction\n\nUser: $prompt\nAssistant:'
        : 'User: $prompt\nAssistant:';

    // Create a chat session
    final chat = await _model!.createChat();
    await chat.addQueryChunk(Message.text(text: fullPrompt, isUser: true));

    // Generate the response
    final response = await chat.generateChatResponse();

    // --- Extract the string content from the response ---
    String responseText = '';
    
    // The correct getters are .token, .name/.args, and .content
    if (response is TextResponse) {
      responseText = response.token;  // For standard Gemma models
    } else if (response is FunctionCallResponse) {
      // For models like FunctionGemma
      responseText = 'Function call: ${response.name} with args: ${response.args}'; // Format it as needed
    } else if (response is ThinkingResponse) {
      // For DeepSeek models
      responseText = response.content; // Access the reasoning content
    } else {
      responseText = response.toString();
    }

    // Clean up the chat session
    await chat.close();
    return responseText.trim();

  } catch (e) {
    // If on-device fails, fall back to cloud
    debugPrint('On-device inference failed: $e');
    return await _callGemmaAPI(prompt, systemInstruction: systemInstruction);
  }
}


 


  // ----------------------------------------------------------------------
  // Threat Assessment (JSON output)
  // ----------------------------------------------------------------------

  Future<Map<String, dynamic>> assessThreat(String transcribedText) async {
    isAnalyzing = true;
    error = null;
    notifyListeners();

    try {
      clearCachedResults();
      const systemInstruction =
          'You are a safety companion. Analyze the transcribed text and determine if it indicates a potential safety threat. Respond with a JSON object, containing: "threat" (type of threat or "none"),' 
            '"confidence" (0-100), and "threatLevel" ("low", "medium", "high"). Be concise and only respond with the JSON.';
      final result = await _complete(
        'Analyze this text for threat level: "$transcribedText"',
        systemInstruction: systemInstruction,
      );
      final jsonStr = _extractJson(result);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      // Normalize missing fields
      parsed.putIfAbsent('threat', () => 'unknown');
      parsed.putIfAbsent('confidence', () => 0);
      parsed.putIfAbsent('threatLevel', () => 'medium');
      lastThreatAssessment = parsed;
      isAnalyzing = false;
      notifyListeners();
      return parsed;
    } catch (e) {
      error = e.toString();
      isAnalyzing = false;
      notifyListeners();
      return {
        'threat': 'unknown',
        'confidence': 0,
        'threatLevel': 'medium',
      };
    }
  }


String _extractJson(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start != -1 && end != -1) {
    return raw.substring(start, end + 1);
  }
  return raw;
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
      const systemInstruction =
          'You are Echo, a friendly safety sidekick. Answer helpfully and concisely.';
      final response = await _complete(message, systemInstruction: systemInstruction);
      messages.add(ChatMessage(text: response, isUser: false));
    } catch (e) {
      messages.add(ChatMessage(text: 'Sorry, error: $e', isUser: false));
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
    const systemInstruction =
        'Generate a short authoritative warning (max 15 words) to deter an attacker, saying help is on the way and location is tracked. Speak directly. No markdown.';
    final msg = await _complete('', systemInstruction: systemInstruction);
    _cachedDiversionMessage = msg.isNotEmpty ? msg : 'Alert: Police notified. Location is being tracked.';
    return _cachedDiversionMessage!;
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
    Generate a brief post-incident safety report (max 80 words) for this emergency:
    - Threat: $threatType
    - Confidence: $confidence%
    - Location: $location
    - Actions Taken: ${actionsTaken.join(', ')}
    Give 2 practical recommendations for future safety.
    ''';
    const systemInstruction = 'You are a supportive safety assistant. Keep it warm and actionable.';
    final report = await _complete(prompt, systemInstruction: systemInstruction);
    _cachedSafetyReport = report;
    return report;
  }

  // ----------------------------------------------------------------------
  // Step‑by‑step instructions
  // ----------------------------------------------------------------------

  Future<List<String>> getSafetyInstructions() async {
    if (lastThreatAssessment == null) {
      return ['Stay calm', 'Echo is listening and sharing your location'];
    }
    if (_cachedSafetyInstructions != null) return _cachedSafetyInstructions!;

    final threatType = lastThreatAssessment!['threat'] ?? 'unknown';
    final instructionsRaw = await _complete(
      'Provide 3 step-by-step safety instructions for someone facing a $threatType threat. Number them clearly.',
      systemInstruction: 'You are a safety assistant. Provide clear, actionable instructions.',
    );
    _cachedSafetyInstructions = instructionsRaw
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.replaceFirst(RegExp(r'^\d+\.'), '').trim())
        .toList();
    return _cachedSafetyInstructions!;
  }

  // ----------------------------------------------------------------------
  // Echo Feed post generation (used by EchoFeedService)
  // ----------------------------------------------------------------------

  Future<String> generateEchoFeedPost({
    required String userInput,
    required String location,
    required String policeHandle,
    required String hotline,
  }) async {
    final threat = lastThreatAssessment ?? {};
    final prompt = '''
Generate a short, urgent Echo Feed post (max 120 characters) for this emergency:
User report: $userInput
Location: $location
Threat: ${threat['threat']} (confidence ${threat['confidence']}%)
Include the police handle $policeHandle and emergency hotline $hotline.
Add relevant hashtags like #EchoAlert.
No explanations, just the post.
''';
    const systemInstruction = 'You are Echo, a community safety assistant.';
    final post = await _complete(prompt, systemInstruction: systemInstruction);
    return post.trim().isEmpty
        ? '🚨 EMERGENCY in $location. Contact $policeHandle or call $hotline. #EchoAlert'
        : post;
  }

  // ----------------------------------------------------------------------
  // Emergency session tracking
  // ----------------------------------------------------------------------

  void startEmergencySession() {
    _emergencyStartTime = DateTime.now();
    _emergencyEndTime = null;
    _tiersTriggered = 0;
    _cachedSafetyReport = null;
    clearCachedResults();
    print('🚨 Emergency session started');
  }

  void recordTierActivation(int tierNumber) {
    _tiersTriggered = tierNumber > _tiersTriggered ? tierNumber : _tiersTriggered;
    print('📊 Tier $tierNumber activated');
  }

  Future<String> generatePostIncidentReport({
    required String location,
    List<String>? actionsTaken,
  }) async {
    if (_emergencyStartTime == null || lastThreatAssessment == null) {
      return 'Emergency resolved safely. Stay safe.';
    }
    _emergencyEndTime = DateTime.now();
    final duration = _emergencyEndTime!.difference(_emergencyStartTime!);
    final durationMinutes = duration.inSeconds ~/ 60;
    final durationSeconds = duration.inSeconds % 60;
    final tierProgression = _tiersTriggered == 0
        ? 'No tiers'
        : _tiersTriggered == 1
            ? 'Tier 1 only'
            : _tiersTriggered == 2
                ? 'Tier 1+2'
                : 'Full escalation';
    final threatType = lastThreatAssessment!['threat'] ?? 'unknown';
    final confidence = lastThreatAssessment!['confidence'] ?? 0;
    final actions = actionsTaken?.join(', ') ?? 'Safety confirmed';
    final prompt = '''
Generate a brief post-incident safety report (max 100 words) for this emergency:
- Threat: $threatType ($confidence% confidence)
- Duration: ${durationMinutes}m ${durationSeconds}s
- Escalation: $tierProgression
- Location: $location
- Resolution: $actions
Keep it warm, supportive, and actionable.
''';
    const systemInstruction = 'You are a supportive safety assistant. Write a short incident summary.';
    final report = await _complete(prompt, systemInstruction: systemInstruction);
    _cachedSafetyReport = report;
    notifyListeners();
    return report;
  }

  // ----------------------------------------------------------------------
  // Firestore / Escalation methods (preserved from your original)
  // ----------------------------------------------------------------------

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
      final analysisJson = jsonEncode(lastThreatAssessment);
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
    final situation = lastThreatAssessment!['analyzedSituation'] ?? 'emergency situation';
    return '$userName needs urgent help in a $situation. Last live location: $location.';
  }

  Stream<List<IncidentModel>> getIncidentsStream() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ GemmaProvider: No authenticated user');
        return Stream.value([]);
      }
      return _firestoreService.getIncidentStream(user.uid);
    } catch (e) {
      print('❌ Error getting incidents stream: $e');
      return Stream.value([]);
    }
  }

  void clearCachedResults() {
    _cachedDiversionMessage = null;
    _cachedSafetyReport = null;
    _cachedSafetyInstructions = null;
  }
}