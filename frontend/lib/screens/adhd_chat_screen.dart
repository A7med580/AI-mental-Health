import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/services/video_storage_service.dart';
import 'package:mindful/screens/video_preview_screen.dart';
import 'package:mindful/screens/processing_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

/// ADHD-specific chat interview screen
class ADHDChatScreen extends StatefulWidget {
  final double initialProbability;
  final Map<int, int> questionnaireAnswers;

  const ADHDChatScreen({
    Key? key,
    required this.initialProbability,
    required this.questionnaireAnswers,
  }) : super(key: key);

  @override
  State<ADHDChatScreen> createState() => _ADHDChatScreenState();
}

class _ADHDChatScreenState extends State<ADHDChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  CameraController? _cameraController;

  bool _isRecording = false;
  bool _isProcessing = false;

  bool _cameraPermissionGranted = false;
  bool _microphonePermissionGranted = false;

  bool _cameraPermissionRequested = false;

  final List<ChatMessage> _messages = [];
  int _currentQuestionIndex = 0;

  final Map<int, String> _questionAnswers = {};
  final Map<int, String?> _questionVideos = {};

  // DSM-5 aligned questions
  final List<ADHDQuestion> _adhdQuestions = [
    ADHDQuestion(
      text: "Do you often find it hard to stay focused on tasks that require long attention, like reading or listening to lectures?",
      category: "inattention",
      requiresVideo: false,
    ),
    ADHDQuestion(
      text: "Do you often make careless mistakes in work or school activities because you're not paying attention to details?",
      category: "inattention",
      requiresVideo: false,
    ),
    ADHDQuestion(
      text: "Do you often have trouble organizing tasks and activities? For example, do you struggle to keep things in order or manage your time?",
      category: "inattention",
      requiresVideo: false,
    ),
    ADHDQuestion(
      text: "Do you often feel restless, like you need to move around even when you're supposed to stay seated?",
      category: "hyperactivity",
      requiresVideo: true,
    ),
    ADHDQuestion(
      text: "Do you often have difficulty waiting your turn in conversations or activities?",
      category: "impulsivity",
      requiresVideo: true,
    ),
    ADHDQuestion(
      text: "Do you often interrupt others when they're speaking or finish their sentences?",
      category: "impulsivity",
      requiresVideo: false,
    ),
    ADHDQuestion(
      text: "Do you often lose things you need for tasks, like keys, phone, or important documents?",
      category: "inattention",
      requiresVideo: false,
    ),
    ADHDQuestion(
      text: "Do you often feel like your mind is racing or you have too many thoughts at once?",
      category: "inattention",
      requiresVideo: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _precheckPermissions();
  }

  Future<void> _initializeChat() async {
    _addSystemMessage(
      "Hello! I'm here to help you understand patterns related to attention and focus. "
      "This is a screening tool, not a medical diagnosis. "
      "I'll ask you some questions - please answer honestly and take your time.",
    );

    await Future.delayed(const Duration(milliseconds: 400));
    _askNextQuestion();
  }

  /// Pre-check permissions (does NOT force popup)
  Future<void> _precheckPermissions() async {
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;

    setState(() {
      _cameraPermissionGranted = cam.isGranted;
      _microphonePermissionGranted = mic.isGranted;
    });

    // If already granted, init camera immediately
    if (_cameraPermissionGranted) {
      await _initCameraController();
    }
  }

  /// ✅ THE ONLY correct way to force iOS popup reliably:
  /// actually initialize camera (and enableAudio) -> iOS shows permission dialog.
  Future<void> _requestCameraAndMicPermission() async {
    if (_cameraPermissionRequested) return;

    setState(() {
      _cameraPermissionRequested = true;
    });

    try {
      // Optional: request mic explicitly (some iOS versions need it)
      final micStatus = await Permission.microphone.request();
      setState(() => _microphonePermissionGranted = micStatus.isGranted);

      // This will trigger iOS camera permission popup when needed
      await _initCameraController();

      if (!mounted) return;

      _addSystemMessage("Camera access granted. You can now record your response.");
      await Future.delayed(const Duration(milliseconds: 200));
      _askNextQuestion();
    } catch (e) {
      if (!mounted) return;

      _addSystemMessage(
        "I couldn't access the camera. We'll continue with text-only responses. "
        "If you want to enable camera later, go to iPhone Settings → Privacy & Security.",
      );

      setState(() {
        _cameraPermissionGranted = false;
      });

      await Future.delayed(const Duration(milliseconds: 200));
      _askNextQuestion();
    }
  }

  Future<void> _initCameraController() async {
    // Dispose old controller
    await _cameraController?.dispose();
    _cameraController = null;

    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception("No cameras found");

    // Prefer front camera
    final front = cameras.where((c) => c.lensDirection == CameraLensDirection.front).toList();
    final selected = front.isNotEmpty ? front.first : cameras.first;

    final controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: true, // ✅ important for voice extraction
    );

    await controller.initialize();

    // Update state only after successful init
    _cameraController = controller;

    // Now camera permission is effectively granted
    final cam = await Permission.camera.status;
    setState(() {
      _cameraPermissionGranted = cam.isGranted || controller.value.isInitialized;
    });
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isSystem: true, timestamp: DateTime.now()));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isSystem: false, timestamp: DateTime.now()));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _askNextQuestion() {
    if (_currentQuestionIndex >= _adhdQuestions.length) {
      _completeScreening();
      return;
    }

    final question = _adhdQuestions[_currentQuestionIndex];

    // If video required but we have no camera permission: ask once
    if (question.requiresVideo && !_cameraPermissionGranted) {
      if (!_cameraPermissionRequested) {
        _addSystemMessage(
          "For the next question, it would be helpful to record a short video response. "
          "Tap the button below to allow camera access (you can still continue with text if you prefer).",
        );
      } else {
        // Permission already requested/failed -> fallback to text prompt
        _addSystemMessage(question.text);
        _addSystemMessage("Please answer in text (camera not available).");
      }
      return;
    }

    _addSystemMessage(question.text);

    if (question.requiresVideo) {
      _addSystemMessage(
        "Please record a short video (15–60 seconds). Speak naturally and be yourself.",
      );
    }
  }

  Future<void> _submitTextAnswer(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    _addUserMessage(cleaned);
    _questionAnswers[_currentQuestionIndex] = cleaned;
    _textController.clear();

    setState(() {
      _currentQuestionIndex++;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    _askNextQuestion();
  }

  Future<void> _startVideoRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not available')),
      );
      return;
    }

    if (_isRecording) return;

    try {
      // Create local temp (camera plugin writes its own file, this is just for sanity/logging)
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String _ = '${appDocDir.path}/adhd_q${_currentQuestionIndex}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await controller.startVideoRecording();

      setState(() {
        _isRecording = true;
      });

      // Auto-stop after 60 seconds
      Future.delayed(const Duration(seconds: 60), () {
        if (_isRecording) {
          _stopVideoRecording();
        }
      });
    } catch (e) {
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_isRecording) return;

    final controller = _cameraController;
    if (controller == null) return;

    try {
      final XFile tempVideoFile = await controller.stopVideoRecording();

      setState(() => _isRecording = false);

      // Save permanently
      final savedPath = await VideoStorageService.saveVideo(
        File(tempVideoFile.path),
        customName: 'adhd_q${_currentQuestionIndex}_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      final savedFile = File(savedPath);
      if (!await savedFile.exists()) throw Exception('Failed to save video file');
      if (await savedFile.length() < 2000) throw Exception('Video file is too small / empty');

      setState(() {
        _questionVideos[_currentQuestionIndex] = savedPath;
      });

      if (!mounted) return;

      _addUserMessage("✓ Video recorded");

      // Preview -> Continue
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPreviewScreen(
            videoPath: savedPath,
            onRetake: () async {
              try {
                await VideoStorageService.deleteVideo(savedPath);
              } catch (_) {}
              setState(() => _questionVideos[_currentQuestionIndex] = null);
              Navigator.pop(context);
            },
            onContinue: () {
              Navigator.pop(context);
              setState(() => _currentQuestionIndex++);
              _askNextQuestion();
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving video: $e')),
      );
    }
  }

  /// Build final payload and go to ProcessingScreen
  Future<void> _completeScreening() async {
    _addSystemMessage("Thank you! Preparing your screening...");

    setState(() => _isProcessing = true);

    try {
      final Map<String, dynamic> questionnaireData = {};

      for (final entry in widget.questionnaireAnswers.entries) {
        questionnaireData['initial_q_${entry.key}'] = entry.value;
      }

      for (final entry in _questionAnswers.entries) {
        questionnaireData['chat_q_${entry.key}_text'] = entry.value;
      }

      // Pick LAST recorded video (best)
      final recorded = _questionVideos.entries
          .where((e) => e.value != null)
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      if (recorded.isEmpty) {
        // ✅ fallback: allow text-only screening (still submit job without video)
        _addSystemMessage(
          "No video recorded. We'll continue with text-only screening.",
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProcessingScreen(
              videoFile: null, // text-only
              questionnaireData: questionnaireData,
            ),
          ),
        );
        return;
      }

      final lastPath = recorded.last.value!;
      final videoFile = File(lastPath);
      if (!await videoFile.exists()) throw Exception("Video file not found");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProcessingScreen(
            videoFile: videoFile,
            questionnaireData: questionnaireData,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _currentQuestionIndex < _adhdQuestions.length
        ? _adhdQuestions[_currentQuestionIndex]
        : null;

    final needsVideo = currentQuestion != null && currentQuestion.requiresVideo;

    final showVideoControls = needsVideo &&
        _cameraPermissionGranted &&
        _cameraController != null &&
        _cameraController!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'ADHD Screening',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),

          // Camera Preview when needed
          if (showVideoControls && !_isRecording)
            Container(
              height: 160,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CameraPreview(_cameraController!),
              ),
            ),

          if (!_isProcessing && currentQuestion != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Permission button if video required but not granted
                  if (needsVideo && !_cameraPermissionGranted && !_cameraPermissionRequested)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _requestCameraAndMicPermission,
                        icon: const Icon(Icons.lock_open),
                        label: const Text('Allow Camera & Microphone'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                  if (showVideoControls && !_isRecording)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _startVideoRecording,
                          icon: const Icon(Icons.videocam),
                          label: const Text('Record Video Response'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),

                  if (_isRecording)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _stopVideoRecording,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop Recording'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),

                  // Text input always available (fallback)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: 'Type your answer...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onSubmitted: _submitTextAnswer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.send, color: AppColors.primary),
                          onPressed: () => _submitTextAnswer(_textController.text),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'Preparing screening...',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isSystem ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: message.isSystem ? Colors.white : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: message.isSystem ? Border.all(color: Colors.grey[300]!) : null,
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(fontSize: 15, color: Colors.black87, height: 1.4),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isSystem;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isSystem,
    required this.timestamp,
  });
}

class ADHDQuestion {
  final String text;
  final String category;
  final bool requiresVideo;

  ADHDQuestion({
    required this.text,
    required this.category,
    this.requiresVideo = false,
  });
}
