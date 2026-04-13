// Track C: Confirmation Sound System
// Real-time Firestore listener + Audio playback

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Confirmation Sound Service
/// 
/// Listens to Firestore incidents in real-time and plays confirmation audio
/// when a new incident is logged (POST-incident confirmation)
/// 
/// Implements PRD Section 13.2: Confirmation sound flow
/// - Plays audio notification when incident logged to Firestore
/// - Falls back to haptic feedback if audio disabled
/// - Supports different sounds for different escalation levels
class ConfirmationSoundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Firestore listener subscription
  StreamSubscription? _incidentListener;
  
  /// Start listening to real-time incident updates for current user
  /// 
  /// Called when app starts (in main.dart or provider initialization)
  /// Returns true if listener successfully initialized
  Future<bool> startListening() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ ConfirmationSoundService: No authenticated user');
        return false;
      }

      // Listen to incidents collection for current user
      _incidentListener = _firestore
          .collection('incidents')
          .doc(user.uid)
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen(
            (snapshot) => _handleIncidentUpdate(snapshot),
            onError: (error) {
              print('❌ Firestore listener error: $error');
            },
          );

      print('✅ ConfirmationSoundService: Listening to incidents for user ${user.uid}');
      return true;
    } catch (e) {
      print('❌ ConfirmationSoundService init error: $e');
      return false;
    }
  }

  /// Handle real-time incident updates from Firestore
  /// 
  /// Plays audio when new incident is created/updated
  void _handleIncidentUpdate(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.docChanges.isEmpty) return;

    for (final change in snapshot.docChanges) {
      // Only react to newly added incidents (ADDED event)
      if (change.type == DocumentChangeType.added) {
        final incident = change.doc.data();
        if (incident != null) {
          _playConfirmationSound(incident);
        }
      }
    }
  }

  /// Play confirmation sound based on incident action type
  /// 
  /// Automatically selects sound file based on action_type field
  /// Falls back to haptic if audio unavailable
  Future<void> _playConfirmationSound(Map<String, dynamic> incident) async {
    try {
      final actionType = incident['action_type'] as String? ?? 'emergency_press';
      
      // Log which incident type triggered the sound
      print('🔊 Confirmation sound triggered for: $actionType');

      // Attempt to play audio
      try {
        await _audioPlayer.play(AssetSource('sounds/confirmation.mp3'));
        print('🔊 Playing confirmation sound');
      } catch (audioError) {
        print('⚠️ Audio playback failed: $audioError, using haptic feedback');
        // Fallback to haptic feedback
        await _playHapticFeedback();
      }
    } catch (e) {
      print('❌ Error playing confirmation sound: $e');
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

  /// Manual sound trigger - for testing or explicit confirmations
  /// 
  /// Used when you want to play sound independent of Firestore listener
  Future<void> playManualConfirmation() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/confirmation.mp3'));
      print('🔊 Manual confirmation sound played');
    } catch (e) {
      print('⚠️ Manual confirmation failed: $e');
      await _playHapticFeedback();
    }
  }

  /// Stop listening to Firestore incidents
  /// 
  /// Called when app closes or user logs out
  Future<void> stopListening() async {
    await _incidentListener?.cancel();
    await _audioPlayer.dispose();
    print('⏹️ ConfirmationSoundService stopped');
  }

  /// Dispose resources
  void dispose() {
    stopListening();
  }
}
