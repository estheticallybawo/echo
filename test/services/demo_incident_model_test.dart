import 'package:echo/services/demo/demo_emergency_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DemoIncident serializes feed-ready escalation state', () {
    final now = DateTime(2026, 5, 14, 12);
    final incident = DemoIncident(
      id: 'demo_1',
      threat: 'High danger',
      summary: 'User requested help',
      locationText: 'Ikoyi, Lagos',
      mapsUrl: 'https://maps.google.com/?q=6.4541,3.4246',
      tier: 2,
      isSafe: false,
      startedAt: now,
      updatedAt: now,
      events: [
        DemoIncidentEvent(
          label: 'Tier 1 alert sent',
          detail: 'Inner circle notified',
          timestamp: now,
        ),
      ],
    );

    final restored = DemoIncident.fromMap(incident.toMap());

    expect(restored.id, 'demo_1');
    expect(restored.tier, 2);
    expect(restored.locationText, 'Ikoyi, Lagos');
    expect(restored.mapsUrl, contains('maps.google.com'));
    expect(restored.events.single.label, 'Tier 1 alert sent');
  });
}
