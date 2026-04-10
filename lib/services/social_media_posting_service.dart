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

  /// Week 1: Mock pipeline (Days 1-2, Apr 9-10)
  Future<bool> postEmergencyAlertMock({
    required String audioContext,
    required String location,
  }) async {
    try {
      // Step 1: Mock threat analysis
      final threat = await gemmaService.analyzeThreatMock(audioContext);

      // Step 2: Generate post
      final postText = gemmaService.generateEmergencyPost(location, threat);

      // Step 3: Mock post to Twitter
      final posted = await twitterService.postEmergencyAlertMock(postText);

      return posted;
    } catch (e) {
      print('Emergency post mock pipeline failed: $e');
      return false;
    }
  }

  /// Week 2+: Real pipeline
  Future<bool> postEmergencyAlert({
    required String audioContext,
    required String location,
  }) async {
    try {
      // Step 1: Analyze threat with Gemma
      final threat = await gemmaService.analyzeThreat(audioContext);

      // Step 2: Generate post
      final postText = gemmaService.generateEmergencyPost(location, threat);

      // Step 3: Post to Twitter
      final posted = await twitterService.postEmergencyAlert(postText);

      return posted;
    } catch (e) {
      print('Emergency post pipeline failed: $e');
      return false;
    }
  }

  /// Get threat assessment details
  String? getLastThreatSummary() {
    // This can be enhanced to track last assessment
    return 'Threat assessment ready';
  }
}
