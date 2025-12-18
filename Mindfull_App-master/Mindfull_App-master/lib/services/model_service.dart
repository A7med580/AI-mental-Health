import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mindful/core/config/api_config.dart';

class ModelService {

  /// Check if backend is healthy
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('health')),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Extract features from video
  Future<Map<String, dynamic>> extractVideoFeatures(File videoFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.getUrl('extract-features')}?modality=video'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('video_file', videoFile.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Feature extraction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error extracting video features: $e');
    }
  }

  /// Extract features from audio
  Future<Map<String, dynamic>> extractAudioFeatures(File audioFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.getUrl('extract-features')}?modality=audio'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('audio_file', audioFile.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Feature extraction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error extracting audio features: $e');
    }
  }

  /// Screen specifically for ADHD (runs all ADHD models and fuses results)
  Future<Map<String, dynamic>> screenADHD({
    File? videoFile,
    File? audioFile,
    Map<String, dynamic>? questionnaireData,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getUrl('screening/adhd')),
      );

      // Add video file if provided
      if (videoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('video_file', videoFile.path),
        );
      }

      // Add audio file if provided
      if (audioFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('audio_file', audioFile.path),
        );
      }

      // Add questionnaire data if provided
      if (questionnaireData != null) {
        request.fields['questionnaire_data'] = json.encode(questionnaireData);
      }

      // Set timeouts
      final client = http.Client();
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2), // Total timeout including upload
        onTimeout: () {
          client.close();
          throw TimeoutException('Request timed out');
        },
      );

      // Read response with timeout
      final responseBody = await streamedResponse.stream.bytesToString().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Response timeout');
        },
      );

      final response = http.Response(responseBody, streamedResponse.statusCode);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw HttpException(
          'ADHD screening failed: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException catch (e) {
      rethrow;
    } on TimeoutException catch (e) {
      rethrow;
    } on HttpException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('Error running ADHD screening: $e');
    }
  }

  /// Run screening with ranked conditions
  Future<Map<String, dynamic>> runScreening({
    required List<Map<String, dynamic>> rankedConditions,
    required List<String> availableModalities,
    File? videoFile,
    File? audioFile,
    Map<String, dynamic>? questionnaireData,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getUrl('run-screening')),
      );

      // Add ranked conditions
      request.fields['ranked_conditions'] = json.encode(rankedConditions);
      request.fields['available_modalities'] = json.encode(availableModalities);

      // Add video file if provided
      if (videoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('video_file', videoFile.path),
        );
      }

      // Add audio file if provided
      if (audioFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('audio_file', audioFile.path),
        );
      }

      // Add questionnaire data if provided
      if (questionnaireData != null) {
        request.fields['questionnaire_data'] = json.encode(questionnaireData);
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Screening failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error running screening: $e');
    }
  }

  /// Predict ADHD using behavior model
  Future<Map<String, dynamic>> predictADHDBehavior(
    Map<String, dynamic> features,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl('predict/adhd/behavior')),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(features),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting ADHD behavior: $e');
    }
  }

  /// Predict ADHD using eye-tracking model
  Future<Map<String, dynamic>> predictADHDEye(
    Map<String, dynamic> eyeFeatures,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl('predict/adhd/eye')),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(eyeFeatures),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting ADHD eye: $e');
    }
  }

  /// Predict ADHD using voice model
  Future<Map<String, dynamic>> predictADHDVoice(File audioFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getUrl('predict/adhd/voice')),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('audio_file', audioFile.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting ADHD voice: $e');
    }
  }

  /// Predict ADHD using facial expression model
  Future<Map<String, dynamic>> predictADHDFacial(File videoFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getUrl('predict/adhd/facial')),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('video_file', videoFile.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting ADHD facial: $e');
    }
  }

  /// Predict anxiety
  Future<Map<String, dynamic>> predictAnxiety(
    Map<String, dynamic> features,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl('predict/anxiety')),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(features),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting anxiety: $e');
    }
  }

  /// Predict ASD using face model
  Future<Map<String, dynamic>> predictASDFace(File videoFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getUrl('predict/asd/face')),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('video_file', videoFile.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting ASD face: $e');
    }
  }

  /// Predict ASD using text model (AQ-10 scores)
  Future<Map<String, dynamic>> predictASDText(List<int> aq10Scores) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl('predict/asd/text')),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(aq10Scores),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting ASD text: $e');
    }
  }
}

