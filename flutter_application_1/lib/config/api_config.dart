import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _overrideHost = String.fromEnvironment('API_BASE_URL');
  static const bool _realDevice = bool.fromEnvironment('REAL_DEVICE');

  static String get host {
    if (_overrideHost.isNotEmpty) {
      return _overrideHost;
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (Platform.isAndroid && _realDevice) {
      // Real Android device mode (typically with adb reverse tcp:3000 tcp:3000).
      return 'http://127.0.0.1:3000';
    } else if (Platform.isAndroid) {
      // ✅ 192.168.1.105 is the local IPv4 address of the dev machine.
      // This is required so physical phones on the same WiFi can connect to the local API.
      // E.g., not 10.0.2.2 which is only for emulators.
      return 'http://192.168.1.105:3000';
    } else {
      return 'http://192.168.1.105:3000';
    }
  }

  static String endpoint(String path) => '$host$path';
}
