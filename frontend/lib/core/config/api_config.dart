import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // BACKEND_HOST is loaded from .env (e.g. BACKEND_HOST=10.1.10.11).
  // If unset, falls back to per-platform localhost detection below.
  static String get _physicalDeviceUrl {
    final host = dotenv.maybeGet('BACKEND_HOST') ?? '';
    if (host.isEmpty) return '';
    return 'http://$host:8000';
  }

  static const String ANDROID_EMULATOR_URL = 'http://10.0.2.2:8000';
  static const String IOS_SIMULATOR_URL = 'http://127.0.0.1:8000';
  static const String WEB_URL = 'http://localhost:8000';
  static const String FALLBACK_URL = 'http://localhost:8000';

  static String getGeminiApiKey() => dotenv.maybeGet('GEMINI_API_KEY') ?? '';

  static bool _printed = false;

  static String get baseUrl {
    // Prefer BACKEND_HOST from .env when present
    final physicalUrl = _physicalDeviceUrl;
    if (physicalUrl.isNotEmpty) {
      _printOnce('Using BACKEND_HOST from .env: $physicalUrl');
      return physicalUrl;
    }

    if (kIsWeb) {
      _printOnce('Web platform: $WEB_URL');
      return WEB_URL;
    }

    if (Platform.isAndroid) {
      _printOnce('Android platform: $ANDROID_EMULATOR_URL');
      return ANDROID_EMULATOR_URL;
    }

    if (Platform.isMacOS) {
      _printOnce('macOS platform: $IOS_SIMULATOR_URL');
      return IOS_SIMULATOR_URL;
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


