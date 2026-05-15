import 'package:flutter_test/flutter_test.dart';

import 'package:echo/services/gemma/gemma_system_drill_service.dart';

void main() {
  test('runs health, warmup, and inference before passing the drill', () async {
    final calls = <String>[];
    String? warmupPrompt;
    String? inferencePrompt;
    int? warmupMaxTokens;
    int? inferenceMaxTokens;

    final service = GemmaSystemDrillService(
      healthCheck: () async {
        calls.add('health');
        return true;
      },
      warmupCheck:
          (
            prompt, {
            maxTokens = 120,
            timeout = const Duration(seconds: 30),
          }) async {
            calls.add('warmup');
            warmupPrompt = prompt;
            warmupMaxTokens = maxTokens;
            return {'status': 'ready'};
          },
      inferenceCheck:
          (
            input, {
            maxTokens = 90,
            timeout = const Duration(seconds: 30),
          }) async {
            calls.add('inference');
            inferencePrompt = input;
            inferenceMaxTokens = maxTokens;
            return {
              'threat': 'stalking',
              'confidence': 82,
              'threatLevel': 'high',
              'summary': 'Safe drill report parsed.',
            };
          },
    );

    final snapshots = await service.run().toList();
    final finalSnapshot = snapshots.last;

    expect(calls, ['health', 'warmup', 'inference']);
    expect(warmupPrompt, contains('Echo'));
    expect(warmupPrompt, contains('JSON'));
    expect(inferencePrompt, contains('<|turn>system'));
    expect(inferencePrompt, contains('<|turn>user'));
    expect(inferencePrompt, isNot(contains('<|turn>drill')));
    expect(inferencePrompt, contains('analyzedSituation'));
    expect(warmupMaxTokens, lessThanOrEqualTo(24));
    expect(inferenceMaxTokens, lessThanOrEqualTo(64));
    expect(finalSnapshot.isPassed, isTrue);
    expect(finalSnapshot.drillResult?['confidence'], 82);
    expect(
      finalSnapshot.step(GemmaSystemDrillStep.inference).status,
      GemmaSystemDrillStepStatus.success,
    );
  });

  test('blocks the drill when Gemma server health check fails', () async {
    var warmupCalled = false;
    var inferenceCalled = false;

    final service = GemmaSystemDrillService(
      healthCheck: () async => false,
      warmupCheck:
          (
            prompt, {
            maxTokens = 120,
            timeout = const Duration(seconds: 90),
          }) async {
            warmupCalled = true;
            return {'status': 'ready'};
          },
      inferenceCheck:
          (
            input, {
            maxTokens = 120,
            timeout = const Duration(seconds: 90),
          }) async {
            inferenceCalled = true;
            return {'threat': 'stalking', 'confidence': 82};
          },
    );

    final finalSnapshot = await service.run().last;

    expect(finalSnapshot.isPassed, isFalse);
    expect(finalSnapshot.errorMessage, contains('Start llama.cpp'));
    expect(
      finalSnapshot.step(GemmaSystemDrillStep.health).status,
      GemmaSystemDrillStepStatus.failure,
    );
    expect(warmupCalled, isFalse);
    expect(inferenceCalled, isFalse);
  });

  test(
    'fails the drill when live inference does not return valid threat JSON',
    () async {
      final service = GemmaSystemDrillService(
        healthCheck: () async => true,
        warmupCheck:
            (
              prompt, {
              maxTokens = 120,
              timeout = const Duration(seconds: 90),
            }) async {
              return {'status': 'ready'};
            },
        inferenceCheck:
            (
              input, {
              maxTokens = 120,
              timeout = const Duration(seconds: 90),
            }) async {
              return {'threat': 'unknown', 'confidence': 'not-a-number'};
            },
      );

      final finalSnapshot = await service.run().last;

      expect(finalSnapshot.isPassed, isFalse);
      expect(finalSnapshot.errorMessage, contains('invalid drill payload'));
      expect(
        finalSnapshot.step(GemmaSystemDrillStep.inference).status,
        GemmaSystemDrillStepStatus.failure,
      );
    },
  );

  test(
    'accepts low-risk drill JSON when Gemma understood the schema',
    () async {
      final service = GemmaSystemDrillService(
        healthCheck: () async => true,
        warmupCheck:
            (
              prompt, {
              maxTokens = 120,
              timeout = const Duration(seconds: 90),
            }) async {
              return {'status': 'ready'};
            },
        inferenceCheck:
            (
              input, {
              maxTokens = 120,
              timeout = const Duration(seconds: 90),
            }) async {
              return {
                'threat': 'unknown',
                'confidence': 20,
                'threatLevel': 'low',
                'action': 'Continue monitoring',
                'summary': 'Safe drill parsed without escalation.',
                'analyzedSituation': 'drill report about being followed',
              };
            },
      );

      final finalSnapshot = await service.run().last;

      expect(finalSnapshot.isPassed, isTrue);
    },
  );

  test('rejects LlamaClient fallback payloads as failed inference', () async {
    final service = GemmaSystemDrillService(
      healthCheck: () async => true,
      warmupCheck:
          (
            prompt, {
            maxTokens = 120,
            timeout = const Duration(seconds: 90),
          }) async {
            return {'status': 'ready'};
          },
      inferenceCheck:
          (
            input, {
            maxTokens = 120,
            timeout = const Duration(seconds: 90),
          }) async {
            return {
              'threat': 'unknown',
              'confidence': 0,
              'threatLevel': 'medium',
              'action': 'Check manual emergency options',
              'summary': 'AI temporarily unavailable',
              'analyzedSituation': 'fallback mode',
            };
          },
    );

    final finalSnapshot = await service.run().last;

    expect(finalSnapshot.isPassed, isFalse);
    expect(finalSnapshot.errorMessage, contains('invalid drill payload'));
  });
}
