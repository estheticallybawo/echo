import 'llama_client.dart';

/// Report and post generation service for incident documentation.
/// Generates safety reports, Echo feed posts, and emergency notifications.
class TriggerReport {
  final LlamaClient _client = LlamaClient();

  /// Generate a post-incident safety report (max 80 words).
  /// Includes threat summary, confidence, location, actions taken, and recommendations.
  Future<String> generateSafetyReport({
    required String threatType,
    required int confidence,
    required String location,
    required List<String> actionsTaken,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final actions = actionsTaken.join(', ');
      final prompt =
          'Generate a short safety report (max 80 words) based on this incident:\n'
          '- Threat: $threatType\n'
          '- Confidence: $confidence%\n'
          '- Location: $location\n'
          '- Actions taken: $actions\n'
          'Give 2 practical recommendations for future safety.';
      
      final response = await _client.complete(
        prompt: prompt,
        maxTokens: 120,
        timeout: timeout,
      );
      return response.trim();
    } catch (e) {
      print('❌ generateSafetyReport error: $e');
      return 'Safety report temporarily unavailable. Please contact emergency services for a complete incident report.';
    }
  }

  /// Generate an Echo Feed post for community alert (max 120 characters).
  /// Includes user info, location, threat level, police handle, and relevant hashtags.
  Future<String> generateEchoFeedPost({
    required String userInput,
    required Map<String, dynamic> threat,
    required String location,
    required String policeHandle,
    required String hotline,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final prompt = '''
      Generate a short, urgent Echo Feed post (max 120 characters) for this emergency:
      User report: $userInput
      Location: $location
      Threat: ${threat['threat']} (confidence ${threat['confidence']}%)
      Include the police handle $policeHandle and emergency hotline $hotline.
      Add relevant hashtags like #EchoAlert.
      No explanations, just the post.
      ''';
      
      final response = await _client.complete(
        prompt: prompt,
        maxTokens: 60,
        timeout: timeout,
      );
      return response.trim();
    } catch (e) {
      print('❌ generateEchoFeedPost error: $e');
      return '';
    }
  }

  /// Generate an emergency post for community notification.
  /// Used when escalating to public alert (Tier 3).
  String generateEmergencyPost(
    String userName,
    String location,
    Map<String, dynamic> threatData,
  ) {
    final situation = threatData['analyzedSituation'] ??
        threatData['summary'] ??
        'emergency situation';
    return '$userName needs urgent help, they are in a $situation. '
        'Last live location is $location. '
        'If you can help, contact emergency services immediately.';
  }

  void dispose() => _client.dispose();
}
