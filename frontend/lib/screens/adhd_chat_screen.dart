import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/services/video_storage_service.dart';

import 'package:mindful/screens/video_preview_screen.dart';
import 'package:mindful/screens/processing_screen.dart';
import 'package:mindful/widgets/glass_container.dart';
import 'package:mindful/widgets/page_transitions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

/// ADHD-specific chat interview screen
class ADHDChatScreen extends StatefulWidget {
  final Map<int, String> questionnaireAnswers;

  const ADHDChatScreen({
    Key? key,
    required this.questionnaireAnswers,
  }) : super(key: key);

  @override
  State<ADHDChatScreen> createState() => _ADHDChatScreenState();
}

class _ADHDChatScreenState extends State<ADHDChatScreen> with TickerProviderStateMixin {
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

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _initializeChat();
    _precheckPermissions();
  }

  // ─── Logic ──────────────────────────────────────────────────────────

  Future<void> _initializeChat() async {
    _addSystemMessage(
      "Hello! I'm here to help you understand patterns related to attention and focus. "
      "This is a screening tool, not a medical diagnosis. "
      "I'll ask you some questions - please answer honestly and take your time.",
    );

    await Future.delayed(const Duration(milliseconds: 400));
    _askNextQuestion();
  }

  Future<void> _precheckPermissions() async {
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;

    setState(() {
      _cameraPermissionGranted = cam.isGranted;
      _microphonePermissionGranted = mic.isGranted;
    });

    if (_cameraPermissionGranted) {
      await _initCameraController();
    }
  }

  Future<void> _requestCameraAndMicPermission() async {
    if (_cameraPermissionRequested) return;

    setState(() {
      _cameraPermissionRequested = true;
    });

    try {
      final micStatus = await Permission.microphone.request();
      setState(() => _microphonePermissionGranted = micStatus.isGranted);

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
    await _cameraController?.dispose();
    _cameraController = null;

    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception("No cameras found");

    final front = cameras.where((c) => c.lensDirection == CameraLensDirection.front).toList();
    final selected = front.isNotEmpty ? front.first : cameras.first;

    final controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    await controller.initialize();
    _cameraController = controller;

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

    if (question.requiresVideo && !_cameraPermissionGranted) {
      if (!_cameraPermissionRequested) {
        _addSystemMessage(
          "For the next question, it would be helpful to record a short video response. "
          "Tap the button below to allow camera access (you can still continue with text if you prefer).",
        );
      } else {
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
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String _ = '${appDocDir.path}/adhd_q${_currentQuestionIndex}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await controller.startVideoRecording();

      setState(() {
        _isRecording = true;
      });

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

      Navigator.push(
        context,
        AppPageRoute(
          page: VideoPreviewScreen(
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

      final recorded = _questionVideos.entries
          .where((e) => e.value != null)
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      if (recorded.isEmpty) {
        _addSystemMessage(
          "No video recorded. We'll continue with text-only screening.",
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            page: ProcessingScreen(
              videoFile: null,
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
        AppPageRoute(
          page: ProcessingScreen(
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
    _pulseController.dispose();
    super.dispose();
  }

  // ─── UI (Liquid Glass Design) ──────────────────────────────────────

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0EEFF),
              Color(0xFFE8E0FF),
              Color(0xFFF5F0FF),
              Color(0xFFEDE5FF),
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI Interview',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentQuestionIndex + 1}/${_adhdQuestions.length}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Messages ──
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                ),
              ),

              // ── Camera preview ──
              if (showVideoControls)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(_cameraController!),
                                // Recording indicator
                                if (_isRecording)
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (_, __) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Transform.scale(
                                              scale: _pulseAnimation.value,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text('REC', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Record / Stop button
                        SizedBox(
                          width: double.infinity,
                          child: _isRecording
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: _stopVideoRecording,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.stop, color: Colors.white, size: 18),
                                            const SizedBox(width: 8),
                                            Text('Stop Recording', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryPurple.withValues(alpha: 0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: _startVideoRecording,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.videocam, color: Colors.white, size: 18),
                                            const SizedBox(width: 8),
                                            Text('Record Video Response', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Input area ──
              if (!_isProcessing && currentQuestion != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Permission button
                        if (needsVideo && !_cameraPermissionGranted && !_cameraPermissionRequested)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: _requestCameraAndMicPermission,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.lock_open, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text('Allow Camera & Microphone', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Multimodal info
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.psychology, size: 14, color: AppColors.primaryPurple),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Multimodal: text + video + audio analysis',
                                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Text input
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                                ),
                                child: TextField(
                                  controller: _textController,
                                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Type your response...',
                                    hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  onSubmitted: _submitTextAnswer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _submitTextAnswer(_textController.text),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPurple.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.send, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else if (_isProcessing)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation(AppColors.primaryPurple),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Preparing screening...', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isSystem = message.isSystem;

    return Align(
      alignment: isSystem ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSystem
              ? Colors.white.withValues(alpha: 0.55)
              : AppColors.primaryPurple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: isSystem ? const Radius.circular(4) : const Radius.circular(16),
            bottomRight: isSystem ? const Radius.circular(16) : const Radius.circular(4),
          ),
          border: Border.all(
            color: isSystem
                ? Colors.white.withValues(alpha: 0.6)
                : AppColors.primaryPurple.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isSystem ? AppColors.textPrimary : AppColors.textPrimary,
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
  final String? videoPath;

  ChatMessage({required this.text, required this.isSystem, required this.timestamp, this.videoPath});
}

class ADHDQuestion {
  final String text;
  final String category;
  final bool requiresVideo;

  ADHDQuestion({required this.text, required this.category, required this.requiresVideo});
}
