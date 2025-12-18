import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/services/model_service.dart';
import 'package:mindful/screens/adhd_result_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

/// ADHD-specific chat interview screen
/// Implements therapist-style questioning aligned with DSM-5 ADHD criteria
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
  final ModelService _modelService = ModelService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  
  CameraController? _cameraController;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _cameraPermissionGranted = false;
  bool _cameraPermissionRequested = false;
  
  final List<ChatMessage> _messages = [];
  int _currentQuestionIndex = 0;
  final Map<int, String> _questionAnswers = {}; // question_index -> user_answer_text
  final Map<int, String?> _questionVideos = {}; // question_index -> video_path
  
  // DSM-5 aligned ADHD questions (inattention, hyperactivity, impulsivity)
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
      requiresVideo: true, // Video helps assess restlessness
    ),
    ADHDQuestion(
      text: "Do you often have difficulty waiting your turn in conversations or activities?",
      category: "impulsivity",
      requiresVideo: true, // Video helps assess impulsivity
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
    _checkPermissions();
  }

  Future<void> _initializeChat() async {
    // Welcome message
    _addSystemMessage(
      "Hello! I'm here to help you understand patterns related to attention and focus. "
      "This is a screening tool, not a medical diagnosis. "
      "I'll ask you some questions - please answer honestly and take your time."
    );
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Start with first question
    _askNextQuestion();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;
    
    setState(() {
      _cameraPermissionGranted = cameraStatus.isGranted;
    });
    
    if (cameraStatus.isGranted) {
      _initializeCamera();
    }
  }

  Future<void> _requestCameraPermission() async {
    if (_cameraPermissionRequested) return;
    
    setState(() {
      _cameraPermissionRequested = true;
    });
    
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      setState(() {
        _cameraPermissionGranted = true;
      });
      _initializeCamera();
      _addSystemMessage("Thank you! Camera access granted. This helps us better understand your responses.");
    } else {
      _addSystemMessage("That's okay. We can continue without video. Your privacy is important to us.");
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
          duration: const Duration(milliseconds: 300),
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
    
    // Ask for camera permission if needed and not yet requested
    if (question.requiresVideo && !_cameraPermissionGranted && !_cameraPermissionRequested) {
      _addSystemMessage(
        "For the next question, it would be helpful to see your response. "
        "May I access your camera? This helps us better understand your communication patterns. "
        "You can decline and continue with text-only responses."
      );
      // Don't ask question yet - wait for permission response
      return;
    }
    
    _addSystemMessage(question.text);
    
    // If video is required and available, prompt for video response
    if (question.requiresVideo && _cameraPermissionGranted && _cameraController != null) {
      _addSystemMessage(
        "Please record a short video (30-60 seconds) responding to this question. "
        "Speak naturally and be yourself."
      );
    }
  }

  Future<void> _submitTextAnswer(String text) async {
    if (text.trim().isEmpty) return;
    
    _addUserMessage(text);
    _questionAnswers[_currentQuestionIndex] = text;
    
    // Move to next question
    setState(() {
      _currentQuestionIndex++;
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    _askNextQuestion();
  }

  Future<void> _startVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not available')),
      );
      return;
    }

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String videoPath = '${appDocDir.path}/adhd_q${_currentQuestionIndex}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _cameraController!.startVideoRecording();
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
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_isRecording) return;

    try {
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _questionVideos[_currentQuestionIndex] = videoFile.path;
      });

      _addUserMessage("✓ Video recorded");
      
      // Move to next question after short delay
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _currentQuestionIndex++;
      });
      _askNextQuestion();
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _completeScreening() async {
    _addSystemMessage("Thank you for your responses! Processing your screening results...");
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Prepare questionnaire data for behavior model
      // Map answers to feature format (simplified - would need proper mapping)
      Map<String, dynamic> questionnaireData = {};
      for (var entry in widget.questionnaireAnswers.entries) {
        questionnaireData['q${entry.key}'] = entry.value;
      }
      for (var entry in _questionAnswers.entries) {
        questionnaireData['adhd_q${entry.key}'] = entry.value;
      }

      // Collect video files
      File? videoFile;
      if (_questionVideos.isNotEmpty) {
        // Use the first video for now (in full implementation, would combine or use all)
        final firstVideoPath = _questionVideos.values.firstWhere((path) => path != null, orElse: () => null);
        if (firstVideoPath != null) {
          videoFile = File(firstVideoPath);
        }
      }

      // Call ADHD-specific screening endpoint
      final result = await _modelService.screenADHD(
        questionnaireData: questionnaireData,
        videoFile: videoFile,
      );

      if (result['success'] == true) {
        // Navigate to ADHD result screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ADHDResultScreen(
              screeningResult: result['fused_result'],
              individualResults: result['individual_results'],
              modalitiesUsed: result['modalities_used'],
            ),
          ),
        );
      } else {
        throw Exception('Screening failed');
      }
    } catch (e) {
      _addSystemMessage("Error processing screening: $e");
      setState(() {
        _isProcessing = false;
      });
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
    final showVideoControls = currentQuestion != null &&
        currentQuestion.requiresVideo &&
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Camera preview (if available and needed)
          if (showVideoControls && !_isRecording)
            Container(
              height: 150,
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

          // Input area
          if (!_isProcessing && _currentQuestionIndex < _adhdQuestions.length)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Video recording button (if needed)
                  if (showVideoControls && !_isRecording)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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

                  // Stop recording button
                  if (_isRecording)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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

                  // Text input
                  if (!currentQuestion!.requiresVideo || !_cameraPermissionGranted)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: 'Type your answer...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
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

                  // Camera permission request button
                  if (currentQuestion.requiresVideo &&
                      !_cameraPermissionGranted &&
                      !_cameraPermissionRequested)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: _requestCameraPermission,
                        child: const Text('Allow Camera Access'),
                      ),
                    ),
                ],
              ),
            )
          else if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Center(child: CircularProgressIndicator()),
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
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isSystem ? Colors.white : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: message.isSystem
              ? Border.all(color: Colors.grey[300]!)
              : null,
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.black87,
            height: 1.4,
          ),
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
  final String category; // "inattention", "hyperactivity", "impulsivity"
  final bool requiresVideo;

  ADHDQuestion({
    required this.text,
    required this.category,
    this.requiresVideo = false,
  });
}

