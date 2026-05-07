import 'dart:convert';
import 'package:http/http.dart' as http;
import '/llama_config.dart';

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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content']?.trim() ?? '';
      }
      return '';
    } catch (e) {
      print('❌ LlamaClient error: $e');
      return '';
    }
  }

  /// Send a completion request with system prompt (Gemma 4 turn format).
  Future<String> completeWithSystem({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 30,
    double temperature = 0.0,
  }) async {
    final fullPrompt = '<|turn>system\n$systemPrompt<turn|>\n'
        '<|turn>user\n$userPrompt<turn|>\n'
        '<|turn>model\n';
    return await complete(prompt: fullPrompt, maxTokens: maxTokens, temperature: temperature);
  }

  void dispose() => _http.close();
}