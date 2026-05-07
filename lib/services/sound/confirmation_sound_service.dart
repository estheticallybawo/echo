// Track C: Confirmation Sound System
// Real-time Firestore listener + Audio playback

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Confirmation Sound Service
/// 
/// Provides audio/haptic feedback for tier completion events
/// (NOT for incident creation - that's in the Firestore listener)
/// 
/// Plays confirmation when:
/// - Tier 2 escalation triggered (T+60s)
/// - Tier 1 follow-up nudge sent (T+90s)
/// - Tier 3 auto-escalation triggered (T+120s)
/// - Contact action confirmed (deep link)
class ConfirmationSoundService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Firestore listener subscription (deprecated - not used for tier confirmations)
  StreamSubscription? _incidentListener;
  
  /// Play confirmation sound for tier completion
  /// 
  /// Called by EscalationTimerService when tier is reached
  /// tierNumber: 1, 2, or 3
  Future<void> confirmTierCompletion(int tierNumber) async {
    try {
      print('🔔 Tier $tierNumber confirmation - playing sound');
      
      try {
        await _audioPlayer.play(AssetSource('sounds/confirmation.mp3'));
        print('🔊 Tier $tierNumber confirmation sound played');
      } catch (audioError) {
        print('⚠️ Audio playback failed: $audioError, using haptic feedback');
        await _playHapticFeedback();
      }
    } catch (e) {
      print('❌ Error in tier confirmation: $e');
      await _playHapticFeedback();
    }
  }
  
  /// Play confirmation sound for contact action (deep link received)
  /// 
  /// Called by DeepLinkService when user taps WhatsApp link
  Future<void> confirmContactAction() async {
    try {
      print('🔔 Contact action confirmation - playing sound');
      
      try {
        await _audioPlayer.play(AssetSource('sounds/confirmation.mp3'));
        print('🔊 Contact action confirmation sound played');
      } catch (audioError) {
        print('⚠️ Audio playback failed: $audioError, using haptic feedback');
        await _playHapticFeedback();
      }
    } catch (e) {
      print('❌ Error in contact confirmation: $e');
      await _playHapticFeedback();
    }
  }

  /// Fallback: Play haptic feedback (vibration) if audio unavailable
  /// 
  /// Provides tactile confirmation on device vibration motor
  Future<void> _playHapticFeedback() async {
    try {
      // Short double-tap pattern for incident confirmation
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.mediumImpact();
      print('📳 Haptic feedback played');
    } catch (e) {
      print('⚠️ Haptic feedback not available: $e');
    }
  }

  /// Clean up resources
  /// 
  /// Called when app closes or user logs out
  Future<void> dispose() async {
    await _incidentListener?.cancel();
    await _audioPlayer.dispose();
    print('⏹️ ConfirmationSoundService disposed');
  }
}
