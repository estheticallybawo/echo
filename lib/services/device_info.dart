import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

Future<int> getDeviceRAMInGB() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    
    final ramInMB = androidInfo.physicalRamSize;
    return ramInMB ~/ 1024;  // Convert MB to GB
  }
  // iOS – fallback to a safe estimate (you can also use `NSProcessInfo` for actual value)
  return 4;
}