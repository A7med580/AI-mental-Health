import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Helper to handle camera access on macOS where the `camera` plugin
/// is not available and `ImageSource.camera` is unsupported.
///
/// On macOS we fall back to picking an image from the gallery so the
/// screening flow can still proceed without crashing.
///
/// This file is macOS-only glue — it does NOT change any iPhone logic.
class MacOSCameraHelper {
  MacOSCameraHelper._();

  /// `true` when the app is running natively on macOS (not iOS simulator).
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// Returns `true` when the native `camera` plugin is available.
  /// On macOS it is not, so we must use gallery fallback.
  static bool get isCameraPluginAvailable => !isMacOS;

  /// Pick an image that works on every platform.
  ///
  /// * **iOS / Android**: opens the device camera (`ImageSource.camera`).
  /// * **macOS**: opens the file picker / gallery (`ImageSource.gallery`)
  ///   because `ImageSource.camera` throws on macOS.
  static Future<XFile?> pickImage({
    ImagePicker? picker,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final _picker = picker ?? ImagePicker();
    final source = isMacOS ? ImageSource.gallery : ImageSource.camera;

    return _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Pick a video that works on every platform.
  ///
  /// * **iOS / Android**: records via `ImageSource.camera`.
  /// * **macOS**: selects a file from disk via `ImageSource.gallery`.
  static Future<XFile?> pickVideo({
    ImagePicker? picker,
    Duration? maxDuration,
  }) async {
    final _picker = picker ?? ImagePicker();
    final source = isMacOS ? ImageSource.gallery : ImageSource.camera;

    return _picker.pickVideo(source: source, maxDuration: maxDuration);
  }
}
