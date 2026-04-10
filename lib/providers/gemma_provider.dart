import 'package:flutter/material.dart';
import '../services/gemma_threat_assessment_service.dart';

/// Track C: Gemma 4 Threat Assessment Provider
/// Week 1: Mocks Google AI Studio
/// Week 2+: Real Gemma 4 API calls + Ollama fallback
class GemmaProvider extends ChangeNotifier {
  final GemmaThreatAssessmentService _gemmaService;
  
  bool isAnalyzing = false;
  Map<String, dynamic>? lastThreatAssessment;
  String? error;
  
  GemmaProvider({required GemmaThreatAssessmentService gemmaService})
      : _gemmaService = gemmaService;
  
  /// Week 1: Mock threat analysis (Days 1-2)
  Future<Map<String, dynamic>> analyzeThreatMock(String audioContext) async {
    isAnalyzing = true;
    error = null;
    notifyListeners();
    
    try {
      final result = await _gemmaService.analyzeThreatMock(audioContext);
      lastThreatAssessment = result;
      isAnalyzing = false;
      notifyListeners();
      return result;
    } catch (e) {
      error = e.toString();
      isAnalyzing = false;
      notifyListeners();
      return {};
    }
  }
  
  /// Week 2+: Real Gemma 4 threat analysis
  Future<Map<String, dynamic>> analyzeThreat(String audioContext) async {
    isAnalyzing = true;
    error = null;
    notifyListeners();
    
    try {
      final result = await _gemmaService.analyzeThreat(audioContext);
      lastThreatAssessment = result;
      isAnalyzing = false;
      notifyListeners();
      return result;
    } catch (e) {
      error = e.toString();
      isAnalyzing = false;
      notifyListeners();
      return {};
    }
  }
  
  /// Generate post from threat assessment
  String generatePostPreview(String location) {
    if (lastThreatAssessment == null) return '';
    return _gemmaService.generateEmergencyPost(location, lastThreatAssessment!);
  }
}
