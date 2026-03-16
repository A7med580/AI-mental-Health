import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Put your Mac LAN IP here for REAL iPhone
  static const String PHYSICAL_DEVICE_IP = 'http://192.168.1.15:8000';

  static const String ANDROID_EMULATOR_URL = 'http://10.0.2.2:8000';
  static const String IOS_SIMULATOR_URL = 'http://127.0.0.1:8000';
  static const String WEB_URL = 'http://localhost:8000';
  static const String FALLBACK_URL = 'http://localhost:8000';

  static bool _printed = false;

  static String get baseUrl {
    // Always use physical IP if set
    if (PHYSICAL_DEVICE_IP.isNotEmpty) {
      _printOnce('Using physical device IP: $PHYSICAL_DEVICE_IP');
      return PHYSICAL_DEVICE_IP;
    }

    if (kIsWeb) {
      _printOnce('Web platform: $WEB_URL');
      return WEB_URL;
    }

    if (Platform.isAndroid) {
      _printOnce('Android platform: $ANDROID_EMULATOR_URL');
      return ANDROID_EMULATOR_URL;
    }

    if (Platform.isIOS) {
      _printOnce('iOS platform: $IOS_SIMULATOR_URL');
      return IOS_SIMULATOR_URL;
    }

    _printOnce('Unknown platform: $FALLBACK_URL');
    return FALLBACK_URL;
  }

  static String getUrl(String endpoint) {
    final cleanEndpoint = endpoint.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    return '$baseUrl/$cleanEndpoint';
  }

  static void _printOnce(String msg) {
    if (!_printed && kDebugMode) {
      debugPrint('[ApiConfig] $msg');
      _printed = true;
    }
  }
}
