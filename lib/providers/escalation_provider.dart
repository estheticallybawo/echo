import 'dart:async';
import 'package:flutter/material.dart';
import '../models/incident.dart';
import '../models/contact.dart';

class EscalationProvider with ChangeNotifier {
  Incident? _currentIncident;
  int _elapsedSeconds = 0;
  Timer? _timer;

  Incident? get currentIncident => _currentIncident;
  int get elapsedSeconds => _elapsedSeconds;
  
  int get currentTier {
    if (_elapsedSeconds < 5) return 0;
    if (_seconds < 60) return 1;
    if (_seconds < 90) return 2;
    return 3;
  }

  // Temporary helper for internal consistency
  int get _seconds => _elapsedSeconds;

  void startEscalation(String userId, String threatType, double confidence) {
    _currentIncident = Incident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      threatType: threatType,
      confidence: confidence,
      startTime: DateTime.now(),
    );
    _elapsedSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      if (_elapsedSeconds == 5) {
        _currentIncident = Incident(
          id: _currentIncident!.id,
          userId: _currentIncident!.userId,
          threatType: _currentIncident!.threatType,
          confidence: _currentIncident!.confidence,
          startTime: _currentIncident!.startTime,
          tier1Time: DateTime.now(),
        );
      } else if (_elapsedSeconds == 60) {
        _currentIncident = Incident(
          id: _currentIncident!.id,
          userId: _currentIncident!.userId,
          threatType: _currentIncident!.threatType,
          confidence: _currentIncident!.confidence,
          startTime: _currentIncident!.startTime,
          tier1Time: _currentIncident!.tier1Time,
          tier2Time: DateTime.now(),
        );
      } else if (_elapsedSeconds == 90) {
        _currentIncident = Incident(
          id: _currentIncident!.id,
          userId: _currentIncident!.userId,
          threatType: _currentIncident!.threatType,
          confidence: _currentIncident!.confidence,
          startTime: _currentIncident!.startTime,
          tier1Time: _currentIncident!.tier1Time,
          tier2Time: _currentIncident!.tier2Time,
          tier3Time: DateTime.now(),
        );
      } else if (_elapsedSeconds >= 180) {
        stopEscalation();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void stopEscalation() {
    _timer?.cancel();
    _currentIncident = null;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
