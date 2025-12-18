import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mindful/profile_screen.dart';
import 'package:mindful/resource_screen.dart';
import 'package:mindful/results_screen.dart';
import 'package:mindful/services/model_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreeningChatScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rankedConditions;

  const ScreeningChatScreen({
    Key? key,
    required this.rankedConditions,
  }) : super(key: key);

  @override
  State<ScreeningChatScreen> createState() => _ScreeningChatScreenState();
}

class _ScreeningChatScreenState extends State<ScreeningChatScreen> {
  final ModelService _modelService = ModelService();
  CameraController? _cameraController;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _recordedVideoPath;
  final List<String> _messages = [];
  int _currentConditionIndex = 0;
  final List<String> _availableModalities = [];

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _checkPermissions();
  }

  Future<void> _initializeChat() async {
    // Add welcome message
    setState(() {
      _messages.add('system: Welcome! I\'ll guide you through the screening process.');
    });

    // Start with first condition
    if (widget.rankedConditions.isNotEmpty) {
      await _processNextCondition();
    }
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    setState(() {
      if (cameraStatus.isGranted) {
        _availableModalities.add('video');
      }
      if (microphoneStatus.isGranted) {
        _availableModalities.add('audio');
      }
      _availableModalities.add('text'); // Always available
    });

    if (cameraStatus.isGranted) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.medium,
        );
        await _cameraController!.initialize();
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _processNextCondition() async {
    if (_currentConditionIndex >= widget.rankedConditions.length) {
      // All conditions processed, show results
      await _showFinalResults();
      return;
    }

    final condition = widget.rankedConditions[_currentConditionIndex];
    final conditionName = condition['condition'] ?? 'Unknown';
    final probability = condition['probability'] ?? 0.0;

    setState(() {
      _messages.add(
        'system: Now screening for $conditionName (probability: ${(probability * 100).toStringAsFixed(1)}%)',
      );
      _messages.add(
        'system: Please record a short video (30-60 seconds) responding to the question.',
      );
    });
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not available')),
      );
      return;
    }

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String videoPath = '${appDocDir.path}/screening_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });

      // Stop after 60 seconds
      Future.delayed(const Duration(seconds: 60), () {
        if (_isRecording) {
          _stopRecording();
        }
      });
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _recordedVideoPath = videoFile.path;
      });

      // Process the video
      await _processRecording();
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _processRecording() async {
    if (_recordedVideoPath == null) return;

    setState(() {
      _isProcessing = true;
      _messages.add('system: Processing your recording...');
    });

    try {
      final videoFile = File(_recordedVideoPath!);

      // Run screening with current conditions
      final result = await _modelService.runScreening(
        rankedConditions: widget.rankedConditions,
        availableModalities: _availableModalities,
        videoFile: videoFile,
      );

      if (result['success'] == true) {
        final detectedCondition = result['result']['detected_condition'];
        final confidence = result['result']['confidence'] ?? 0.0;

        if (detectedCondition != null && confidence >= 0.5) {
          // Strong indicator detected
          setState(() {
            _messages.add(
              'system: Strong indicators detected for $detectedCondition (confidence: ${(confidence * 100).toStringAsFixed(1)}%)',
            );
          });

          // Navigate to results screen
          await _showResults(result['result']);
        } else {
          // Move to next condition
          setState(() {
            _currentConditionIndex++;
            _messages.add('system: Moving to next condition...');
          });
          await _processNextCondition();
        }
      } else {
        throw Exception('Screening failed');
      }
    } catch (e) {
      setState(() {
        _messages.add('system: Error processing recording: $e');
      });
    } finally {
      setState(() {
        _isProcessing = false;
        _recordedVideoPath = null;
      });
    }
  }

  Future<void> _showResults(Map<String, dynamic> result) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          screeningResult: result,
          allResults: result['all_results'],
        ),
      ),
    );
  }

  Future<void> _showFinalResults() async {
    // No strong indicators found
    final result = {
      'detected_condition': null,
      'confidence': 0.0,
      'message': 'No strong indicators detected. Consider consulting a healthcare professional.',
      'all_results': [],
    };

    await _showResults(result);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Screening Session',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isSystem = message.startsWith('system:');
                final text = isSystem ? message.substring(8) : message;

                return Align(
                  alignment: isSystem ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSystem ? Colors.grey[300] : Colors.blue[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),

          // Camera Preview / Recording Controls
          if (_cameraController != null && _cameraController!.value.isInitialized)
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CameraPreview(_cameraController!),
              ),
            ),

          // Recording Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRecording && !_isProcessing)
                  ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Start Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  )
                else if (_isRecording)
                  ElevatedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  )
                else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

