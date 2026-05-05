// ignore_for_file: constant_identifier_names

import 'package:flutter/services.dart';

/// Action types that trigger confirmation sounds and haptics
enum ConfirmationActionType {
  police_called,
  tweet_posted,
  en_route,
  public_post_live,
  contact_notified,
  emergency_stopped,
}

/// Confirmation Sound System Service
/// Manages audio feedback and haptic feedback for critical Echo actions
class ConfirmationSoundSystem {
  static const platform = MethodChannel('com.Echo/audio');
  static const hapticChannel = MethodChannel('com.Echo/haptics');

  /// Play confirmation sound and haptic for an action
  static Future<void> playConfirmation(ConfirmationActionType action) async {
    // Play sound
    await _playSound(action);
    
    // Trigger haptic feedback
    await _triggerHaptic(action);
  }

  /// Play sound based on action type
  static Future<void> _playSound(ConfirmationActionType action) async {
    try {
      final soundAsset = _getSoundAssetPath(action);
      await platform.invokeMethod('playSound', {
        'asset': soundAsset,
        'volume': 1.0,
      });
    } catch (e) {
      // Fallback: continue with just haptics
    }
  }

  /// Trigger haptic feedback based on action type
  static Future<void> _triggerHaptic(ConfirmationActionType action) async {
    try {
      final pattern = _getHapticPattern(action);
      await hapticChannel.invokeMethod('playHaptic', {
        'pattern': pattern,
        'duration': _getHapticDuration(action),
      });
    } catch (e) {
      print('Error triggering haptic: $e');
    }
  }

  /// Map action types to sound asset paths
  static String _getSoundAssetPath(ConfirmationActionType action) {
    switch (action) {
      case ConfirmationActionType.police_called:
        return 'assets/sounds/police_dispatch.mp3';
      case ConfirmationActionType.tweet_posted:
        return 'assets/sounds/tweet_sent.mp3';
      case ConfirmationActionType.en_route:
        return 'assets/sounds/en_route.mp3';
      case ConfirmationActionType.public_post_live:
        return 'assets/sounds/post_live.mp3';
      case ConfirmationActionType.contact_notified:
        return 'assets/sounds/contact_notified.mp3';
      case ConfirmationActionType.emergency_stopped:
        return 'assets/sounds/emergency_stopped.mp3';
    }
  }

  /// Map action types to haptic patterns
  /// Patterns are defined as arrays of vibration durations (ms)
  static List<int> _getHapticPattern(ConfirmationActionType action) {
    switch (action) {
      // Police called: Double pulse - urgent
      case ConfirmationActionType.police_called:
        return [0, 100, 50, 100, 50, 200];
      
      // Tweet posted: Single short pulse - confirmation
      case ConfirmationActionType.tweet_posted:
        return [0, 80];
      
      // En route: Triple quick pulse - urgent alert
      case ConfirmationActionType.en_route:
        return [0, 60, 40, 60, 40, 60];
      
      // Public post live: Long gentle pulse - broadcast
      case ConfirmationActionType.public_post_live:
        return [0, 150];
      
      // Contact notified: Light single tap - subtle
      case ConfirmationActionType.contact_notified:
        return [0, 50];
      
      // Emergency stopped: Three short taps - resolved
      case ConfirmationActionType.emergency_stopped:
        return [0, 40, 30, 40, 30, 40];
    }
  }

  /// Get haptic duration for each action
  static int _getHapticDuration(ConfirmationActionType action) {
    switch (action) {
      case ConfirmationActionType.police_called:
        return 400;
      case ConfirmationActionType.tweet_posted:
        return 150;
      case ConfirmationActionType.en_route:
        return 400;
      case ConfirmationActionType.public_post_live:
        return 300;
      case ConfirmationActionType.contact_notified:
        return 100;
      case ConfirmationActionType.emergency_stopped:
        return 350;
    }
  }

  /// Silent confirmation - haptics only (for discreet use)
  static Future<void> playDiscreetConfirmation(
      ConfirmationActionType action) async {
    await _triggerHaptic(action);
    // No sound, just haptic - perfect for when phone is in pocket or in danger
  }

  /// Test confirmation - verify system works
  static Future<void> testConfirmation() async {
    try {
      await platform.invokeMethod('testSound');
      await hapticChannel.invokeMethod('testHaptic');
    } catch (e) {
      print('Error testing confirmation: $e');
    }
  }

  /// Enable/disable confirmation sounds
  static Future<void> setSoundEnabled(bool enabled) async {
    try {
      await platform.invokeMethod('setSoundEnabled', {
        'enabled': enabled,
      });
    } catch (e) {
      print('Error setting sound enabled: $e');
    }
  }

  /// Enable/disable haptic feedback
  static Future<void> setHapticEnabled(bool enabled) async {
    try {
      await hapticChannel.invokeMethod('setHapticEnabled', {
        'enabled': enabled,
      });
    } catch (e) {
      print('Error setting haptic enabled: $e');
    }
  }

  /// Set volume level (0.0 to 1.0)
  static Future<void> setVolume(double volume) async {
    try {
      await platform.invokeMethod('setVolume', {
        'volume': volume.clamp(0.0, 1.0),
      });
    } catch (e) {
      print('Error setting volume: $e');
    }
  }
}

/// Usage Examples:
/// 
/// // Play confirmation when police is called
/// ConfirmationSoundSystem.playConfirmation(
///   ConfirmationActionType.police_called
/// );
/// 
/// // Discreet feedback in dangerous situation
/// ConfirmationSoundSystem.playDiscreetConfirmation(
///   ConfirmationActionType.contact_notified
/// );
/// 
/// // Test system during onboarding
/// ConfirmationSoundSystem.testConfirmation();
/// 
/// // User preferences
/// ConfirmationSoundSystem.setSoundEnabled(false); // Silent mode
/// ConfirmationSoundSystem.setHapticEnabled(true);  // Haptics only
