import 'dart:async';
import 'package:flutter/material.dart';
import '../models/incident.dart';
import '../models/contact.dart';

class EscalationProvider with ChangeNotifier {
  Incident? _currentIncident;
  int _elapsedSeconds = 0;
  Timer? _timer;


  VoidCallback? onTier1Activate;
  VoidCallback? onTier2Escalate;
  VoidCallback? onTier3Escalate;

  Incident? get currentIncident => _currentIncident;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isActive => _currentIncident != null;
  
  int get currentTier {
    if (_elapsedSeconds < 5) return 0;
    if (_elapsedSeconds < 60) return 1;
    if (_elapsedSeconds < 90) return 2;
    return 3;
  }

  void startEscalation({
    required String userId,
    required String threatType,
    required double confidence,
    VoidCallback? onTier1,
    VoidCallback? onTier2,
    VoidCallback? onTier3,
  }) {
    onTier1Activate = onTier1;
    onTier2Escalate = onTier2;
    onTier3Escalate = onTier3;

    _currentIncident = Incident(
      id: 'inc_${DateTime.now().millisecondsSinceEpoch}',
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
        _activateTier1();
      } else if (_elapsedSeconds == 60) {
        _activateTier2();
      } else if (_elapsedSeconds == 90) {
        _activateTier3();
      } else if (_elapsedSeconds >= 180) {
        _resolveEmergency();
      }
      
      notifyListeners();
    });
    notifyListeners();
  }

  void _activateTier1() {
    _currentIncident = Incident(
      id: _currentIncident!.id,
      userId: _currentIncident!.userId,
      threatType: _currentIncident!.threatType,
      confidence: _currentIncident!.confidence,
      startTime: _currentIncident!.startTime,
      tier1Time: DateTime.now(),
    );
    onTier1Activate?.call();
  }

  void _activateTier2() {
    _currentIncident = Incident(
      id: _currentIncident!.id,
      userId: _currentIncident!.userId,
      threatType: _currentIncident!.threatType,
      confidence: _currentIncident!.confidence,
      startTime: _currentIncident!.startTime,
      tier1Time: _currentIncident!.tier1Time,
      tier2Time: DateTime.now(),
    );
    onTier2Escalate?.call();
  }

  void _activateTier3() {
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
    onTier3Escalate?.call();
  }

  void _resolveEmergency() {
    if (_currentIncident != null) {
      _currentIncident = Incident(
        id: _currentIncident!.id,
        userId: _currentIncident!.userId,
        threatType: _currentIncident!.threatType,
        confidence: _currentIncident!.confidence,
        startTime: _currentIncident!.startTime,
        tier1Time: _currentIncident!.tier1Time,
        tier2Time: _currentIncident!.tier2Time,
        tier3Time: _currentIncident!.tier3Time,
        isResolved: true,
      );
    }
    _timer?.cancel();
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
