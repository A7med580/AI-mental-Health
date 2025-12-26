import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mindful/core/config/api_config.dart';
import 'package:mindful/services/notification_service.dart';

class JobService {
  static const Duration _submitTimeout = Duration(minutes: 2);
  static const Duration _getTimeout = Duration(seconds: 20);

  static Future<String> submitADHDJob({
    required File videoFile,
    required Map<String, dynamic> questionnaireData,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getUrl('jobs/adhd'));
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';

      request.files.add(
        await http.MultipartFile.fromPath('video_file', videoFile.path),
      );

      request.fields['questionnaire_data'] = json.encode(questionnaireData);

      final streamed = await request.send().timeout(
        _submitTimeout,
        onTimeout: () => throw TimeoutException('Submit /jobs/adhd timed out'),
      );

      final body = await streamed.stream.bytesToString().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException('Submit response read timed out'),
      );

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        final jsonResponse = json.decode(body) as Map<String, dynamic>;
        final jobId = jsonResponse['job_id']?.toString();
        if (jobId == null || jobId.isEmpty) {
          throw Exception('Backend did not return job_id. Body=$body');
        }
        return jobId;
      } else {
        throw Exception('Failed to submit job: ${streamed.statusCode} - $body');
      }
    } catch (e) {
      final s = e.toString();
      if (s.contains('Connection refused') || s.contains('Failed host lookup')) {
        throw Exception(
          'Server not connected. Check same Wi-Fi + backend running on your PC.',
        );
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    try {
      final uri = Uri.parse(ApiConfig.getUrl('jobs/$jobId'));
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(_getTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get job status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      final s = e.toString();
      if (s.contains('Connection refused') || s.contains('Failed host lookup')) {
        throw Exception('Server not connected');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getJobResult(String jobId) async {
    try {
      final uri = Uri.parse(ApiConfig.getUrl('jobs/$jobId/result'));
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(_getTimeout);

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;

        // Optional: push notification
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
        throw Exception('Failed to get job result: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      final s = e.toString();
      if (s.contains('Connection refused') || s.contains('Failed host lookup')) {
        throw Exception('Server not connected');
      }
      rethrow;
    }
  }

  /// ✅ Poll until completed/failed (and still supports old "done" just in case)
  static Future<Map<String, dynamic>> pollJobUntilDone(
    String jobId, {
    Duration pollInterval = const Duration(seconds: 2),
    int maxAttempts = 150, // 5 minutes @2s
    void Function(String status, String? error)? onStatus,
  }) async {
    int attempts = 0;

    while (attempts < maxAttempts) {
      final statusResponse = await getJobStatus(jobId);
      final statusRaw = (statusResponse['status'] ?? '').toString().toLowerCase();
      final err = statusResponse['error']?.toString();

      onStatus?.call(statusRaw, err);

      // ✅ new backend uses "completed"
      if (statusRaw == 'completed' || statusRaw == 'done') {
        return await getJobResult(jobId);
      }

      if (statusRaw == 'failed') {
        throw Exception('Job failed: ${err ?? 'Unknown error'}');
      }

      // queued / processing
      await Future.delayed(pollInterval);
      attempts++;
    }

    throw Exception('Job polling timeout after $maxAttempts attempts');
  }
}
