import 'capabilities/threat_analyzer.dart';
import 'capabilities/diversion_generation.dart';
import 'capabilities/instruction_engine.dart';
import 'capabilities/trigger_report.dart';
import 'capabilities/geolocation_enrichment_service.dart';

/// Gemma 4 powered threat analysis + advanced safety features (Facade).
/// Orchestrates multiple capability services for comprehensive emergency response.
/// All prompts are kept short and focused for fast inference (<3s).
class LlamaThreatService {
  final ThreatAnalyzer _threatAnalyzer = ThreatAnalyzer();
  final DiversionGeneration _diversionGeneration = DiversionGeneration();
  final InstructionEngine _instructionEngine = InstructionEngine();
  final TriggerReport _triggerReport = TriggerReport();
  final GeolocationEnrichmentService _geolocationService = GeolocationEnrichmentService();

  /// Set the location context to be included in threat analysis prompts.
  void setLocationContext(String location) =>
      GeolocationEnrichmentService.setLocationContext(location);

  /// Clear the location context.
  void clearLocationContext() =>
      GeolocationEnrichmentService.clearLocationContext();

  // ------- Core threat assessment -------
  /// Assess threat level from user input.
  Future<Map<String, dynamic>> assessThreat(
    String userInput, {
    int maxTokens = 30,
    Duration timeout = const Duration(seconds: 30),
  }) async =>
      _threatAnalyzer.assessThreat(
        userInput,
        maxTokens: maxTokens,
        timeout: timeout,
        locationContext: GeolocationEnrichmentService.getLocationContext(),
      );

  /// Lightweight warm-up check that tests actual connection to llama.cpp.
  /// Returns JSON response from server to verify it's ready.
  Future<Map<String, dynamic>> warmupCheck(
    String rawPrompt, {
    int maxTokens = 20,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      // Test connection via threat analyzer's warmup capability
      final response = await _threatAnalyzer.performWarmupCheck(
        rawPrompt: rawPrompt,
        maxTokens: maxTokens,
        timeout: timeout,
      );
      return response;
    } catch (e) {
      print('❌ warmupCheck error: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// High-level threat analysis wrapper.
  Future<Map<String, dynamic>> analyzeThreat(String audioContext) async =>
      _threatAnalyzer.analyzeThreat(
        audioContext,
        locationContext: GeolocationEnrichmentService.getLocationContext(),
      );

  /// Mock threat analysis for development/offline testing.
  Future<Map<String, dynamic>> analyzeThreatMock(String input) async =>
      _threatAnalyzer.analyzeThreatMock(input);

  // ------- Spoken diversion message -------
  /// Generate a spoken diversion message (≤15 words).
  Future<String> generateDiversionMessage() async =>
      _diversionGeneration.generateDiversionMessage();

  /// Mock diversion message for development/offline testing.
  String generateDiversionMessageMock() =>
      _diversionGeneration.generateDiversionMessageMock();

  // ------- Post-incident safety report -------
  /// Generate a post-incident safety report.
  Future<String> generateSafetyReport({
    required String threatType,
    required int confidence,
    required String location,
    required List<String> actionsTaken,
  }) async =>
      _triggerReport.generateSafetyReport(
        threatType: threatType,
        confidence: confidence,
        location: location,
        actionsTaken: actionsTaken,
      );

  // ------- Step-by-step emergency instructions -------
  /// Get safety instructions for user (2-3 bullet points).
  Future<List<String>> getSafetyInstructions(
    Map<String, dynamic> threat = const {},
  ) async {
    if (threat.isEmpty) {
      return _instructionEngine.getDefaultSafetyInstructions();
    }
    return _instructionEngine.getSafetyInstructions(threat);
  }

  // ------- Echo feed post generation -------
  /// Generate an Echo Feed post for community alert.
  Future<String> generateEchoFeedPost({
    required String userInput,
    required Map<String, dynamic> threat,
    required String location,
    required String policeHandle,
    required String hotline,
  }) async =>
      _triggerReport.generateEchoFeedPost(
        userInput: userInput,
        threat: threat,
        location: location,
        policeHandle: policeHandle,
        hotline: hotline,
      );

  /// Generate an emergency post for community notification.
  String generateEmergencyPost(
    String userName,
    String location,
    Map<String, dynamic> threatData,
  ) =>
      _triggerReport.generateEmergencyPost(userName, location, threatData);

  // ------- Translation (placeholder) -------
  /// Translate text to target language using Gemma 4 multilingual capabilities.
  Future<String> translate(String text, String targetLanguage) async {
    // TODO: Implement translation capability module
    print('⚠️  Translation not yet implemented');
    return text;
  }

  // ------- Geolocation enrichment -------
  /// Get enriched context with local emergency contacts based on location.
  Future<Map<String, String>> getEnrichedContext({
    required String locationText,
    double? lat,
    double? lon,
  }) async =>
      _geolocationService.getEnrichedContext(
        locationText: locationText,
        lat: lat,
        lon: lon,
      );

  /// Dispose all services.
  void dispose() {
    _threatAnalyzer.dispose();
    _diversionGeneration.dispose();
    _instructionEngine.dispose();
    _triggerReport.dispose();
  }
}
