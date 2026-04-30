import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llama_config.dart';

class LlamaThreatService {
  static const String _systemPrompt =
      'You are Echo emergency threat analyzer. Who understands Nigerian threat context and returns only one-line JSON with keys: '
      'threat, confidence, threatLevel, action, summary, analyzedSituation. '
      'No markdown, no explanation.';

  static const Duration _requestTimeout = Duration(seconds: 12);

  static const List<String> _oneChanceSignals = [
    'one chance',
    'korope',
    'danfo',
    'bus',
    'taxi',
    'driver changed route',
    'wrong route',
    'route diversion',
    'they locked the door',
    'can\'t open the door',
    'all passengers are together',
    'everyone is watching me',
    'forced transfer',
    'transfer all the money',
    'enter your pin',
    'collect my phone',
    'blindfold',
    'kidnap',
    'kidnapping',
  ];

  static const List<String> _criticalTransitSignals = [
    'gun',
    'knife',
    'weapon',
    'inject',
    'injection',
    'drugged',
    'take me somewhere else',
    'unknown place',
    'forest',
    'abduct',
  ];

  bool _containsAny(String text, List<String> terms) {
    for (final term in terms) {
      if (text.contains(term)) {
        return true;
      }
    }
    return false;
  }

  List<String> _matchedTerms(String text, List<String> terms) {
    final matches = <String>[];
    for (final term in terms) {
      if (text.contains(term)) {
        matches.add(term);
      }
    }
    return matches;
  }

  Map<String, dynamic> _buildLocalContextSignals(String userInput) {
    final normalized = userInput.toLowerCase();
    final oneChanceMatched = _matchedTerms(normalized, _oneChanceSignals);
    final criticalMatched = _matchedTerms(normalized, _criticalTransitSignals);
    final isOneChancePattern = oneChanceMatched.isNotEmpty;
    final isCriticalTransitPattern = criticalMatched.isNotEmpty;

    return {
      'country_context': 'nigeria',
      'scenario_context': isOneChancePattern
          ? 'possible_one_chance'
          : 'general',
      'signals_detected': [...oneChanceMatched, ...criticalMatched],
      'risk_flags': {
        'possible_coordinated_transit_threat': isOneChancePattern,
        'possible_abduction_risk': isCriticalTransitPattern,
      },
    };
  }

  String _buildJsonUserPayload(String userInput) {
    final localContext = _buildLocalContextSignals(userInput);

    return jsonEncode({
      'task': 'emergency_assessment',
      'input': userInput,
      'local_context': localContext,
      'rules': {
        'json_only': true,
        'max_summary_words': 18,
        'threat_values': [
          'stalking',
          'assault',
          'kidnapping',
          'medical',
          'fire',
          'accident',
          'other',
        ],
        'threat_level_values': ['low', 'medium', 'high', 'critical'],
      },
      'output_schema': {
        'threat': 'string',
        'confidence': 'integer_0_to_100',
        'threatLevel': 'string',
        'action': 'string',
        'summary': 'string',
        'analyzedSituation': 'string',
      },
    });
  }

  int _parseConfidence(dynamic value) {
    if (value is int) {
      return value.clamp(0, 100);
    }
    if (value is double) {
      return value.round().clamp(0, 100);
    }
    if (value is String) {
      final parsed = int.tryParse(value) ?? double.tryParse(value)?.round();
      if (parsed != null) {
        return parsed.clamp(0, 100);
      }
    }
    return 0;
  }

  String _normalizeThreatLevel(String level) {
    const valid = ['low', 'medium', 'high', 'critical'];
    final normalized = level.toLowerCase();
    return valid.contains(normalized) ? normalized : 'medium';
  }

  Map<String, dynamic> _applyContextAwareNormalization(
    Map<String, dynamic> rawAssessment,
    String userInput,
  ) {
    final normalizedInput = userInput.toLowerCase();
    final isOneChancePattern = _containsAny(normalizedInput, _oneChanceSignals);
    final hasCriticalTransitSignal = _containsAny(
      normalizedInput,
      _criticalTransitSignals,
    );

    final threat = (rawAssessment['threat'] ?? 'other')
        .toString()
        .toLowerCase();
    final currentConfidence = _parseConfidence(rawAssessment['confidence']);
    final currentThreatLevel = _normalizeThreatLevel(
      (rawAssessment['threatLevel'] ?? 'medium').toString(),
    );

    final patched = Map<String, dynamic>.from(rawAssessment);
    patched['confidence'] = currentConfidence;
    patched['threatLevel'] = currentThreatLevel;

    if (!isOneChancePattern) {
      patched.putIfAbsent('type', () => patched['threat'] ?? 'unknown');
      return patched;
    }

    if (threat == 'other' || threat == 'unknown' || threat == 'stalking') {
      patched['threat'] = hasCriticalTransitSignal ? 'kidnapping' : 'assault';
    }

    final boostedConfidence = hasCriticalTransitSignal
        ? (currentConfidence < 85 ? 85 : currentConfidence)
        : (currentConfidence < 72 ? 72 : currentConfidence);
    patched['confidence'] = boostedConfidence;

    if (hasCriticalTransitSignal) {
      patched['threatLevel'] = 'critical';
    } else if (currentThreatLevel == 'low' || currentThreatLevel == 'medium') {
      patched['threatLevel'] = 'high';
    }

    patched['action'] =
        'Treat as possible one-chance transit threat; share live location, alert trusted contacts, and seek nearest police checkpoint safely.';
    patched['summary'] =
        'Possible coordinated transit robbery/kidnapping pattern detected.';
    patched['analyzedSituation'] =
        'possible one chance trap in public transport with coordinated threat behavior';
    patched['localContextTag'] = 'nigeria_one_chance';
    patched['type'] = patched['threat'] ?? 'unknown';

    return patched;
  }

  String _buildGemmaTurnPrompt({
    required String systemPrompt,
    required String userPrompt,
  }) {
    final enhancedSystemPrompt = '''$systemPrompt

    EMERGENCY DEFINITIONS FOR NIGERIA:
    - "One chance" / "Korope" / "Danfo" = Fake taxi/bus used for robbery/kidnapping. This is a CRITICAL threat.
    - If user mentions ANY of these words, threatLevel = "critical" and threat = "kidnapping".

    ''';
    return '<bos><|turn>system\n$enhancedSystemPrompt<turn|>\n'
        '<|turn>user\n$userPrompt<turn|>\n'
        '<|turn>model\n';
  }

  Map<String, dynamic>? _extractJson(String rawContent) {
    final cleanContent = rawContent
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    // Remove outer quotes if the entire response is string-encoded
    var processContent = cleanContent;
    if (processContent.startsWith('"') && processContent.endsWith('"')) {
      processContent = processContent.substring(1, processContent.length - 1);
      // Unescape the string
      processContent = processContent
          .replaceAll('\\n', '\n')
          .replaceAll('\\t', '\t')
          .replaceAll('\\"', '"')
          .replaceAll('\\\\', '\\');
    }

    final start = processContent.indexOf('{');
    final end = processContent.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return null;
    }

    final candidate = processContent.substring(start, end + 1);
    try {
      final decoded = jsonDecode(candidate);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      print('❌ JSON decode error in candidate: $e');
      return null;
    }
  }

  /// Main threat assessment method
  /// Calls llama.cpp server for threat assessment
  Future<Map<String, dynamic>> assessThreat(
    String userInput, {
    int maxTokens = 56,
    Duration timeout = _requestTimeout,
  }) async {
    try {
      final compactUserPrompt = _buildJsonUserPayload(userInput);
      final prompt = _buildGemmaTurnPrompt(
        systemPrompt: _systemPrompt,
        userPrompt: compactUserPrompt,
      );

      final requestBody = LlamaConfig.buildCompletionBody(
        prompt,
        maxTokens: maxTokens,
      );
      requestBody['stop'] = ['<turn|>'];

      final response = await http
          .post(
            Uri.parse('${LlamaConfig.activeHost}/completion'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      print('🔍 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final parsedResponse = jsonDecode(response.body);
        final content =
            (parsedResponse['content'] ?? parsedResponse['response'] ?? '')
                .toString();

        print('📊 Raw Llama response: "$content"');
        print('   Length: ${content.length} chars');
        if (content.isEmpty) {
          print('⚠️ Empty model content. Raw response body: ${response.body}');
        }

        try {
          final extracted = _extractJson(content);
          if (extracted != null) {
            final normalized = _applyContextAwareNormalization(
              extracted,
              userInput,
            );
            print('✅ Parsed threat assessment: $normalized');
            return normalized;
          }
          print('⚠️ No JSON found in model response content');
        } catch (e) {
          print('❌ Failed to parse JSON: $e');
        }
      } else {
        print('❌ Non-200 status code: ${response.statusCode}');
        print('   Response: ${response.body}');
      }

      return {'threat': 'unknown', 'type': 'unknown', 'confidence': 0};
    } on Exception catch (e) {
      print(
        '❌ Llama request timed out or failed after ${timeout.inSeconds}s: $e',
      );
      return {'threat': 'unknown', 'type': 'unknown', 'confidence': 0};
    } catch (e) {
      print('❌ Llama threat assessment failed: $e');
      return {'threat': 'unknown', 'type': 'unknown', 'confidence': 0};
    }
  }

  /// Alias for assessThreat - used by SocialMediaPostingService
  Future<Map<String, dynamic>> analyzeThreat(String audioContext) async {
    return assessThreat(audioContext);
  }

  /// Mock version for testing (no actual llama.cpp call)
  Future<Map<String, dynamic>> analyzeThreatMock(String audioContext) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Return realistic mock response
    if (audioContext.toLowerCase().contains('follow') ||
        audioContext.toLowerCase().contains('car')) {
      return {
        'threat': 'Stalking',
        'confidence': 88,
        'threatLevel': 'high',
        'action': 'Call trusted contacts and share location',
        'summary':
            'Person reporting being followed. Potential stalking situation.',
        'analyzedSituation': 'being followed by unknown person',
      };
    }

    return {
      'threat': 'Other',
      'confidence': 65,
      'threatLevel': 'medium',
      'action': 'Monitor situation and stay aware',
      'summary':
          'Potential emergency detected. User describes concerning situation.',
      'analyzedSituation': 'possible emergency scenario',
    };
  }

  /// Generate subtle, brand-aligned post from threat assessment
  String generateEmergencyPost(
    String userName,
    String location,
    Map<String, dynamic> threatAssessment,
  ) {
    final analyzedSituation =
        threatAssessment['analyzedSituation'] ?? 'emergency situation';

    // This matches your template from gemma_threat_assessment_service.dart
    return '''$userName needs urgent help, they are in a $analyzedSituation last live location is at $location if you can help please tag anyone who can, tweet by Echo''';
  }
}
