import '../models/background_listening_settings.dart';

/// Background Listening Service
/// Manages when and whether Echo listens in the background
/// User has COMPLETE autonomy over this feature
class BackgroundListeningService {
  BackgroundListeningSettings _settings =
      BackgroundListeningSettings(isEnabled: false); // Default: OFF

  /// Get current listening status
  bool get isListening => _settings.isEnabled;

  /// Get current settings
  BackgroundListeningSettings get settings => _settings;

  /// Enable background listening
  /// User explicitly opts in to this feature
  Future<bool> enableBackgroundListening({
    String? reason,
  }) async {
    try {
      // Simulate permission check and service start
      await Future.delayed(const Duration(milliseconds: 500));

      _settings = _settings.copyWith(
        isEnabled: true,
        lastToggleTime: DateTime.now(),
        userReason: reason,
      );

      print('✓ Background listening ENABLED at ${DateTime.now()}');
      print('  Reason: $reason');
      return true;
    } catch (e) {
      print('✗ Failed to enable background listening: $e');
      return false;
    }
  }

  /// Disable background listening
  /// User explicitly opts out - this is the default state
  Future<bool> disableBackgroundListening({
    String? reason,
  }) async {
    try {
      // Simulate service stop
      await Future.delayed(const Duration(milliseconds: 500));

      _settings = _settings.copyWith(
        isEnabled: false,
        lastToggleTime: DateTime.now(),
        userReason: reason,
      );

      print('✓ Background listening DISABLED at ${DateTime.now()}');
      print('  Reason: $reason');
      return true;
    } catch (e) {
      print('✗ Failed to disable background listening: $e');
      return false;
    }
  }

  /// Toggle listening status with user confirmation
  Future<bool> toggleBackgroundListening({
    String? reason,
  }) async {
    if (_settings.isEnabled) {
      return disableBackgroundListening(reason: reason);
    } else {
      return enableBackgroundListening(reason: reason);
    }
  }

  /// Get status summary for UI
  String getStatusSummary() {
    if (_settings.isEnabled) {
      return 'Echo is listening in background';
    } else {
      return 'Background listening is OFF (tap to enable)';
    }
  }

  /// Load settings from storage (placeholder for persistence)
  Future<void> loadSettings() async {
    // TODO: Implement with SharedPreferences or local storage
    // For now, defaults to disabled (privacy-first)
  }

  /// Save settings to storage (placeholder for persistence)
  Future<void> saveSettings() async {
    // TODO: Implement with SharedPreferences or local storage
    // Store _settings as JSON
  }
}
