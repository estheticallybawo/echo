import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hi_gemma/services/permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter.baseflow.com/permissions/methods');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'checkPermissionStatus') {
        return 0; // PermissionStatus.denied
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PermissionService Tests', () {
    test('isGranted returns false for denied permission', () async {
      final result = await PermissionService.isGranted(Permission.location);
      expect(result, isFalse);
    });

    test('hasAllCriticalPermissions returns false when denied', () async {
      final result = await PermissionService.hasAllCriticalPermissions();
      expect(result, isFalse);
    });
  });
}
