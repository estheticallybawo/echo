import '../gemma/capabilities/llama_client.dart';

class VoiceConversationService {
  final LlamaClient _client;

  VoiceConversationService({LlamaClient? client})
    : _client = client ?? LlamaClient();

  Future<Map<String, dynamic>> analyzeTranscript(String transcript) async {
    final cleaned = transcript.trim();
    if (cleaned.isEmpty) {
      return {
        'transcript': '',
        'summary': 'I could not hear a clear request. Please try again.',
        'reply': 'I could not hear a clear request. Please try again.',
        'threatLevel': 'unknown',
        'confidence': 0,
        'action': 'Ask the user to try again',
      };
    }

    final response = await _client.completeWithSystem(
      systemPrompt: _systemPrompt,
      userPrompt: 'User voice transcript: "$cleaned"',
      maxTokens: 120,
      temperature: 0.0,
      timeout: const Duration(seconds: 45),
    );

    final parsed = _client.extractJson(response);
    if (parsed != null) {
      parsed['transcript'] =
          (parsed['transcript'] as String?)?.trim().isNotEmpty == true
          ? parsed['transcript']
          : cleaned;
      parsed.putIfAbsent('reply', () => parsed['summary'] ?? 'I understand.');
      parsed.putIfAbsent('summary', () => parsed['reply'] ?? 'I understand.');
      parsed.putIfAbsent('threatLevel', () => 'unknown');
      parsed.putIfAbsent('confidence', () => 0);
      parsed.putIfAbsent('action', () => 'Continue conversation');
      return parsed;
    }

    final fallback = response.trim().isEmpty
        ? 'I heard you, but I could not form a reliable response yet.'
        : response.trim();
    return {
      'transcript': cleaned,
      'summary': fallback,
      'reply': fallback,
      'threatLevel': 'unknown',
      'confidence': 0,
      'action': 'Continue conversation',
    };
  }

  void dispose() => _client.dispose();

  static const String _systemPrompt =
      'You are Echo, a voice-first safety and emergency assistant powered by Gemma. '
      'Understand the user transcript and decide whether to answer normally or escalate. '
      'If the user asks for emergency help, says they are unsafe, asks to trigger SOS, or describes high danger, set threatLevel to high or critical. '
      'For ordinary demo questions, answer as Echo in one or two short sentences. '
      'Return ONLY valid JSON with keys: transcript, summary, reply, threatLevel, confidence, action.';
}
