import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get host {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://localhost:3000';
    }
  }

  static String endpoint(String path) => '$host$path';
}
