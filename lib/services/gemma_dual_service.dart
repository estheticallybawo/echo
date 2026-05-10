import 'dart:convert';
import 'dart:io';
import 'package:cactus/cactus.dart';
import 'package:http/http.dart' as http;
import 'model_manager.dart';

enum GemmaMode { server, onDevice }

class GemmaDualService {
  GemmaMode _mode = GemmaMode.server;
  CactusLM? _cactus;
  final String _serverUrl;



  GemmaDualService({String? serverUrl}) : _serverUrl = serverUrl ?? 'http://localhost:8080';

  GemmaMode get mode => _mode;

  /// Check if a model is already downloaded (using your ModelManager)
  Future<bool> isModelReady() async {
    final modelPath = await ModelManager.getModelPath();
    return modelPath != null && await File(modelPath).exists();
  }

  /// Switch to on‑device mode using a pre‑downloaded model (path from ModelManager)
  Future<void> switchToOnDevice() async {
  final modelPath = await ModelManager.getModelPath();
  if (modelPath == null) throw Exception('No model downloaded');
  _cactus = CactusLM();
  await _cactus!.initializeModel();
  _mode = GemmaMode.onDevice;
}

 Future<void> initialize() async {
    if (await isModelReady()) {
      await switchToOnDevice();
    } else {
      await switchToServer();
    }
  }

  /// Switch to server mode (fallback)
  Future<void> switchToServer() async {
   _cactus?.unload();
    _cactus = null;
    _mode = GemmaMode.server;
  }

  /// Unified completion method (used by provider)
  Future<String> complete(String prompt, {String? systemPrompt}) async {
    if (_mode == GemmaMode.onDevice && _cactus != null) {
      return _completeOnDevice(prompt, systemPrompt: systemPrompt);
    } else {
      return _completeViaServer(prompt, systemPrompt: systemPrompt);
    }
  }

  Future<String> _completeOnDevice(String userMessage, {String? systemPrompt}) async {
    try {
      final messages = <ChatMessage>[];
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        messages.add(ChatMessage(role: 'system', content: systemPrompt));
      }
      messages.add(ChatMessage(role: 'user', content: userMessage));

      final result = await _cactus!.generateCompletion(
        messages: messages,
        params: CactusCompletionParams(maxTokens: 150, temperature: 0.7),
      );
      return result.success ? result.response : '';
    } catch (e) {
      print('On‑device error: $e');
      return '';
    }
  }

  Future<String> _completeViaServer(String userMessage, {String? systemPrompt}) async {
    try {
      final messages = <Map<String, String>>[];
      if (systemPrompt != null) messages.add({'role': 'system', 'content': systemPrompt});
      messages.add({'role': 'user', 'content': userMessage});

      final response = await http.post(
        Uri.parse('$_serverUrl/v1/chat/completions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'model': 'gemma', 'messages': messages, 'max_tokens': 150, 'temperature': 0.7}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['choices'][0]['message']['content'] ?? '';
      }
      return '';
    } catch (e) {
      print('Server error: $e');
      return '';
    }
  }

  Future<void> dispose() async {
  _cactus?.unload();
  _cactus = null;
}
}