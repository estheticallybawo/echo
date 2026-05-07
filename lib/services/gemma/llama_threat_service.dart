import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'llama_config.dart';

/// Gemma 4 powered threat analysis + advanced safety features.
/// All prompts are kept short and focused for fast inference (<3s).
class LlamaThreatService {
  // Base system prompt for threat analysis (used only when not overridden)
  static const String _defaultSystemPrompt =
      'You are Echo emergency threat analyzer. '
      'Return ONLY a single-line JSON with keys: threat, confidence, threatLevel, action, summary, analyzedSituation. '
      'No markdown, no explanation.';

  // Optional location context (set before calling assessThreat)
  static String? _locationContext;

  static void setLocationContext(String location) =>
      _locationContext = location;
  static void clearLocationContext() => _locationContext = null;

  // ----------------------------------------------------------------------
  // Core threat assessment
  // ----------------------------------------------------------------------
  Future<Map<String, dynamic>> assessThreat(
    String userInput, {
    int maxTokens = 30,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final prompt = _buildGemmaPrompt(
        systemPrompt: _defaultSystemPrompt,
        userPrompt: 'Emergency report: $userInput',
      );

      final responseText = await _sendCompletion(prompt, maxTokens, timeout);
      final extracted = _extractJson(responseText);
      if (extracted != null) {
        return _normalize(extracted, userInput);
      }
      return _fallbackResponse('unknown');
    } catch (e) {
      print('❌ assessThreat error: $e');
      return _fallbackResponse('unknown');
    }
  }

  // ----------------------------------------------------------------------
  // Spoken diversion message (≤15 words)
  // ----------------------------------------------------------------------
  Future<String> generateDiversionMessage() async {
    const prompt =
        'Generate a short authoritative warning (max 15 words) to deter an attacker, '
        'saying help is on the way and location is tracked. Speak directly. No markdown.';
    final response = await _sendCompletion(
      prompt,
      30,
      const Duration(seconds: 10),
    );
    return response.trim();
  }

  // ----------------------------------------------------------------------
  // Post‑incident safety report
  // ----------------------------------------------------------------------
  Future<String> generateSafetyReport({
    required String threatType,
    required int confidence,
    required String location,
    required List<String>
    actionsTaken, // e.g. ['Tier 1 notified', 'Echo Feed posted']
  }) async {
    final actions = actionsTaken.join(', ');
    final prompt =
        'Generate a short safety report (max 80 words) based on this incident:\n'
        '- Threat: $threatType\n'
        '- Confidence: $confidence%\n'
        '- Location: $location\n'
        '- Actions taken: $actions\n'
        'Give 2 practical recommendations for future safety.';
    final response = await _sendCompletion(
      prompt,
      120,
      const Duration(seconds: 15),
    );
    return response.trim();
  }

  // ----------------------------------------------------------------------
  // Step‑by‑step emergency instructions (2‑3 bullet points)
  // ----------------------------------------------------------------------
  Future<List<String>> getSafetyInstructions(
    Map<String, dynamic> threat,
  ) async {
    final threatType = threat['threat'] ?? 'unknown';
    final confidence = threat['confidence'] ?? 0;
    final prompt =
        'Based on a $threatType threat (confidence $confidence%), '
        'give 2 or 3 short, calm instructions for the user. '
        'Example: "Stay near a well‑lit area", "Share live location with your mother". '
        'Return ONLY a JSON array of strings.';
    final response = await _sendCompletion(
      prompt,
      60,
      const Duration(seconds: 10),
    );
    try {
      final List<dynamic> list = jsonDecode(response);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return ['Stay calm', 'Share your location with a trusted contact'];
    }
  }

  // ----------------------------------------------------------------------
  // Translation placeholder (Gemma 4 multilingual)
  // ----------------------------------------------------------------------
  Future<String> translate(String text, String targetLanguage) async {
    // For hackathon, you can either implement or just return original text
    // with a note that this feature is ready.
    const prompt = 'Translate the following to $targetLanguage:\n\n$text';
    final response = await _sendCompletion(
      prompt,
      200,
      const Duration(seconds: 10),
    );
    return response.trim();
  }

  // ----------------------------------------------------------------------
  // Mock versions for development / offline testing
  // ----------------------------------------------------------------------
  Future<Map<String, dynamic>> analyzeThreatMock(String input) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (input.toLowerCase().contains('follow') ||
        input.toLowerCase().contains('car')) {
      return {
        'threat': 'Stalking',
        'confidence': 88,
        'threatLevel': 'high',
        'action': 'Call trusted contacts and share location',
        'summary': 'Person reporting being followed.',
        'analyzedSituation': 'being followed by unknown person',
      };
    }

    return {
      'threat': 'unknown',
      'confidence': 42,
      'threatLevel': 'medium',
      'action': 'Monitor the situation and keep trusted contacts informed',
      'summary': 'Unable to confirm a specific threat from the mock input.',
      'analyzedSituation': input,
    };
  }

  Future<String> generateDiversionMessageMock() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'Alert: Police have been notified. Your location is being tracked.';
  }

  // ----------------------------------------------------------------------
  // Echo feed post generation
  // ----------------------------------------------------------------------

          Future<String> generateEchoFeedPost({
            required String userInput,
            required Map<String, dynamic> threat,
            required String location,
            required String policeHandle,
            required String hotline,
          }) async {
            final prompt =
                '''
        Generate a short, urgent Echo Feed post (max 120 characters) for this emergency:
        Location: $location
        Threat: ${threat['threat']} (confidence ${threat['confidence']}%)
        Include the police handle $policeHandle and emergency hotline $hotline.
        Add relevant hashtags like #EchoAlert.
        No explanations, just the post.
        ''';
            final response = await _sendCompletion(
              prompt,
              60,
              const Duration(seconds: 10),
            );
            return response.trim();
          }

  // ----------------------------------------------------------------------
  // Private helpers
  // ----------------------------------------------------------------------
  Future<String> _sendCompletion(
    String prompt,
    int maxTokens,
    Duration timeout,
  ) async {
    final requestBody = LlamaConfig.buildCompletionBody(
      prompt,
      maxTokens: maxTokens,
    );
    final response = await http
        .post(
          Uri.parse('${LlamaConfig.activeHost}/completion'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['content'] ?? '').toString().trim();
    }
    return '';
  }

  String _buildGemmaPrompt({
    required String systemPrompt,
    required String userPrompt,
  }) {
    final locationPart =
        (_locationContext != null && _locationContext!.isNotEmpty)
        ? '\n\nLOCATION CONTEXT: $_locationContext'
        : '';
    return '<|turn>system\n$systemPrompt$locationPart<turn|>\n'
        '<|turn>user\n$userPrompt<turn|>\n'
        '<|turn>model\n';
  }

  Map<String, dynamic>? _extractJson(String raw) {
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

  Map<String, dynamic> _normalize(Map<String, dynamic> raw, String input) {
    // Ensure required fields exist, trust Gemma's output
    raw.putIfAbsent('threat', () => 'unknown');
    raw.putIfAbsent('confidence', () => 0);
    raw.putIfAbsent('threatLevel', () => 'medium');
    raw.putIfAbsent('action', () => 'Monitor situation');
    raw.putIfAbsent('summary', () => 'Potential emergency reported');
    raw.putIfAbsent('analyzedSituation', () => input);
    return raw;
  }

  Map<String, dynamic> _fallbackResponse(String reason) {
    return {
      'threat': 'unknown',
      'confidence': 0,
      'threatLevel': 'medium',
      'action': 'Check manual emergency options',
      'summary': 'AI temporarily unavailable',
      'analyzedSituation': 'fallback mode',
    };
  }
}
