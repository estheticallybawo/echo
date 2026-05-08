/// End-to-End (E2E) test helper for manual feature integration testing.
/// 
/// This provides mock scenarios and logging for testing complete feature flows
/// without a dedicated UI test screen.
/// 
/// Usage:
/// ```dart
/// final e2e = E2ETestHelper();
/// await e2e.runScenario(E2EScenario.normalThreatResponse);
/// ```

import '../logging/echo_logger.dart';
import '../../services/gemma/llama_threat_service.dart';

enum E2EScenario {
  normalThreatResponse,       // Moderate threat, standard escalation
  highConfidenceThreat,       // Critical threat, accelerated escalation
  locationEnrichment,         // Threat with location context
  safetyInstructionsTest,     // Verify instruction generation
  completeIncidentLifecycle,  // Full flow from start to resolution
}

class E2ETestHelper {
  final LlamaThreatService _gemmaService = LlamaThreatService();

  /// Run a complete E2E test scenario
  Future<void> runScenario(E2EScenario scenario) async {
    EchoLogger.featureStart('E2E_TEST_SCENARIO', context: {'scenario': scenario.name});

    try {
      switch (scenario) {
        case E2EScenario.normalThreatResponse:
          await _testNormalThreatResponse();
        case E2EScenario.highConfidenceThreat:
          await _testHighConfidenceThreat();
        case E2EScenario.locationEnrichment:
          await _testLocationEnrichment();
        case E2EScenario.safetyInstructionsTest:
          await _testSafetyInstructions();
        case E2EScenario.completeIncidentLifecycle:
          await _testCompleteLifecycle();
      }
      EchoLogger.featureComplete('E2E_TEST_SCENARIO');
    } catch (e) {
      EchoLogger.featureError('E2E_TEST_SCENARIO', e);
      rethrow;
    }
  }

  /// Test 1: Normal Threat Response Flow
  Future<void> _testNormalThreatResponse() async {
    EchoLogger.analysis('TEST', 'Normal Threat Response (Stalking)');
    
    const mockVoiceInput = 'Someone is following me in the parking lot';
    EchoLogger.voiceTranscript(mockVoiceInput);

    final stopwatch = Stopwatch()..start();
    final threat = await _gemmaService.analyzeThreat(mockVoiceInput);
    stopwatch.stop();

    EchoLogger.timing('Threat Analysis', stopwatch.elapsedMilliseconds);
    EchoLogger.threatAssessment(
      threat['threat'] ?? 'unknown',
      (threat['confidence'] as num?)?.toInt() ?? 0,
      threat['threatLevel'] ?? 'unknown',
    );

    // Get safety instructions
    final instructions = await _gemmaService.getSafetyInstructions(threat: threat);
    EchoLogger.safetyInstructions(instructions);

    // Verify threat data
    assert(threat['threat'] != null, 'Threat type missing');
    assert(threat['confidence'] != null, 'Confidence missing');
    assert(threat['threatLevel'] != null, 'Threat level missing');
    assert(instructions.isNotEmpty, 'Instructions empty');

    EchoLogger.featureComplete('Normal Threat Response');
  }

  /// Test 2: High Confidence Threat (Accelerated Escalation)
  Future<void> _testHighConfidenceThreat() async {
    EchoLogger.analysis('TEST', 'High Confidence Threat (Critical)');
    
    const mockVoiceInput = 'There is someone with a knife at my door right now';
    EchoLogger.voiceTranscript(mockVoiceInput);

    final stopwatch = Stopwatch()..start();
    final threat = await _gemmaService.analyzeThreat(mockVoiceInput);
    stopwatch.stop();

    EchoLogger.timing('Threat Analysis', stopwatch.elapsedMilliseconds);
    EchoLogger.threatAssessment(
      threat['threat'] ?? 'unknown',
      (threat['confidence'] as num?)?.toInt() ?? 0,
      threat['threatLevel'] ?? 'unknown',
    );

    // For critical threats, escalation should be faster
    final confidence = (threat['confidence'] as num?)?.toInt() ?? 0;
    if (confidence >= 85) {
      EchoLogger.warning('HIGH CONFIDENCE THREAT - Distress adjustment applied');
      EchoLogger.analysis('Expected', 'Escalation timers should be 33% faster');
      // Get safety instructions for critical threat
      final instructions = await _gemmaService.getSafetyInstructions(threat: threat);
      EchoLogger.safetyInstructions(instructions);
    }

    EchoLogger.featureComplete('High Confidence Threat');
  }

  /// Test 3: Location Enrichment
  Future<void> _testLocationEnrichment() async {
    EchoLogger.analysis('TEST', 'Location Enrichment');
    
    const location = 'Ikoyi, Lagos';
    _gemmaService.setLocationContext(location);
    EchoLogger.location('Context set: $location');

    const mockVoiceInput = 'Help, someone is attacking me';
    EchoLogger.voiceTranscript(mockVoiceInput);

    final threat = await _gemmaService.analyzeThreat(mockVoiceInput);
    EchoLogger.threatAssessment(
      threat['threat'] ?? 'unknown',
      (threat['confidence'] as num?)?.toInt() ?? 0,
      threat['threatLevel'] ?? 'unknown',
    );

    // Get enriched context (police handle, hotline, etc.)
    final enriched = await _gemmaService.getEnrichedContext(
      locationText: location,
    );
    EchoLogger.custom('Enriched Context', [
      'Police Handle: ${enriched['localPolice']}',
      'Fire Service: ${enriched['localFire']}',
      'Emergency Hotline: ${enriched['emergencyHotline']}',
    ]);

    _gemmaService.clearLocationContext();
    EchoLogger.featureComplete('Location Enrichment');
  }

  /// Test 4: Safety Instructions Generation
  Future<void> _testSafetyInstructions() async {
    EchoLogger.analysis('TEST', 'Safety Instructions Generation');
    
    // Test various threat types
    final testThreats = [
      {'threat': 'Stalking', 'confidence': 85, 'threatLevel': 'high'},
      {'threat': 'Assault', 'confidence': 92, 'threatLevel': 'critical'},
      {'threat': 'Harassment', 'confidence': 70, 'threatLevel': 'medium'},
    ];

    for (final threat in testThreats) {
      EchoLogger.analysis('Threat Type', threat['threat']);
      final instructions = await _gemmaService.getSafetyInstructions(threat: threat);
      EchoLogger.safetyInstructions(instructions);
      assert(instructions.isNotEmpty, 'No instructions for ${threat['threat']}');
    }

    EchoLogger.featureComplete('Safety Instructions');
  }

  /// Test 5: Complete Incident Lifecycle
  Future<void> _testCompleteLifecycle() async {
    EchoLogger.analysis('TEST', 'Complete Incident Lifecycle');
    EchoLogger.analysis('PHASE', '1. Voice Input');
    
    const mockVoiceInput = 'I am being followed and I do not feel safe';
    EchoLogger.voiceTranscript(mockVoiceInput);

    EchoLogger.analysis('PHASE', '2. Threat Analysis');
    final stopwatch = Stopwatch()..start();
    final threat = await _gemmaService.analyzeThreat(mockVoiceInput);
    stopwatch.stop();
    EchoLogger.timing('Analysis', stopwatch.elapsedMilliseconds);
    EchoLogger.threatAssessment(
      threat['threat'] ?? 'unknown',
      (threat['confidence'] as num?)?.toInt() ?? 0,
      threat['threatLevel'] ?? 'unknown',
    );

    EchoLogger.analysis('PHASE', '3. Safety Instructions');
    final instructions = await _gemmaService.getSafetyInstructions(threat: threat);
    EchoLogger.safetyInstructions(instructions);

    EchoLogger.analysis('PHASE', '4. Escalation Timeline');
    EchoLogger.escalation('Tier 1 (T+5s)', 'SMS to 3 contacts');
    EchoLogger.escalation('Tier 2 (T+60s)', 'Extended alert to 5-10 contacts');
    EchoLogger.escalation('Tier 3 (T+90s)', 'Echo Feed post');

    EchoLogger.analysis('PHASE', '5. Diversion Message');
    final diversionMsg = await _gemmaService.generateDiversionMessage();
    EchoLogger.voiceResponse(diversionMsg);

    EchoLogger.analysis('PHASE', '6. Safety Report (Mock)');
    final report = await _gemmaService.generateSafetyReport(
      threatType: threat['threat'] ?? 'unknown',
      confidence: (threat['confidence'] as num?)?.toInt() ?? 0,
      location: 'Test Location',
      actionsTaken: [
        'Tier 1 SMS sent',
        'Location shared',
        'Police dispatch queued',
      ],
    );
    EchoLogger.custom('Safety Report', report.split('\n'));

    EchoLogger.incidentClosed(
      'TEST_INCIDENT_001',
      const Duration(minutes: 2, seconds: 15),
      {
        'threatType': threat['threat'],
        'contactsNotified': '3 (Tier 1) + 8 (Tier 2)',
        'resolution': 'User marked safe',
      },
    );

    EchoLogger.featureComplete('Complete Lifecycle');
  }

  /// Generate mock escalation timeline for visualization
  void logMockEscalationTimeline({
    required Duration totalDuration,
    bool userMarkedSafe = true,
  }) {
    EchoLogger.custom('Escalation Timeline', [
      'T+0s: Emergency triggered',
      'T+5s: TIER 1 ACTIVE - SMS to 3 contacts',
      'T+60s: TIER 2 ACTIVE - Extended alert to 5-10 contacts',
      'T+90s: TIER 3 ACTIVE - Echo Feed post',
      'T+${totalDuration.inSeconds}s: ${userMarkedSafe ? 'User marked SAFE' : 'Incident escalated'}',
    ]);
  }
}

/// Run all E2E scenarios
Future<void> runAllE2ETests() async {
  EchoLogger.custom('E2E FULL TEST SUITE', ['Starting all scenarios...']);
  
  final e2e = E2ETestHelper();
  
  for (final scenario in E2EScenario.values) {
    EchoLogger.analysis('RUNNING', scenario.name);
    try {
      await e2e.runScenario(scenario);
      EchoLogger.featureComplete(scenario.name);
    } catch (e) {
      EchoLogger.featureError(scenario.name, e);
    }
    await Future.delayed(const Duration(seconds: 1)); // Pause between tests
  }
  
  EchoLogger.custom('E2E FULL TEST SUITE', ['All scenarios complete']);
}
