import 'dart:io';
import 'package:flutter/foundation.dart';

/// Central API configuration with environment-based base URL detection
/// 
/// To set base URL for physical device, edit the BASE_URL constant below.
class ApiConfig {
  // ============================================
  // CONFIGURE BASE URL HERE FOR PHYSICAL DEVICE
  // ============================================
  // For physical device: Set your PC's LAN IP address
  // Example: 'http://192.168.1.100:8000'
  // Find your IP: Windows: ipconfig | findstr IPv4
  //                Mac/Linux: ifconfig | grep inet
  static const String? PHYSICAL_DEVICE_IP = 'http://192.168.1.2:8000'; // Set this for physical device testing
  
  // Default base URLs (auto-detected)
  static const String ANDROID_EMULATOR_URL = 'http://10.0.2.2:8000';
  static const String IOS_SIMULATOR_URL = 'http://127.0.0.1:8000';
  static const String WEB_URL = 'http://localhost:8000';
  static const String FALLBACK_URL = 'http://localhost:8000';

  /// Get the base URL based on the current platform
  static String get baseUrl {
    // If physical device IP is set, use it
    if (PHYSICAL_DEVICE_IP != null && PHYSICAL_DEVICE_IP!.isNotEmpty) {
      debugPrint('[ApiConfig] Using physical device IP: $PHYSICAL_DEVICE_IP');
      return PHYSICAL_DEVICE_IP!;
    }

    if (kIsWeb) {
      debugPrint('[ApiConfig] Web platform detected, using: $WEB_URL');
      return WEB_URL;
    }

    if (Platform.isAndroid) {
      debugPrint('[ApiConfig] Android platform detected, using: $ANDROID_EMULATOR_URL');
      debugPrint('[ApiConfig] For physical device, set PHYSICAL_DEVICE_IP in api_config.dart');
      return ANDROID_EMULATOR_URL;
    }

    if (Platform.isIOS) {
      debugPrint('[ApiConfig] iOS platform detected, using: $IOS_SIMULATOR_URL');
      debugPrint('[ApiConfig] For physical device, set PHYSICAL_DEVICE_IP in api_config.dart');
      return IOS_SIMULATOR_URL;
    }

    debugPrint('[ApiConfig] Unknown platform, using fallback: $FALLBACK_URL');
    return FALLBACK_URL;
  }

  /// Get full URL for an endpoint (removes accidental spaces)
  static String getUrl(String endpoint) {
    // Remove leading/trailing slashes and spaces
    final cleanEndpoint = endpoint.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    final url = '$baseUrl/$cleanEndpoint';
    debugPrint('[ApiConfig] Full URL: $url');
    return url;
  }
}
