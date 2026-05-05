import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Checks if a specific permission is granted
  static Future<bool> isGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Requests a specific permission
  static Future<bool> requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  /// Checks if all critical permissions are granted
  static Future<bool> hasAllCriticalPermissions() async {
    final location = await Permission.location.isGranted;
    final microphone = await Permission.microphone.isGranted;
    return location && microphone;
  }

  /// Opens app settings if permission is permanently denied
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Specialized request for multiple permissions
  static Future<Map<Permission, PermissionStatus>> requestAll() async {
    return await [
      Permission.location,
      Permission.microphone,
      Permission.contacts,
      Permission.notification,
    ].request();
  }
}
