import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:math';

/// X OAuth 1.0a Service for posting as @Echo
/// Direct posting with pre-authorized tokens (no OAuth flow needed)
/// Requires: consumerKey, consumerSecret, accessToken, accessTokenSecret from .env
class XOauthService {
  static const String xApiBase = 'https://api.x.com/1.1'; // OAuth 1.0a uses 1.1 endpoint

  final String consumerKey;
  final String consumerSecret;
  final String accessToken;
  final String accessTokenSecret;

  XOauthService({
    required this.consumerKey,
    required this.consumerSecret,
    required this.accessToken,
    required this.accessTokenSecret,
  }) {
    if (consumerKey.isEmpty || consumerSecret.isEmpty || accessToken.isEmpty || accessTokenSecret.isEmpty) {
      print('⚠️ WARNING: X OAuth 1.0a tokens are incomplete or empty - posting will fail');
    } else {
      print('✅ XOauthService initialized with OAuth 1.0a tokens - ready to post as @Echo');
    }
  }

  /// Generate OAuth 1.0a signature
  String _generateSignature(String method, String url, Map<String, String> params, String tokenSecret) {
    // Create parameter string
    var sortedParams = params.keys.toList()..sort();
    var paramString = sortedParams.map((key) => '$key=${Uri.encodeQueryComponent(params[key]!)}').join('&');
    
    // Create signature base string
    var signatureBaseString = '$method&${Uri.encodeComponent(url)}&${Uri.encodeComponent(paramString)}';
    
    // Create signing key
    var signingKey = '${Uri.encodeComponent(consumerSecret)}&${Uri.encodeComponent(tokenSecret)}';
    
    // Generate HMAC-SHA1 signature
    var hmac = Hmac(sha1, utf8.encode(signingKey));
    var signature = base64.encode(hmac.convert(utf8.encode(signatureBaseString)).bytes);
    
    return signature;
  }

  /// Build OAuth 1.0a header
  Map<String, String> _buildOAuthHeader(String method, String url, Map<String, String> additionalParams) {
    var oauthParams = {
      'oauth_consumer_key': consumerKey,
      'oauth_nonce': _generateNonce(),
      'oauth_signature_method': 'HMAC-SHA1',
      'oauth_timestamp': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
      'oauth_version': '1.0',
      'oauth_token': accessToken,
    };
    
    // Merge all parameters for signature
    var allParams = {...oauthParams, ...additionalParams};
    
    // Generate signature
    var signature = _generateSignature(method, url, allParams, accessTokenSecret);
    oauthParams['oauth_signature'] = signature;
    
    // Build header string
    var headerParts = oauthParams.entries.map((entry) => 
      '${entry.key}="${Uri.encodeQueryComponent(entry.value)}"'
    ).toList();
    
    return {'Authorization': 'OAuth ${headerParts.join(', ')}'};
  }

  String _generateNonce() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    var random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Post emergency alert to X using OAuth 1.0a
  /// Posts directly with pre-authorized tokens (no user interaction required)
  Future<bool> postEmergencyAlert(String postText) async {
    try {
      final url = '$xApiBase/statuses/update.json';
      final params = {'status': postText};
      
      final headers = _buildOAuthHeader('POST', url, params);
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
      
      final body = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
      
      print('🐦 Posting to X as @Echo...');
      print('   Endpoint: $url');
      print('   Text length: ${postText.length}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      print('   Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tweetId = data['id_str'];
        print('✅ Posted to X as @Echo: $tweetId');
        print('   URL: https://x.com/i/web/status/$tweetId');
        return true;
      } else {
        print('❌ X post failed: ${response.statusCode}');
        print('   Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ X post error: $e');
      return false;
    }
  }
}