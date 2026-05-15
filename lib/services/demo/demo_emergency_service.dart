import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../local_storage_service.dart';

class DemoIncidentEvent {
  final String label;
  final String detail;
  final DateTime timestamp;

  const DemoIncidentEvent({
    required this.label,
    required this.detail,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'label': label,
    'detail': detail,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DemoIncidentEvent.fromMap(Map<String, dynamic> map) {
    return DemoIncidentEvent(
      label: (map['label'] as String?) ?? 'Update',
      detail: (map['detail'] as String?) ?? '',
      timestamp:
          DateTime.tryParse((map['timestamp'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

class DemoIncident {
  final String id;
  final String threat;
  final String summary;
  final String locationText;
  final String mapsUrl;
  final int tier;
  final bool isSafe;
  final DateTime startedAt;
  final DateTime updatedAt;
  final List<DemoIncidentEvent> events;

  const DemoIncident({
    required this.id,
    required this.threat,
    required this.summary,
    required this.locationText,
    required this.mapsUrl,
    required this.tier,
    required this.isSafe,
    required this.startedAt,
    required this.updatedAt,
    required this.events,
  });

  DemoIncident copyWith({
    String? threat,
    String? summary,
    String? locationText,
    String? mapsUrl,
    int? tier,
    bool? isSafe,
    DateTime? updatedAt,
    List<DemoIncidentEvent>? events,
  }) {
    return DemoIncident(
      id: id,
      threat: threat ?? this.threat,
      summary: summary ?? this.summary,
      locationText: locationText ?? this.locationText,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      tier: tier ?? this.tier,
      isSafe: isSafe ?? this.isSafe,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      events: events ?? this.events,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'threat': threat,
    'summary': summary,
    'locationText': locationText,
    'mapsUrl': mapsUrl,
    'tier': tier,
    'isSafe': isSafe,
    'startedAt': startedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'events': events.map((event) => event.toMap()).toList(),
  };

  factory DemoIncident.fromMap(Map<String, dynamic> map) {
    final rawEvents = map['events'];
    return DemoIncident(
      id: (map['id'] as String?) ?? 'demo_incident',
      threat: (map['threat'] as String?) ?? 'Emergency',
      summary: (map['summary'] as String?) ?? 'Emergency active',
      locationText: (map['locationText'] as String?) ?? 'Ikoyi, Lagos',
      mapsUrl:
          (map['mapsUrl'] as String?) ??
          'https://maps.google.com/?q=6.4541,3.4246',
      tier: (map['tier'] as num?)?.toInt() ?? 1,
      isSafe: (map['isSafe'] as bool?) ?? false,
      startedAt:
          DateTime.tryParse((map['startedAt'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
      events: rawEvents is List
          ? rawEvents
                .whereType<Map>()
                .map(
                  (event) => DemoIncidentEvent.fromMap(
                    Map<String, dynamic>.from(event),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class DemoEmergencyService {
  static final DemoEmergencyService _instance =
      DemoEmergencyService._internal();

  factory DemoEmergencyService() => _instance;

  DemoEmergencyService._internal();

  static const String bridgeBaseUrl = String.fromEnvironment(
    'ECHO_TELEGRAM_BRIDGE_URL',
    defaultValue: 'http://localhost:8790',
  );

  final LocalStorageService _storage = LocalStorageService();
  final StreamController<DemoIncident?> _controller =
      StreamController<DemoIncident?>.broadcast();
  final http.Client _client = http.Client();

  DemoIncident? _activeIncident;

  DemoIncident? get activeIncident => _activeIncident;
  Stream<DemoIncident?> get incidentStream => _controller.stream;

  Future<DemoIncident> startIncident({
    required String threat,
    required String summary,
    String locationText = 'Ikoyi, Lagos',
    String mapsUrl = 'https://maps.google.com/?q=6.4541,3.4246',
  }) async {
    final now = DateTime.now();
    final incident = DemoIncident(
      id: 'demo_${now.millisecondsSinceEpoch}',
      threat: threat,
      summary: summary,
      locationText: locationText,
      mapsUrl: mapsUrl,
      tier: 0,
      isSafe: false,
      startedAt: now,
      updatedAt: now,
      events: [
        DemoIncidentEvent(
          label: 'Emergency started',
          detail: summary,
          timestamp: now,
        ),
      ],
    );
    await _setIncident(incident);
    await _postBridge('/incident/start', incident.toMap());
    return incident;
  }

  Future<void> activateTier(int tier) async {
    final incident = _activeIncident;
    if (incident == null || incident.isSafe || incident.tier >= tier) return;

    final updated = _withEvent(
      incident.copyWith(tier: tier),
      'Tier $tier alert sent',
      tier == 1
          ? 'Inner circle contact notified through Telegram.'
          : tier == 2
          ? 'Backup contact notified through Telegram.'
          : 'Echo Feed public escalation posted locally.',
    );
    await _setIncident(updated);
    await _postBridge('/incident/tier', updated.toMap());
  }

  Future<void> markSafe({String detail = 'User marked safe in Echo.'}) async {
    final incident = _activeIncident;
    if (incident == null) return;

    final updated = _withEvent(
      incident.copyWith(isSafe: true),
      'Marked safe',
      detail,
    );
    await _setIncident(updated);
    await _postBridge('/incident/safe', updated.toMap());
  }

  Future<void> syncBridgeState() async {
    try {
      final response = await _client
          .get(Uri.parse('$bridgeBaseUrl/state'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final remote = decoded['activeIncident'];
      if (remote is! Map) return;
      final remoteIncident = DemoIncident.fromMap(
        Map<String, dynamic>.from(remote),
      );
      if (_activeIncident == null ||
          remoteIncident.updatedAt.isAfter(_activeIncident!.updatedAt)) {
        await _setIncident(remoteIncident);
      }
    } catch (error) {
      debugPrint('[DemoEmergency] Bridge sync skipped: $error');
    }
  }

  Future<void> restore() async {
    final raw = _storage.getPreference('demo_active_incident');
    if (raw is Map) {
      _activeIncident = DemoIncident.fromMap(Map<String, dynamic>.from(raw));
      _controller.add(_activeIncident);
    }
  }

  DemoIncident _withEvent(DemoIncident incident, String label, String detail) {
    final now = DateTime.now();
    return incident.copyWith(
      updatedAt: now,
      events: [
        ...incident.events,
        DemoIncidentEvent(label: label, detail: detail, timestamp: now),
      ],
    );
  }

  Future<void> _setIncident(DemoIncident incident) async {
    _activeIncident = incident;
    await _storage.setPreference('demo_active_incident', incident.toMap());
    _controller.add(incident);
  }

  Future<void> _postBridge(String path, Map<String, dynamic> body) async {
    try {
      await _client
          .post(
            Uri.parse('$bridgeBaseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 4));
    } catch (error) {
      debugPrint('[DemoEmergency] Bridge post skipped: $error');
    }
  }
}
