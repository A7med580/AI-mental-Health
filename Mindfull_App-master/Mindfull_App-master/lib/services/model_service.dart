import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mindful/core/config/api_config.dart';

class ModelService {
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('health')),
        headers: {'Accept': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // -----------------------------
  // General Screening (ranked)
  // -----------------------------
  Future<Map<String, dynamic>> runScreening({
    required List<Map<String, dynamic>> rankedConditions,
    required List<String> availableModalities,
    File? videoFile,
    File? audioFile,
    Map<String, dynamic>? questionnaireData,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.getUrl('run-screening')),
    );

    request.headers['Accept'] = 'application/json';

    request.fields['ranked_conditions'] = jsonEncode(rankedConditions);
    request.fields['available_modalities'] = jsonEncode(availableModalities);

    if (videoFile != null) {
      request.files.add(await http.MultipartFile.fromPath('video_file', videoFile.path));
    }

    if (audioFile != null) {
      request.files.add(await http.MultipartFile.fromPath('audio_file', audioFile.path));
    }

    if (questionnaireData != null) {
      request.fields['questionnaire_data'] = jsonEncode(questionnaireData);
    }

    final streamed = await request.send().timeout(
      const Duration(minutes: 3),
      onTimeout: () => throw TimeoutException('run-screening timed out'),
    );

    final responseBody = await streamed.stream.bytesToString().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw TimeoutException('run-screening response timeout'),
    );

    if (streamed.statusCode == 200) {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    }

    throw HttpException('run-screening failed: ${streamed.statusCode} - $responseBody');
  }
}
