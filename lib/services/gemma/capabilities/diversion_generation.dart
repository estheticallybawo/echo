import 'llama_client.dart';

/// Diversion message generation service.
/// Generates authoritative warning messages to deter attackers.
class DiversionGeneration {
  final LlamaClient _client = LlamaClient();

  /// Generate a short spoken diversion message (≤15 words).
  /// Message informs attacker that help is coming and location is tracked.
  Future<String> generateDiversionMessage({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      const prompt =
          'Generate a short authoritative warning (max 15 words) to deter an attacker, '
          'saying help is on the way and location is tracked. Speak directly. No markdown.';
      final response = await _client.complete(
        prompt: prompt,
        maxTokens: 30,
        timeout: timeout,
      );
      final trimmed = response.trim();
      if (trimmed.isEmpty) {
        return generateDiversionMessageMock();
      }
      return trimmed;
    } catch (e) {
      print('❌ generateDiversionMessage error: $e');
      return generateDiversionMessageMock();
    }
  }

  /// Mock diversion message for development/offline testing.
  String generateDiversionMessageMock() {
    return 'Alert: Police have been notified. Your location is being tracked.';
  }

  void dispose() => _client.dispose();
}
