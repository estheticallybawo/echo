import 'dart:convert';
import 'package:http/http.dart' as http;

/// Track C: Twitter OAuth 2.0 Service
/// Week 1: Mock OAuth (Days 1-2)
/// Week 2+: Real Twitter API v2 integration
class TwitterOAuthService {
  static const String TWITTER_API_BASE = 'https://api.twitter.com/2';
  static const String TWITTER_OAUTH_URL = 'https://twitter.com/2/oauth2/token';

  final String apiKey; // Client ID
  final String apiSecret; // Client Secret
  final String redirectUri;

  String? _accessToken;

  TwitterOAuthService({
    required this.apiKey,
    required this.apiSecret,
    required this.redirectUri,
  });

  /// Week 1: Mock OAuth (Days 1-2, Apr 9-10)
  Future<bool> authenticateOAuthMock() async {
    // Simulate OAuth flow
    await Future.delayed(const Duration(seconds: 1));
    _accessToken = 'mock-access-token-${DateTime.now().millisecondsSinceEpoch}';
    return true;
  }

  /// Week 2+: Real Twitter OAuth 2.0
  Future<bool> authenticateOAuth() async {
    try {
      // Step 1: Get authorization code (Flutter UI plugin handles this)
      // For MVP: You'll use flutter_appauth to handle this flow
      
      // Step 2: Exchange code for access token
      final response = await http.post(
        Uri.parse(TWITTER_OAUTH_URL),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': apiKey,
          'client_secret': apiSecret,
          'grant_type': 'authorization_code',
          'code': 'AUTH_CODE_HERE', // From OAuth flow
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        // _refreshToken stored in secure storage for production
        return true;
      }
      return false;
    } catch (e) {
      print('OAuth failed: $e');
      return false;
    }
  }

  /// Week 1: Mock post (Days 1-2)
  Future<bool> postEmergencyAlertMock(String postText) async {
    // Simulate post API call
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// Week 2+: Real post to Twitter
  Future<bool> postEmergencyAlert(String postText) async {
    if (_accessToken == null) {
      print('Not authenticated with Twitter');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$TWITTER_API_BASE/tweets'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'text': postText}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('Posted tweet: ${data['data']['id']}');
        return true;
      } else {
        print('Tweet post failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Post failed: $e');
      return false;
    }
  }

  /// Get authenticated user info
  Future<String?> getUserInfo() async {
    if (_accessToken == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$TWITTER_API_BASE/users/me'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['username'];
      }
      return null;
    } catch (e) {
      print('Get user info failed: $e');
      return null;
    }
  }

  /// Check if authenticated
  bool get isAuthenticated => _accessToken != null;

  /// Get current access token (for debugging)
  String? get accessToken => _accessToken;
}
