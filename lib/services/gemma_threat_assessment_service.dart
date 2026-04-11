import 'dart:convert';
import 'package:http/http.dart' as http;

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
  static const String GOOGLE_AI_STUDIO_API =
      'https://generativelanguage.googleapis.com/v1beta/models/gemma-2-27b-it:generateContent';

  final String apiKey;

  GemmaThreatAssessmentService({required this.apiKey});

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
    try {
      final response = await http.post(
        Uri.parse('$GOOGLE_AI_STUDIO_API?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''Analyze this emergency audio context and respond ONLY in valid JSON format (no markdown):

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

Do not add any markdown, code blocks, or other text.'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3, // Low temp for deterministic output
            'maxOutputTokens': 250,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];

        // Parse JSON from response
        final threatData = jsonDecode(content);
        return threatData;
      } else {
        print('Gemma API error: ${response.statusCode}');
        print('Response: ${response.body}');
        return analyzeThreatMock(audioContext); // Fallback to mock
      }
    } catch (e) {
      print('Gemma analysis failed: $e');
      return analyzeThreatMock(audioContext); // Fallback to mock
    }
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
