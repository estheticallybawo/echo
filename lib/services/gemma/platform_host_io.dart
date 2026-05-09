import 'dart:io' show Platform;

String getPlatformLocalHost() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}
