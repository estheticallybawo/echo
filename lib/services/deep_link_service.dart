import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'firestore_incident_service.dart';

/// Service for handling deep links from WhatsApp and other sources
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();

  factory DeepLinkService() {
    return _instance;
  }

  DeepLinkService._internal();

  final FirestoreIncidentService _firestoreService = FirestoreIncidentService();
  late StreamSubscription deepLinkSubscription;
  late AppLinks _appLinks;

  /// Initialize app links (must be called early)
  Future<void> initAppLinks() async {
    _appLinks = AppLinks();
    // Handle deep link when app is already running
    deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        print('🔗 Deep link received while app is running: $uri');
      },
      onError: (err) {
        print('❌ Deep link error: $err');
      },
    );
  }

  /// Start listening to deep links
  void startListeningToDeepLinks(BuildContext context) {
    // Handle deep link when app is launched from dead state
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        print('🔗 Initial deep link received: $uri');
        _handleDeepLink(uri.toString(), context);
      }
    }).catchError((err) {
      print('❌ Error getting initial link: $err');
    });

    // Listen to incoming deep links
    deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri.toString(), context);
      },
      onError: (err) {
        print('❌ Deep link error: $err');
      },
    );
  }

  /// Stop listening to deep links (cleanup)
  void stopListeningToDeepLinks() {
    deepLinkSubscription.cancel();
  }

  /// Parse and handle incoming deep link
  /// Format: https://echo.app/?contact_id=X&action=Y
  /// Example: https://echo.app/?contact_id=mom&action=emergency_call
  Future<void> _handleDeepLink(String link, BuildContext context) async {
    try {
      final uri = Uri.parse(link);

      // Extract parameters
      final contactId = uri.queryParameters['contact_id'];
      final action = uri.queryParameters['action'];
      final timestamp = uri.queryParameters['timestamp'];

      if (contactId == null || action == null) {
        print('⚠️ Invalid deep link: missing contact_id or action');
        return;
      }

      print('🔗 Deep link received:');
      print('   Contact ID: $contactId');
      print('   Action: $action');
      print('   Timestamp: $timestamp');

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        return;
      }

      // Log to Firestore
      final incidentId = await _firestoreService.logIncident(
        userId: user.uid,
        actionType: 'contact_action',
        contactId: contactId,
        location: '',
        threatLevel: 'LOW',
        threatCategory: 'contact_action_via_whatsapp',
        gemmaAnalysis: '',
      );

      print('✅ Incident logged: $incidentId');

      // Route to appropriate screen based on action
      _routeToScreen(context, action, contactId);
    } catch (e) {
      print('❌ Error handling deep link: $e');
    }
  }

  /// Route to appropriate screen based on action
  void _routeToScreen(BuildContext context, String action, String contactId) {
    switch (action.toLowerCase()) {
      case 'emergency_call':
      case 'emergency_press':
        // Navigate to emergency active screen
        Navigator.pushNamed(context, '/emergency');
        break;

      case 'contact_details':
      case 'view_contact':
        // Navigate to contact screen (if exists)
        Navigator.pushNamed(context, '/contacts', arguments: contactId);
        break;

      case 'fake_call':
        // Trigger fake call from contact
        Navigator.pushNamed(context, '/emergency');
        break;

      default:
        print('⚠️ Unknown action: $action');
    }
  }
}
