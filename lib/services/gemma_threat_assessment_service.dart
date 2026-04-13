import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Threat level enum - determined by Gemma analysis, NOT user selection
enum ThreatLevel {
  low,      // Requires monitoring
  medium,   // Requires coordination
  high,     // Requires immediate response
  critical, // Life-threatening
}

/// Track C: Gemma 4 Threat Assessment Service
/// Week 1: Mock responses (Days 1-2)
/// Week 2+: Real Google AI Studio API calls
/// 
/// IMPORTANT: Threat level is DETERMINED BY GEMMA, not chosen by user
class GemmaThreatAssessmentService {
  final String apiKey;
  final String modelName;
  final bool useMockMode;

  GemmaThreatAssessmentService({
    required this.apiKey,
    this.modelName = 'gemma-3-27b-it',
    this.useMockMode = false,
  });

  static const Map<String, dynamic> _genericFallbackAssessment = {
    'threat': 'Other',
    'confidence': 60,
    'action': 'Call emergency contacts and local responders immediately',
    'summary': 'Potential emergency detected. Escalate and share live location.',
    'threatLevel': 'high',
    'analyzedSituation': 'possible emergency requiring urgent support',
  };

  /// Week 1: MOCK VERSION (Days 1-2, Apr 9-10)
  Future<Map<String, dynamic>> analyzeThreatMock(String audioContext) async {
    // Simulate API latency
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock threat assessment
    return {
      'threat': 'Kidnapping',
      'confidence': 92,
      'action': 'Call police immediately',
      'summary': 'Victim is being forcibly transported. High-threat situation.',
      'threatLevel': 'critical', // Gemma determines this
      'analyzedSituation': 'being forcibly transported in unknown vehicle',
    };
  }

  /// Week 2+: REAL API (Days 3+, Apr 11+)
  /// Gemma analyzes and determines threat level automatically
  Future<Map<String, dynamic>> analyzeThreat(String audioContext) async {
    if (useMockMode) {
      return analyzeThreatMock(audioContext);
    }

    if (apiKey.trim().isEmpty) {
      return analyzeThreatMock(audioContext);
    }

    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      final response = await model.generateContent([
        Content.text('''Analyze this emergency audio context and respond ONLY in valid JSON format (no markdown):

Audio context: "$audioContext"

Respond with EXACTLY this JSON structure:
{
  "threat": "Kidnapping|Assault|Fire|Medical|Robbery|Stalking|Other",
  "confidence": 0-100,
  "action": "specific emergency action",
  "summary": "brief explanation of situation",
  "analyzedSituation": "one-line description suitable for posting (e.g., 'being trapped in vehicle' or 'suffering chest pain')",
  "threatLevel": "critical|high|medium|low"
}

Do not add any markdown, code blocks, or other text.'''),
      ],
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 250,
      ),
    ).timeout(const Duration(seconds: 12));

      final content = response.text;
      if (content == null || content.trim().isEmpty) {
        return _buildGenericFallback(audioContext);
      }

      // Parse JSON from response even when wrapped in markdown/code fences.
      final threatData = _extractThreatPayload(content);
      return threatData;
    } catch (e) {
      print('Gemma analysis failed: $e');
      return _buildGenericFallback(audioContext);
    }
  }

  Map<String, dynamic> _extractThreatPayload(String content) {
    final normalized = content.trim();

    try {
      return _normalizeThreatPayload(jsonDecode(normalized) as Map<String, dynamic>);
    } catch (_) {
      final start = normalized.indexOf('{');
      final end = normalized.lastIndexOf('}');

      if (start >= 0 && end > start) {
        final candidate = normalized.substring(start, end + 1);
        try {
          return _normalizeThreatPayload(jsonDecode(candidate) as Map<String, dynamic>);
        } catch (_) {
          return Map<String, dynamic>.from(_genericFallbackAssessment);
        }
      }

      return Map<String, dynamic>.from(_genericFallbackAssessment);
    }
  }

  Map<String, dynamic> _normalizeThreatPayload(Map<String, dynamic> payload) {
    final fallback = Map<String, dynamic>.from(_genericFallbackAssessment);
    fallback.addAll(payload);
    return fallback;
  }

  Map<String, dynamic> _buildGenericFallback(String audioContext) {
    final fallback = Map<String, dynamic>.from(_genericFallbackAssessment);
    fallback['summary'] =
        'Potential emergency detected from audio context. Escalate and share location.';
    fallback['analyzedSituation'] =
        audioContext.isEmpty ? fallback['analyzedSituation'] : audioContext;
    return fallback;
  }

  /// Generate subtle, brand-aligned post from threat assessment
  /// Template: "{Username} needs urgent help, she/he is in a {analyzed situation} 
  /// last live location is at {location} if you can do much please tag anyone who can,
  /// tweet by Echo"
  String generateEmergencyPost(
    String userName,
    String location,
    Map<String, dynamic> threatAssessment,
  ) {
    final analyzedSituation = threatAssessment['analyzedSituation'] ?? 'emergency situation';
    
    // Build the subtle, non-anxiety-inducing post
    return '''$userName needs urgent help, they are in a $analyzedSituation last live location is at $location if you can help please tag anyone who can, tweet by Echo''';
  }
}
