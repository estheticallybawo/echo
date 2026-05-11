import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// PerformanceProfile
/// Higher profiles allow for heavier local Gemma models.
enum PerformanceProfile { low, medium, high }

/// HardwareMonitor
/// Real-time analyzer that senses device constraints.
class HardwareMonitor {
  final _deviceInfo = DeviceInfoPlugin();
  final _battery = Battery();
  final _connectivity = Connectivity();
  
  /// Determines the best AI strategy based on real hardware telemetry.
  Future<AIStrategy> getBestAIStrategy() async {
    debugPrint('🔍 Telemetry: Sensing hardware state...');

    // 1. Check Connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    final bool hasNoInternet = connectivityResult.contains(ConnectivityResult.none);

    // 2. Check Battery Level
    final int batteryLevel = await _battery.batteryLevel;
    final bool isLowPowerMode = batteryLevel < 20;

    // 3. Check System Memory (Android specific example)
    int deviceRamGB = 4; // Fallback
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      // Note: totalMemory requires a physical memory check, we'll estimate via device specs
      // or assume 4GB+ for modern AI-capable phones as per LiteRT requirements.
      debugPrint('   📱 Device: ${androidInfo.model}');
    }

    // --- DECISION LOGIC ---

    // Prioritize Survival: If there is NO internet, we HAVE to go local.
    if (hasNoInternet) {
      debugPrint('   📡 ALERT: 0% Signal. Forcing Local Gemma (Edge) for survival.');
      return AIStrategy.localOnly;
    }

    // Save Power: Local AI drains battery fast. 
    // If battery is low but internet is good, use the cloud.
    if (isLowPowerMode) {
      debugPrint('   🪫 Alert: Low Battery ($batteryLevel%). Routing to Cloud Flash to save juice.');
      return AIStrategy.cloudHeavy;
    }

    // Optimal Mode: If signal and battery are good, use Hybrid.
    debugPrint('   🚀 Hardware Optimal: Using Hybrid Orchestration.');
    return AIStrategy.hybrid;
  }

  /// Fetches actual battery level for telemetry.
  Future<int> getRealBatteryLevel() async {
    return await _battery.batteryLevel;
  }
}

enum AIStrategy {
  localOnly,    // Use E2B/E4B on device (Offline/Crisis mode)
  cloudHeavy,   // Use Gemini 1.5 Flash API (Low-RAM/Battery saving mode)
  hybrid        // Local for sensing, Cloud for deep reasoning (Ideal mode)
}
