import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SettingsProvider
/// Manages user-defined triggers, custom keywords, and acoustic signatures.
class SettingsProvider extends ChangeNotifier {
  static const String _keyCustomWord = 'custom_sos_word';
  static const String _keyShakeActive = 'shake_trigger_active';
  static const String _keyVoiceActive = 'voice_trigger_active';
  static const String _keySoundActive = 'sound_trigger_active';
  static const String _keySoundPaths = 'sound_signature_paths';

  String _customWord = 'Echo SOS';
  bool _shakeActive = true;
  bool _voiceActive = true;
  bool _soundActive = false; 
  List<String> _soundSignaturePaths = []; 

  SettingsProvider() {
    _loadSettings();
  }

  // Getters
  String get customWord => _customWord;
  bool get shakeActive => _shakeActive;
  bool get voiceActive => _voiceActive;
  bool get soundActive => _soundActive;
  List<String> get soundSignaturePaths => _soundSignaturePaths;

  /// Loads persisted settings from device storage.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _customWord = prefs.getString(_keyCustomWord) ?? 'Echo SOS';
    _shakeActive = prefs.getBool(_keyShakeActive) ?? true;
    _voiceActive = prefs.getBool(_keyVoiceActive) ?? true;
    _soundActive = prefs.getBool(_keySoundActive) ?? false;
    _soundSignaturePaths = prefs.getStringList(_keySoundPaths) ?? [];
    notifyListeners();
  }

  /// Updates the custom SOS keyword.
  Future<void> setCustomWord(String word) async {
    _customWord = word;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomWord, word);
    notifyListeners();
  }

  /// Toggles the hardware shake trigger.
  Future<void> setShakeActive(bool active) async {
    _shakeActive = active;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShakeActive, active);
    notifyListeners();
  }

  /// Toggles the voice activation (Always-listening).
  Future<void> setVoiceActive(bool active) async {
    _voiceActive = active;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVoiceActive, active);
    notifyListeners();
  }

  /// Toggles the custom sound activation (Requires training).
  Future<void> setSoundActive(bool active) async {
    _soundActive = active;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundActive, active);
    notifyListeners();
  }

  /// Saves the paths to our 3-pass trained acoustic signatures.
  Future<void> saveSoundSignatures(List<String> paths) async {
    _soundSignaturePaths = paths;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySoundPaths, paths);
    notifyListeners();
  }
}
