import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Checks if a specific permission is granted
  static Future<bool> isGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Requests a specific permission and returns the resulting status
  static Future<PermissionStatus> requestPermission(
      Permission permission) async {
    return await permission.request();
  }

  /// Checks multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> checkStatuses(
      List<Permission> permissions) async {
    Map<Permission, PermissionStatus> statuses = {};
    for (var permission in permissions) {
      statuses[permission] = await permission.status;
    }
    return statuses;
  }

  /// Requests multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> requestPermissions(
      List<Permission> permissions) async {
    return await permissions.request();
  }

  /// Opens the app settings if a permission is permanently denied
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
