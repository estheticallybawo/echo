// lib/services/secrets_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class SecretsService {
  static const _phraseKey = 'safety_phrase';

  static Future<String?> getSafetyPhrase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phraseKey);
  }

  static Future<void> storeSafetyPhrase(String phrase) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phraseKey, phrase);
  }
}
