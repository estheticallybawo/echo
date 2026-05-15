enum VoiceEscalationReason {
  none,
  gemmaThreat,
  userRequest,
}

class VoiceConversationDecision {
  final bool shouldEscalate;
  final VoiceEscalationReason reason;
  final String responseText;

  const VoiceConversationDecision({
    required this.shouldEscalate,
    required this.reason,
    required this.responseText,
  });

  factory VoiceConversationDecision.fromAnalysis(Map<String, dynamic> analysis) {
    final transcript = _stringValue(analysis, [
      'transcript',
      'heardContext',
      'analysis',
    ]);
    final summary = _stringValue(analysis, [
      'reply',
      'summary',
      'audio_description',
      'analysis',
      'transcript',
    ]);
    final action = _stringValue(analysis, ['action', 'recommendedAction']);
    final threatLevel = _stringValue(analysis, [
      'threatLevel',
      'threat_level',
      'distress_level',
    ]).toLowerCase();

    if (threatLevel == 'high' || threatLevel == 'critical') {
      return VoiceConversationDecision(
        shouldEscalate: true,
        reason: VoiceEscalationReason.gemmaThreat,
        responseText: _fallbackResponse(
          summary,
          'I detected possible danger and I am opening emergency mode.',
        ),
      );
    }

    final combinedText = '$transcript $summary $action'.toLowerCase();
    if (_containsUserEscalationRequest(combinedText)) {
      return VoiceConversationDecision(
        shouldEscalate: true,
        reason: VoiceEscalationReason.userRequest,
        responseText:
            'I heard you ask for emergency help. I am opening emergency mode now.',
      );
    }

    return VoiceConversationDecision(
      shouldEscalate: false,
      reason: VoiceEscalationReason.none,
      responseText: _fallbackResponse(
        summary,
        transcript.isNotEmpty
            ? transcript
            : 'I listened, but I could not identify a clear request. Please try again.',
      ),
    );
  }

  static String _fallbackResponse(String preferred, String fallback) {
    final trimmed = preferred.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String _stringValue(Map<String, dynamic> analysis, List<String> keys) {
    for (final key in keys) {
      final value = analysis[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static bool _containsUserEscalationRequest(String text) {
    const phrases = [
      'call emergency',
      'call the police',
      'call police',
      'send help',
      'get help',
      'help me',
      'i need help',
      'emergency now',
      'trigger sos',
      'start sos',
      'open emergency',
    ];
    return phrases.any(text.contains);
  }
}
