import 'dart:convert';
import 'llama_client.dart';

/// Safety instruction engine powered by Gemma 4.
/// Generates step-by-step safety instructions based on threat assessment.
class InstructionEngine {
  final LlamaClient _client = LlamaClient();

  /// Generate 2-3 calm safety instructions based on threat analysis.
  /// Returns a list of actionable safety steps.
  Future<List<String>> getSafetyInstructions(
    Map<String, dynamic> threat, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final threatType = threat['threat'] ?? 'unknown';
      final confidence = threat['confidence'] ?? 0;
      final prompt =
          'Based on a $threatType threat (confidence $confidence%), '
          'give 2 or 3 short, calm instructions for the user. '
          'Example: "Stay near a well-lit area", "Share live location with your mother". '
          'Return ONLY a JSON array of strings.';
      
      final response = await _client.complete(
        prompt: prompt,
        maxTokens: 60,
        timeout: timeout,
      );
      
      try {
        final List<dynamic> list = jsonDecode(response);
        return list.map((e) => e.toString()).toList();
      } catch (e) {
        return getDefaultSafetyInstructions();
      }
    } catch (e) {
      print('❌ getSafetyInstructions error: $e');
      return getDefaultSafetyInstructions();
    }
  }

  /// Get default fallback safety instructions.
  List<String> getDefaultSafetyInstructions() {
    return [
      'Stay calm and find a safe location',
      'Sharing your live location with a trusted contact',
      'Staying calm helps you think clearly and stay grounded',
    ];
  }

  void dispose() => _client.dispose();
}
