import 'package:http/http.dart' as http;
import 'dart:convert';

class OllamaConfig {
  /// Local Ollama endpoint (run: ollama serve on your machine)
  static const String LOCAL_HOST = 'http://localhost:11434';

  /// Production Ngrok tunnel URL (set dynamically after ngrok tunnel created)
  /// Example: https://abc123.ngrok.io
  static String ngrokHost = '';

  /// Use Ngrok endpoint if available (for team testing)
  static String get activeHost => ngrokHost.isNotEmpty ? ngrokHost : LOCAL_HOST;

  /// Model name - verify this matches your installed model
  static const String MODEL = 'gemma4:e4b'; // Updated to your actual model

  /// Temperature controls randomness (0.0 = deterministic, 1.0 = creative)
  /// For threat assessment: use LOW (0.3) = consistent threat analysis
  static const double TEMPERATURE = 0.3;

  /// Max tokens to generate (longer responses = more tokens)
  static const int MAX_TOKENS = 500;

  /// Timeout for Ollama responses
  /// Note: gemma4:e4b is a large model, takes 5-20 seconds per response
  /// For production: consider smaller model (gemma2:7b = 2-3s)
  static const Duration TIMEOUT = Duration(seconds: 45);

  /// Health check: Is Ollama running and responding?
  static Future<bool> isOllamaHealthy({String? hostOverride}) async {
    final endpoint = hostOverride ?? activeHost;
    try {
      final response = await http
          .get(Uri.parse('$endpoint/api/tags'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Ollama health check failed: $e');
      return false;
    }
  }

  /// Verify the specific model is available
  static Future<bool> isModelAvailable({String? hostOverride}) async {
    final endpoint = hostOverride ?? activeHost;
    try {
      final response = await http
          .get(Uri.parse('$endpoint/api/tags'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List?;
        if (models != null) {
          return models.any((m) => m['name'].toString().contains(MODEL));
        }
      }
      return false;
    } catch (e) {
      print('❌ Model availability check failed: $e');
      return false;
    }
  }

  /// Set Ngrok tunnel URL for team access
  /// Call this ONCE after starting ngrok tunnel
  static void setNgrokUrl(String url) {
    ngrokHost = url;
    print('✅ Ngrok configured: $url');
    print('   Team members can now use: $activeHost');
  }

  /// Get endpoint URL for a specific purpose
  static String getEndpoint(String path) => '$activeHost$path';
}
