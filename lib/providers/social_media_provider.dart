import 'package:flutter/material.dart';
import '../services/social_media_posting_service.dart';
import '../services/twitter_oauth_service.dart';
import 'gemma_provider.dart';

/// Track C: Social Media Auto-Posting Provider
/// Week 1: Mock Twitter OAuth + post generation
/// Week 2+: Real Twitter OAuth + auto-posting
class SocialMediaProvider extends ChangeNotifier {
  final TwitterOAuthService _twitterService;
  final GemmaProvider _gemmaProvider;
  
  // OAuth state
  bool isAuthenticating = false;
  bool isTwitterConnected = false;
  String? twitterUsername;
  
  // Posting state
  bool isPosting = false;
  String? lastPostId;
  String? lastPostText;
  String? lastPostUrl;
  DateTime? lastPostTime;
  
  // Settings
  bool autoPostEnabled = true;
  
  // Error handling
  String? error;
  
  SocialMediaProvider({
    required SocialMediaPostingService socialMediaService,
    required TwitterOAuthService twitterService,
    required GemmaProvider gemmaProvider,
  })  : _twitterService = twitterService,
        _gemmaProvider = gemmaProvider;
  
  /// Week 1: Mock Twitter OAuth (Days 1-2)
  Future<bool> authenticateTwitterMock() async {
    isAuthenticating = true;
    error = null;
    notifyListeners();
    
    try {
      final result = await _twitterService.authenticateOAuthMock();
      isTwitterConnected = result;
      twitterUsername = 'test_user_Echo'; // Mock username
      isAuthenticating = false;
      notifyListeners();
      return result;
    } catch (e) {
      error = e.toString();
      isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Week 2+: Real Twitter OAuth
  Future<bool> authenticateTwitter() async {
    isAuthenticating = true;
    error = null;
    notifyListeners();
    
    try {
      final result = await _twitterService.authenticateOAuth();
      isTwitterConnected = result;
      if (result) {
        twitterUsername = await _twitterService.getUserInfo();
      }
      isAuthenticating = false;
      notifyListeners();
      return result;
    } catch (e) {
      error = e.toString();
      isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Disconnect Twitter
  Future<void> disconnectTwitter() async {
    isTwitterConnected = false;
    twitterUsername = null;
    autoPostEnabled = false;
    notifyListeners();
  }
  
  /// Main Track C Pipeline: Audio → Threat → Post → Twitter
  /// Gemma determines threat level automatically
  Future<bool> postEmergencyAlert({
    required String userName,
    required String audioContext,
    required String location,
  }) async {
    if (!autoPostEnabled) {
      print('Auto-posting disabled');
      return false;
    }
    
    isPosting = true;
    error = null;
    notifyListeners();
    
    try {
      // Step 1: Get threat assessment from Gemma
      await _gemmaProvider.analyzeThreatMock(audioContext);
      
      // Step 2: Generate post text (Gemma determined threat is included)
      final postText = _gemmaProvider.generatePostPreview(userName, location);
      
      // Step 3: Post to Twitter
      final posted = await _twitterService.postEmergencyAlert(postText);
      
      if (posted) {
        lastPostText = postText;
        lastPostTime = DateTime.now();
        lastPostUrl = 'https://twitter.com/i/web/status/mock-${DateTime.now().millisecondsSinceEpoch}';
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
  
  /// Toggle auto-posting setting
  void toggleAutoPosting() {
    if (isTwitterConnected) {
      autoPostEnabled = !autoPostEnabled;
      notifyListeners();
    } else {
      error = 'Twitter not connected';
      notifyListeners();
    }
  }
  
  /// Get post status summary
  String getPostStatusSummary() {
    if (!isTwitterConnected) return 'Twitter not connected';
    if (isPosting) return 'Posting...';
    if (lastPostId != null) return 'Posted at ${lastPostTime?.toString().split('.')[0]}';
    return 'Ready to post';
  }
}
