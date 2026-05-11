import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// LocationManager
/// Handles high-accuracy GPS tracking for ECHO.
class LocationManager {
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Check and request location permissions
  Future<bool> requestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('ECHO: Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('ECHO: Location permissions are denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('ECHO: Location permissions are permanently denied.');
      return false;
    }

    debugPrint('ECHO: Location Permissions Granted.');
    return true;
  }

  /// Captures a one-time high-accuracy snapshot of the user's location.
  Future<Map<String, double>?> getTriggerSnapshot() async {
    debugPrint('ECHO: Capturing Trigger Location Snapshot...');
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.millisecondsSinceEpoch.toDouble(),
      };
    } catch (e) {
      debugPrint('ECHO: Failed to get current position: $e');
      return null;
    }
  }

  /// Starts the continuous location tracking stream.
  void startLiveTracking({required Function(Map<String, double>) onLocationUpdate}) {
    if (_isTracking) return;
    _isTracking = true;

    debugPrint('ECHO: Starting Live Location Stream...');

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      final update = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.millisecondsSinceEpoch.toDouble(),
      };
      onLocationUpdate(update);
    });
  }

  /// Stops tracking and cleans up resources.
  void stopTracking() {
    debugPrint('ECHO: Stopping Location Stream.');
    _isTracking = false;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  bool get isTracking => _isTracking;
}
