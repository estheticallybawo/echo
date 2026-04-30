import 'llama_threat_service.dart';
import 'x_oauth_service.dart';

/// Track C: Social Media Posting Service (DEPRECATED)
/// This service is no longer actively used - posting is handled directly by SocialMediaProvider
/// Kept for reference and potential future use
class SocialMediaPostingService {
  final LlamaThreatService gemmaService;
  final XOauthService xService;

  SocialMediaPostingService({
    required this.gemmaService,
    required this.xService,
  });

  /// Gemma determines threat level automatically
  Future<Map<String, dynamic>> postEmergencyAlert({
    required String userName,
    required String audioContext,
    required String location,
  }) async {
    try {
      // Step 1: Analyze threat with Gemma (Gemma determines threat level)
      final threat = await gemmaService.analyzeThreat(audioContext);

      // Step 2: Generate subtle post
      final postText = gemmaService.generateEmergencyPost(userName, location, threat);

      // Step 3: Post to X
      final posted = await xService.postEmergencyAlert(postText);

      return {
        'success': posted,
        'postText': postText,
        'threatAssessment': threat,
      };
    } catch (e) {
      print('Emergency post pipeline failed: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get threat assessment details
  String? getLastThreatSummary() {
    // This can be enhanced to track last assessment
    return 'Threat assessment ready';
  }
}
