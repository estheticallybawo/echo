import 'llama_client.dart';

/// Threat analysis service powered by Gemma 4.
/// Analyzes user input and returns structured threat assessment.
class ThreatAnalyzer {
  final LlamaClient _client = LlamaClient();

  static const String _systemPrompt =
      'You are Echo a first responder emergency assistant. '
      'you analyze threats and provide safety recommendations. '
      'Return ONLY a single-line JSON with keys: threat, confidence, threatLevel, action, summary, analyzedSituation. '
      'No markdown, no explanation.';

  /// Perform a warmup check to verify llama.cpp server is responding.
  Future<Map<String, dynamic>> performWarmupCheck({
    required String rawPrompt,
    int maxTokens = 20,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final response = await _client.complete(
        prompt: rawPrompt,
        maxTokens: maxTokens,
        timeout: timeout,
      );
      
      final extracted = _client.extractJson(response);
      if (extracted != null) {
        return extracted;
      }
      // If no JSON, return success status with response preview
      final preview = response.length > 100 ? response.substring(0, 100) : response;
      return {
        'status': 'ready',
        'responsePreview': preview,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Assess threat level from user input.
  Future<Map<String, dynamic>> assessThreat(
    String userInput, {
    int maxTokens = 30,
    Duration timeout = const Duration(seconds: 30),
    String? locationContext,
  }) async {
    try {
      final responseText = await _client.completeWithSystem(
        systemPrompt: _systemPrompt,
        userPrompt: 'Emergency report: $userInput',
        maxTokens: maxTokens,
        locationContext: locationContext,
        timeout: timeout,
      );

      final extracted = _client.extractJson(responseText);
      if (extracted != null) {
        return _client.normalize(extracted, userInput);
      }
      return _client.fallbackResponse('no_json');
    } catch (e) {
      print('❌ assessThreat error: $e');
      return _client.fallbackResponse('error');
    }
  }

  /// High-level threat analysis wrapper.
  Future<Map<String, dynamic>> analyzeThreat(
    String audioContext, {
    String? locationContext,
  }) async {
    return assessThreat(audioContext, locationContext: locationContext);
  }

  /// Mock threat analysis for development/offline testing.
  Future<Map<String, dynamic>> analyzeThreatMock(String input) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (input.toLowerCase().contains('follow') ||
        input.toLowerCase().contains('car')) {
      return {
        'threat': 'Stalking',
        'confidence': 88,
        'threatLevel': 'high',
        'action': 'Call trusted contacts and share location',
        'summary': 'Person reporting being followed.',
        'analyzedSituation': 'being followed by unknown person',
      };
    }

    return {
      'threat': 'unknown',
      'confidence': 42,
      'threatLevel': 'medium',
      'action': 'Monitor the situation and keep trusted contacts informed',
      'summary': 'Unable to confirm a specific threat from the mock input.',
      'analyzedSituation': input,
    };
  }

  void dispose() => _client.dispose();
}
