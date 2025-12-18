import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mindful/core/config/api_config.dart';
import 'package:mindful/services/notification_service.dart';

/// Job status enum
enum JobStatus {
  queued,
  processing,
  done,
  failed,
}

/// Service for managing async screening jobs
class JobService {
  /// Submit an ADHD screening job
  /// Returns job_id
  static Future<String> submitADHDJob({
    required File videoFile,
    required Map<String, dynamic> questionnaireData,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getUrl('jobs/adhd')),
      );

      // Add video file
      request.files.add(
        await http.MultipartFile.fromPath('video_file', videoFile.path),
      );

      // Add questionnaire data
      request.fields['questionnaire_data'] = json.encode(questionnaireData);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
        final jobId = jsonResponse['job_id'] as String;
        return jobId;
      } else {
        throw Exception('Failed to submit job: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('Server not connected. Please check your network connection and ensure the backend is running.');
      }
      throw Exception('Error submitting ADHD screening job: $e');
    }
  }

  /// Get job status
  static Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('jobs/$jobId')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get job status: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('Server not connected');
      }
      throw Exception('Error getting job status: $e');
    }
  }

  /// Get job result (only call when status is "done")
  static Future<Map<String, dynamic>> getJobResult(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('jobs/$jobId/result')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        
        // Create notification when result is ready
        final fusedResult = result['fused_result'] as Map<String, dynamic>?;
        if (fusedResult != null) {
          final isAdhd = fusedResult['fused_prediction'] == 1;
          final confidence = (fusedResult['fused_confidence'] as num).toDouble();
          
          await NotificationService.createADHDScreeningNotification(
            jobId: jobId,
            isAdhd: isAdhd,
            confidence: confidence,
          );
        }
        
        return result;
      } else {
        throw Exception('Failed to get job result: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('Server not connected');
      }
      throw Exception('Error getting job result: $e');
    }
  }

  /// Poll job status until completion
  /// Returns the final result when done
  static Future<Map<String, dynamic>> pollJobUntilDone(
    String jobId, {
    Duration pollInterval = const Duration(seconds: 10),
    int maxAttempts = 60, // 10 minutes max
  }) async {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      final statusResponse = await getJobStatus(jobId);
      final status = statusResponse['status'] as String;

      if (status == 'done') {
        return await getJobResult(jobId);
      } else if (status == 'failed') {
        throw Exception('Job failed: ${statusResponse['error'] ?? 'Unknown error'}');
      }

      // Wait before next poll
      await Future.delayed(pollInterval);
      attempts++;
    }

    throw Exception('Job polling timeout after ${maxAttempts} attempts');
  }
}
