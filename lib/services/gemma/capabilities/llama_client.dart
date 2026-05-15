import 'dart:convert';
import 'package:http/http.dart' as http;
import '../llama_config.dart';

/// Shared HTTP client for all Gemma 4 interactions.
/// Each service uses this to keep code DRY and consistent.
class LlamaClient {
  final http.Client _http = http.Client();

  /// Send a completion request to llama.cpp server.
  /// Returns the raw content string.
  Future<String> complete({
    required String prompt,
    int maxTokens = 30,
    double temperature = 0.0,
    int topK = 10,
    double repeatPenalty = 1.0,
    Duration timeout = const Duration(seconds: 400),
  }) async {
    try {
      final response = await _http.post(
        Uri.parse('${LlamaConfig.activeHost}/completion'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'n_predict': maxTokens,
          'temperature': temperature,
          'top_k': topK,
          'repeat_penalty': repeatPenalty,
          'stream': false,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['content'] ?? '').toString().trim();
      }
      return '';
    } catch (e) {
      print('❌ LlamaClient.complete error: $e');
      return '';
    }
  }

  /// Send a completion request with system prompt (Gemma 4 turn format).
  Future<String> completeWithSystem({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 30,
    double temperature = 0.0,
    String? locationContext,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final fullPrompt = buildGemmaPrompt(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      locationContext: locationContext,
    );
    return await complete(prompt: fullPrompt, maxTokens: maxTokens, temperature: temperature, timeout: timeout);
  }

  /// Build a properly formatted Gemma 4 prompt with optional location context.
  String buildGemmaPrompt({
    required String systemPrompt,
    required String userPrompt,
    String? locationContext,
  }) {
    final locationPart =
        (locationContext != null && locationContext.isNotEmpty)
        ? '\n\nLOCATION CONTEXT: $locationContext'
        : '';
    return '<|turn>system\n$systemPrompt$locationPart<turn|>\n'
        '<|turn>user\n$userPrompt<turn|>\n'
        '<|turn>model\n';
  }

  /// Extract JSON from a potentially messy response string.
  Map<String, dynamic>? extractJson(String raw) {
    var cleaned = raw.replaceAll('```json', '').replaceAll('```', '').trim();
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned
          .substring(1, cleaned.length - 1)
          .replaceAll('\\"', '"')
          .replaceAll('\\n', '\n');
    }
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1) return null;
    try {
      return jsonDecode(cleaned.substring(start, end + 1));
    } catch (e) {
      return null;
    }
  }

  /// Normalize Gemma output to ensure all required fields exist.
  Map<String, dynamic> normalize(Map<String, dynamic> raw, String fallbackInput) {
    raw.putIfAbsent('threat', () => 'unknown');
    raw.putIfAbsent('confidence', () => 0);
    raw.putIfAbsent('threatLevel', () => 'medium');
    raw.putIfAbsent('action', () => 'Monitor situation');
    raw.putIfAbsent('summary', () => 'Potential emergency reported');
    raw.putIfAbsent('analyzedSituation', () => fallbackInput);
    return raw;
  }

  /// Get a fallback response when AI is unavailable.
  Map<String, dynamic> fallbackResponse(String reason) {
    return {
      'threat': 'unknown',
      'confidence': 0,
      'threatLevel': 'medium',
      'action': 'Check manual emergency options',
      'summary': 'AI temporarily unavailable',
      'analyzedSituation': 'fallback mode',
    };
  }

  void dispose() => _http.close();
}