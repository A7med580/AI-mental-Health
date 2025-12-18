import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for managing video storage
class VideoStorageService {
  static const String _videoSubdirectory = 'app_videos';

  /// Save a video file permanently to app documents directory
  /// Returns the saved file path
  static Future<String> saveVideo(File sourceFile, {String? customName}) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory videoDir = Directory(path.join(appDocDir.path, _videoSubdirectory));
      
      // Create directory if it doesn't exist
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      // Generate filename with timestamp if custom name not provided
      final String fileName = customName ?? 
          'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      final String savedPath = path.join(videoDir.path, fileName);
      final File savedFile = await sourceFile.copy(savedPath);
      
      return savedFile.path;
    } catch (e) {
      throw Exception('Failed to save video: $e');
    }
  }

  /// Get the app videos directory path
  static Future<String> getVideoDirectoryPath() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    return path.join(appDocDir.path, _videoSubdirectory);
  }

  /// Check if a video file exists
  static Future<bool> videoExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// Delete a video file
  static Future<void> deleteVideo(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete video: $e');
    }
  }

  /// Get all saved videos
  static Future<List<File>> getAllVideos() async {
    try {
      final videoDirPath = await getVideoDirectoryPath();
      final Directory videoDir = Directory(videoDirPath);
      
      if (!await videoDir.exists()) {
        return [];
      }

      final List<FileSystemEntity> entities = videoDir.listSync();
      final List<File> videos = entities
          .whereType<File>()
          .where((file) => file.path.endsWith('.mp4') || file.path.endsWith('.mov'))
          .toList();

      // Sort by modification time (newest first)
      videos.sort((a, b) {
        final aTime = a.lastModifiedSync();
        final bTime = b.lastModifiedSync();
        return bTime.compareTo(aTime);
      });

      return videos;
    } catch (e) {
      throw Exception('Failed to get videos: $e');
    }
  }
}
