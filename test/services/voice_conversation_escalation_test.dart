import 'package:echo/services/sound/voice_conversation_decision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('escalates when Gemma returns high danger', () {
    final decision = VoiceConversationDecision.fromAnalysis({
      'threatLevel': 'high',
      'summary': 'The speaker sounds unsafe.',
    });

    expect(decision.shouldEscalate, isTrue);
    expect(decision.reason, VoiceEscalationReason.gemmaThreat);
  });

  test('escalates when user asks for emergency help', () {
    final decision = VoiceConversationDecision.fromAnalysis({
      'transcript': 'Please call emergency services now',
      'threatLevel': 'low',
    });

    expect(decision.shouldEscalate, isTrue);
    expect(decision.reason, VoiceEscalationReason.userRequest);
  });

  test('stays conversational for ordinary requests', () {
    final decision = VoiceConversationDecision.fromAnalysis({
      'transcript': 'Who are you and why were you created?',
      'reply': 'I am Echo, a safety assistant built to help people get support.',
      'summary': 'The user is asking about Echo.',
      'threatLevel': 'low',
    });

    expect(decision.shouldEscalate, isFalse);
    expect(decision.responseText, contains('I am Echo'));
  });
}
