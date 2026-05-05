import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echo/services/escalation_timer_service.dart';

void main() {
  late EscalationTimerService service;

  setUp(() {
    service = EscalationTimerService();
    service.stopEscalation();
  });

  tearDown(() {
    service.stopEscalation();
  });

  test('advances through tiers while running', () {
    fakeAsync((async) {
      var tier1Calls = 0;
      var tier2Calls = 0;
      var tier3Calls = 0;
      final tickValues = <int>[];

      service.startEscalation(
        incidentId: 'test-incident',
        onTier1Activate: () => tier1Calls++,
        onTier2Escalate: () => tier2Calls++,
        onTier3Escalate: () => tier3Calls++,
        onTickCallback: tickValues.add,
      );

      expect(service.isRunning, isTrue);
      expect(service.secondsElapsed, 0);
      expect(service.currentTier, 1);

      async.elapse(const Duration(seconds: 5));
      expect(tier1Calls, 1);
      expect(service.secondsElapsed, 5);
      expect(service.currentTier, 1);

      async.elapse(const Duration(seconds: 55));
      expect(tier2Calls, 1);
      expect(service.secondsElapsed, 60);
      expect(service.currentTier, 2);
      expect(tier3Calls, 0);
      expect(tickValues.last, 60);
    });
  });

  test('confirmSafety stops future escalation callbacks', () {
    fakeAsync((async) {
      var tier1Calls = 0;
      var tier2Calls = 0;
      var tier3Calls = 0;

      service.startEscalation(
        incidentId: 'cancel-test',
        onTier1Activate: () => tier1Calls++,
        onTier2Escalate: () => tier2Calls++,
        onTier3Escalate: () => tier3Calls++,
      );

      async.elapse(const Duration(seconds: 61));
      expect(tier1Calls, 1);
      expect(tier2Calls, 1);
      expect(service.isRunning, isTrue);
      expect(service.currentTier, 2);

      service.confirmSafety();

      expect(service.isRunning, isFalse);
      expect(service.secondsElapsed, 0);
      expect(service.getStatusMessage(), 'Idle');

      async.elapse(const Duration(seconds: 60));
      expect(tier3Calls, 0);
      expect(tier2Calls, 1);
      expect(tier1Calls, 1);
      expect(service.isRunning, isFalse);
    });
  });
}