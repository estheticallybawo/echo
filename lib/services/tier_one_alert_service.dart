import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// TierOneAlertService
/// Manages the dispatch of alerts to the inner circle (Tier 1 contacts).
/// This service communicates with the ECHO backend to send automatic WhatsApp/SMS.
class TierOneAlertService {
  
  /// Sends the initial emergency alert to Tier 1 contacts via Firebase (FCM) and Telegram.
  Future<String?> sendInitialAlert({
    required String userId,
    required String gemmaSummary,
    required Map<String, double> location,
    String? address, 
    List<String>? telegramChatIds, 
  }) async {
    debugPrint('ECHO: Dispatching Secure Alerts (FCM Push & Telegram)...');

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('startEmergency');
      
      final response = await callable.call({
        'userId': userId,
        'summary': gemmaSummary,
        'lat': location['latitude'],
        'lng': location['longitude'],
        'address': address,
        'telegramChatIds': telegramChatIds, 
        'channel': 'fcm_telegram', 
      });
      
      if (response.data != null) {
        final incidentId = response.data['incidentId'];
        debugPrint('ECHO: Firebase Alerts successfully dispatched. Incident ID: $incidentId');
        return incidentId; // Return the ID so we can sync updates to it
      }
      return null;
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        debugPrint('ECHO: Firebase Function Error [${e.code}]: ${e.message}');
        debugPrint('ECHO: Details: ${e.details}');
      } else {
        debugPrint('ECHO: Unknown Dispatch Error: $e');
      }
      return null;
    }
  }

  Future<void> sendStatusUpdate(String updateMessage) async {
    debugPrint('ECHO: Sending nudge: $updateMessage');
  }
}
