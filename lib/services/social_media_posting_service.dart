import 'gemma_threat_assessment_service.dart';
import 'twitter_oauth_service.dart';

/// Track C: Social Media Posting Service
/// Orchestrates the main pipeline: Audio → Threat analysis → Post generation → Twitter
class SocialMediaPostingService {
  final GemmaThreatAssessmentService gemmaService;
  final TwitterOAuthService twitterService;

  SocialMediaPostingService({
    required this.gemmaService,
    required this.twitterService,
  });

  /// Week 1: Mock pipeline 
  Future<Map<String, dynamic>> postEmergencyAlertMock({
    required String userName,
    required String audioContext,
    required String location,
  }) async {
    try {
      // Step 1: Mock threat analysis (Gemma determines threat level)
      final threat = await gemmaService.analyzeThreatMock(audioContext);

      // Step 2: Generate subtle post
      final postText = gemmaService.generateEmergencyPost(userName, location, threat);

      // Step 3: Mock post to Twitter
      final posted = await twitterService.postEmergencyAlertMock(postText);

      return {
        'success': posted,
        'postText': postText,
        'threatAssessment': threat,
      };
    } catch (e) {
      print('Emergency post mock pipeline failed: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }


  /// Gemma determines threat level automatically - NOT user selection
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

      // Step 3: Post to Twitter
      final posted = await twitterService.postEmergencyAlert(postText);

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
