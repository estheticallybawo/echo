

import 'package:http/http.dart' as http;
import 'dart:convert';

/// Llama.cpp Server Configuration (for llama-server.exe)
/// 
/// Model: google_gemma-4-E2B-it-Q4_K_M (3.5GB quantized)
/// Server: llama-server.exe on localhost:8080
/// Run: .\llama-server.exe -m <model.gguf> --host 0.0.0.0 --port 8080
class LlamaConfig {
  /// Local llama-server endpoint
  // ignore: constant_identifier_names
  static const String LOCAL_HOST = 'http://localhost:8080';
  
  static const String completionEndpoint = '/completion';
  /// Production Ngrok tunnel URL (set dynamically after   //  tunnel created)
  static String ngrokHost = '';

  /// Use Ngrok endpoint if available (for team testing)
  static String get activeHost =>  LOCAL_HOST;

  /// Max tokens to generate (shorter = faster for emergencies)
  static const int MAX_TOKENS = 30;

  /// Temperature controls randomness (0.0 = deterministic, 1.0 = creative)
  /// For threat assessment: use 0.0 for consistent, focused analysis
  static const double TEMPERATURE = 0.0;

  /// Top K sampling (limit to top K tokens)
  static const int TOP_K = 10;

  /// Repeat penalty (1.0 = no penalty)
  static const double REPEAT_PENALTY = 1.0;

  /// Timeout for llama-server responses
  static const Duration TIMEOUT = Duration(seconds: 300);

  /// Health check timeout (longer for ngrok's variable latency)
  static const Duration HEALTH_CHECK_TIMEOUT_LOCAL = Duration(seconds: 60);


  /// Health check: Is llama-server running?
  static Future<bool> isServerHealthy({String? hostOverride}) async {
    final endpoint = hostOverride ?? activeHost;
    try {
      final timeout = HEALTH_CHECK_TIMEOUT_LOCAL;

      // First try llama.cpp native completion format on /completion.
      final nativeResponse = await http
          .post(
            Uri.parse('$endpoint/completion'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
              buildCompletionBody('Respond with ONLY: OK', maxTokens: 8),
            ),
          )
          .timeout(timeout);

      if (nativeResponse.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Llama server health check failed: $e');
      return false;
    }
  }

 
  /// Build completion request body (llama.cpp format)
  static Map<String, dynamic> buildCompletionBody(String prompt, {int? maxTokens}) {
    return {
      'prompt': prompt,
      'n_predict': maxTokens ?? MAX_TOKENS,
      'temperature': TEMPERATURE,
      'top_k': TOP_K,
      'repeat_penalty': REPEAT_PENALTY,
      'stream': false,
    };
  }

  /// Parse llama.cpp completion response
  static String parseCompletionResponse(String responseBody) {
    final data = jsonDecode(responseBody);
    return data['content']?.trim() ?? '';
  }
}