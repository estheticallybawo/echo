import 'package:flutter/material.dart';
import '../models/background_listening_settings.dart';
import '../services/background_listening_service.dart';

/// Background Listening Provider
/// Manages and exposes background listening state
class BackgroundListeningProvider extends ChangeNotifier {
  final BackgroundListeningService _listeningService;

  bool _isLoading = false;
  String? _error;

  BackgroundListeningProvider({
    required BackgroundListeningService listeningService,
  }) : _listeningService = listeningService;

  /// Getters
  bool get isListening => _listeningService.isListening;
  bool get isLoading => _isLoading;
  String? get error => _error;
  BackgroundListeningSettings get settings => _listeningService.settings;

  /// Enable background listening with user confirmation
  Future<bool> enableBackgroundListening({
    String? reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _listeningService.enableBackgroundListening(
        reason: reason ?? 'User enabled background listening',
      );

      if (success) {
        await _listeningService.saveSettings();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Disable background listening
  Future<bool> disableBackgroundListening({
    String? reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _listeningService.disableBackgroundListening(
        reason: reason ?? 'User disabled background listening',
      );

      if (success) {
        await _listeningService.saveSettings();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle listening with user confirmation
  Future<bool> toggleBackgroundListening({
    String? reason,
  }) async {
    if (isListening) {
      return disableBackgroundListening(reason: reason);
    } else {
      return enableBackgroundListening(reason: reason);
    }
  }

  /// Get readable status
  String getStatusText() {
    return _listeningService.getStatusSummary();
  }

  /// Clear errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
