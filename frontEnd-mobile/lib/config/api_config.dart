import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _overrideHost = String.fromEnvironment('API_BASE_URL');
  static const bool _realDevice = bool.fromEnvironment('REAL_DEVICE');

  static String get host {
    if (_overrideHost.isNotEmpty) return _overrideHost;

    if (kReleaseMode) {
      // Production Render backend URL
      // return 'https://sevenjemty.onrender.com/';
      return 'https://7jemty-production.up.railway.app/';
    }

    // --- Dev Mode (Local) ---
    if (kIsWeb) return 'http://127.0.0.1:3000';
    if (Platform.isAndroid && _realDevice) return 'http://127.0.0.1:3000';

    // Android emulator
    return 'http://10.0.2.2:3000';
  }

  static String endpoint(String path) => '$host$path';
}
