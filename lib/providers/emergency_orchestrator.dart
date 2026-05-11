import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/location_manager.dart';
import '../services/tier_one_alert_service.dart';
import '../services/gemma_service.dart';
import '../services/hardware_monitor.dart';
import '../services/geocoding_service.dart';
import '../services/audio_capture_service.dart';
import '../services/gemma_local_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact.dart';
import 'settings_provider.dart';

enum EmergencyState { idle, triggered, active, resolved, cancelled }

/// EmergencyOrchestrator
/// COORDINATES: Location (GPS) + Acoustic Intel (Gemma 4) + Multi-Channel Alerts (SMS/Telegram)
class EmergencyOrchestrator extends ChangeNotifier {
  final LocationManager _locationManager;
  final TierOneAlertService _alertService;
  final GemmaService _gemmaService;
  final HardwareMonitor _hardwareMonitor;
  final GeocodingService _geocodingService;
  final AudioCaptureService _audioCaptureService = AudioCaptureService(); 
  final GemmaLocalService _gemmaLocalService = GemmaLocalService();
  final SettingsProvider _settingsProvider;

  EmergencyState _state = EmergencyState.idle;
  AIStrategy _activeStrategy = AIStrategy.cloudHeavy;
  Map<String, double>? _triggerLocation;
  String? _exactAddress;
  String? _currentIncidentId;

  EmergencyState get state => _state;
  Map<String, double>? get triggerLocation => _triggerLocation;
  String? get exactAddress => _exactAddress;
  String? get currentIncidentId => _currentIncidentId;

  EmergencyOrchestrator({
    required LocationManager locationManager,
    required TierOneAlertService alertService,
    required GemmaService gemmaService,
    required HardwareMonitor hardwareMonitor,
    required GeocodingService geocodingService,
    required SettingsProvider settingsProvider,
  })  : _locationManager = locationManager,
        _alertService = alertService,
        _gemmaService = gemmaService,
        _hardwareMonitor = hardwareMonitor,
        _geocodingService = geocodingService,
        _settingsProvider = settingsProvider {
    _initBackgroundListener();
    try {
      _gemmaLocalService.init(); 
    } catch (e) {
      debugPrint('⚠️ Local Gemma AI not available on this platform: $e');
    }
  }

  void _initBackgroundListener() {
    try {
      final port = ReceivePort();
      IsolateNameServer.registerPortWithName(port.sendPort, 'silent_sos_port');
      port.listen((message) {
        if (message == 'TRIGGER_SOS') {
          activateEmergency(userId: 'current_user_id', userName: 'User'); 
        }
      });
    } catch (e) {
      debugPrint('⚠️ Background listener not supported on this platform: $e');
    }
  }

  /// ACTIVATE: The main entry point for the ECHO protocol.
  Future<void> activateEmergency({
    required String userId, 
    required String userName,
    List<Contact>? contacts, // Pass contacts to get Telegram IDs
  }) async {
    if (_state != EmergencyState.idle) return;

    _state = EmergencyState.triggered;
    notifyListeners();

    // 1. HARDWARE & STRATEGY
    _activeStrategy = await _hardwareMonitor.getBestAIStrategy();

    // 2. LOCATION GROUNDING
    _triggerLocation = await _locationManager.getTriggerSnapshot();
    if (_triggerLocation != null) {
      _exactAddress = await _geocodingService.getAddressFromLatLng(
        _triggerLocation!['latitude']!, 
        _triggerLocation!['longitude']!,
      );
    }
    notifyListeners();

    // 3. START LIVE TRACKING
    _locationManager.startLiveTracking(onLocationUpdate: (newPosition) {
       debugPrint('Updating Live Position: $newPosition');
       // In a real app, you'd sync this to Firestore here
    });

    // 4. SECURE MULTI-CHANNEL DISPATCH
    List<String> telegramIds = contacts
        ?.where((c) => c.telegramChatId != null && c.telegramChatId!.isNotEmpty)
        .map((c) => c.telegramChatId!)
        .toList() ?? [];

    debugPrint('ECHO: Found ${telegramIds.length} contacts with Telegram IDs.');
    if (telegramIds.isEmpty) {
      debugPrint('WARNING: No Telegram IDs found! Make sure you added them in the Add Contact screen.');
    }

    _currentIncidentId = await _alertService.sendInitialAlert(
      userId: userId,
      gemmaSummary: "SOS ACTIVATED at ${_exactAddress ?? 'Unknown Location'}. Situational analysis pending...",
      location: _triggerLocation ?? {'latitude': 0, 'longitude': 0},
      address: _exactAddress,
      telegramChatIds: telegramIds,
    );

    // 5. LIVE SYNC TO FIRESTORE
    if (_currentIncidentId != null) {
      _locationManager.startLiveTracking(onLocationUpdate: (newPosition) {
        FirebaseFirestore.instance
            .collection('incidents')
            .doc(_currentIncidentId!)
            .update({
          'location': {
            'lat': newPosition['latitude'],
            'lng': newPosition['longitude'],
          },
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      });
    }

    // 6. BACKGROUND ACOUSTIC CAPTURE (Gemma 4 Analysis)
    _processAcousticIntel(userId, userName, contacts);

    _state = EmergencyState.active;
    notifyListeners();
  }

  /// Tier 2: Escalate to extended contacts
  Future<void> escalateToTier2({required String userId, List<Contact>? contacts}) async {
    debugPrint('ECHO: Escalating to Tier 2 (Extended Contacts)...');
    List<String> telegramIds = contacts
        ?.where((c) => c.telegramChatId != null && c.telegramChatId!.isNotEmpty)
        .map((c) => c.telegramChatId!)
        .toList() ?? [];

    if (telegramIds.isNotEmpty) {
      await _alertService.sendInitialAlert(
        userId: userId,
        gemmaSummary: "TIER 2 ESCALATION: Emergency still active at ${_exactAddress ?? 'Location Locked'}.",
        location: _triggerLocation ?? {'latitude': 0, 'longitude': 0},
        address: _exactAddress,
        telegramChatIds: telegramIds,
      );
    }
  }

  /// Tier 3: Public Echo Post
  Future<void> escalateToTier3({required String userId}) async {
    debugPrint('ECHO: Escalating to Tier 3 (Public Echo Post)...');
    // Implementation: Create a public document in 'echo_posts' collection
    await FirebaseFirestore.instance.collection('echo_posts').add({
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'message': "PUBLIC SAFETY ALERT: An emergency has been escalated to Tier 3. Nearby users please be vigilant.",
      'address': _exactAddress ?? "Location withheld for privacy",
      'status': 'active',
    });
  }

  /// Secretly captures and analyzes multimodal audio using Gemma 4.
  Future<void> _processAcousticIntel(String userId, String userName, List<Contact>? contacts) async {
    final audioPath = await _audioCaptureService.recordEvidenceSnippet();
    if (audioPath != null) {
      String summary;
      
      try {
        final Uint8List audioBytes = await File(audioPath).readAsBytes();
        List<Uint8List> signatures = [];
        
        if (_activeStrategy == AIStrategy.localOnly) {
          summary = await _gemmaLocalService.analyzeMultimodalAudio(
            address: _exactAddress ?? "Unknown", 
            rawAudioBuffer: audioBytes,
            trainedSignatureTokens: signatures,
          );
        } else {
          summary = await _gemmaService.analyzeMultimodalScenario(
            location: _triggerLocation ?? {'latitude': 0, 'longitude': 0},
            address: _exactAddress,
            rawAudioTokens: audioBytes,
          );
        }

        List<String> telegramIds = contacts
            ?.where((c) => c.telegramChatId != null)
            .map((c) => c.telegramChatId!)
            .toList() ?? [];

        // DISPATCH AI INSIGHT TO ALL CHANNELS
        await _alertService.sendInitialAlert(
          userId: userId,
          gemmaSummary: "GEMMA 4 INSIGHT: $summary",
          location: _triggerLocation ?? {'latitude': 0, 'longitude': 0},
          address: _exactAddress,
          telegramChatIds: telegramIds,
        );
      } catch (e) {
        debugPrint('GEMMA 4 Multimodal Error: $e');
      }

      await _audioCaptureService.deleteEvidence(audioPath);
    }
  }

  void resolveEmergency() {
    _locationManager.stopTracking();
    _state = EmergencyState.idle;
    _triggerLocation = null;
    _exactAddress = null;
    notifyListeners();
  }
}
