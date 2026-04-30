import 'package:echo/services/x_oauth_service.dart';
import 'package:flutter/material.dart';
import 'gemma_provider.dart';

/// Track C: Social Media Auto-Posting Provider
/// Direct posting to X with pre-authorized OAuth 1.0a tokens
/// Auto-posts at Tier 3 escalation (T+90s) if no contact response
class SocialMediaProvider extends ChangeNotifier {
  final XOauthService _xService;
  final GemmaProvider _gemmaProvider;
  
  // Post template customization
  String postTemplate = '{Username} needs urgent help, she/he is in a {analyzed situation} last live location is at {location} if you can do much please tag anyone who can, tweet by Echo';
  bool includeLocationInPost = true;
  bool includeContactInfoInPost = false;
  
  // Posting state
  bool isPosting = false;
  String? lastPostId;
  String? lastPostText;
  String? lastPostUrl;
  DateTime? lastPostTime;
  
  // Settings - auto-posting always enabled when service is initialized
  bool autoPostEnabled = true;
  
  // Error handling
  String? error;
  
  SocialMediaProvider({
    required XOauthService xService,
    required GemmaProvider gemmaProvider,
  })  : _xService = xService,
        _gemmaProvider = gemmaProvider;
  
  /// Update post template
  void updatePostTemplate(String newTemplate) {
    postTemplate = newTemplate;
    notifyListeners();
  }
  
  /// Update post location inclusion setting
  void setIncludeLocation(bool value) {
    includeLocationInPost = value;
    notifyListeners();
  }
  
  /// Update post contact info inclusion setting
  void setIncludeContactInfo(bool value) {
    includeContactInfoInPost = value;
    notifyListeners();
  }
  
  /// Main Track C Pipeline: Audio → Threat → Post → X
  /// Gemma determines threat level automatically
  Future<bool> postEmergencyAlert({
    required String userName,
    required String audioContext,
    required String location,
    Map<String, dynamic>? precomputedThreatAssessment,
  }) async {
    if (!autoPostEnabled) {
      print('Auto-posting disabled');
      return false;
    }
    
    isPosting = true;
    error = null;
    notifyListeners();
    
    try {
      // Step 1: Use precomputed threat (preferred) or analyze now
      if (precomputedThreatAssessment != null &&
          precomputedThreatAssessment.isNotEmpty) {
        _gemmaProvider.lastThreatAssessment = precomputedThreatAssessment;
      } else {
        await _gemmaProvider.analyzeThreat(audioContext);
      }
      
      // Step 2: Generate post text (Gemma determined threat is included)
      final postText = _gemmaProvider.generatePostPreview(userName, location);
      
      // Step 3: Post to X
      final posted = await _xService.postEmergencyAlert(postText);
      
      if (posted) {
        lastPostId = 'mock-${DateTime.now().millisecondsSinceEpoch}';
        lastPostText = postText;
        lastPostTime = DateTime.now();
        lastPostUrl = 'https://X.com/i/web/status/$lastPostId';
      }
      
      isPosting = false;
      notifyListeners();
      return posted;
    } catch (e) {
      error = e.toString();
      isPosting = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Get post status summary
  String getPostStatusSummary() {
    if (isPosting) return 'Posting...';
    if (lastPostId != null) return 'Posted at ${lastPostTime?.toString().split('.')[0]}';
    return 'Ready to post';
  }
  
  /// Tier 3 Auto-Escalation: Called at T+90s when no confirmation from Tier 1/2
  /// Generates emergency alert post and posts directly to X
  Future<bool> tier3AutoEscalate({
    required String threatLevel,
    required String threatCategory,
    required double lat,
    required double lon,
    String? additionalContext,
  }) async {
    isPosting = true;
    error = null;
    notifyListeners();

    try {
      // Generate post text with threat level, location, and context
      final postText = _generateTier3PostText(
        threatLevel: threatLevel,
        threatCategory: threatCategory,
        latitude: lat,
        longitude: lon,
        additionalContext: additionalContext,
      );

      // Post directly to X with OAuth 1.0a tokens
      final posted = await _xService.postEmergencyAlert(postText);

      if (posted) {
        lastPostText = postText;
        lastPostTime = DateTime.now();
        lastPostUrl = 'https://x.com/i/web/status/emergency-${DateTime.now().millisecondsSinceEpoch}';
        lastPostId = 'tier3-${DateTime.now().millisecondsSinceEpoch}';
        print('✅ Tier 3 emergency alert posted to X');
      } else {
        error = 'Failed to post to X';
      }

      isPosting = false;
      notifyListeners();
      return posted;
    } catch (e) {
      error = 'Tier 3 escalation error: $e';
      isPosting = false;
      notifyListeners();
      print('❌ Tier 3 auto-escalation failed: $e');
      return false;
    }
  }

  /// Generate Tier 3 emergency alert post text
  String _generateTier3PostText({
    required String threatLevel,
    required String threatCategory,
    required double latitude,
    required double longitude,
    String? additionalContext,
  }) {
    final location = 'https://maps.google.com/?q=$latitude,$longitude';
    final timestamp = DateTime.now().toString().split('.')[0];
    
    return '''🚨 EMERGENCY ALERT 🚨

Threat Level: $threatLevel
Category: $threatCategory
Location: $location
Time: $timestamp

${additionalContext ?? 'Emergency detected - immediate assistance needed'}

If you can help or have information, please contact authorities.
powered by Echo''';
  }
}
