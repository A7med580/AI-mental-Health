import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/theme/module_themes.dart';
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
  DateTime? _recordingStartTime;

  bool _cameraPermissionGranted = false;
  bool _microphonePermissionGranted = false;

  bool _cameraPermissionRequested = false;
  bool _isMicActive = false;

  final List<ChatMessage> _messages = [];
  int _currentQuestionIndex = 0;

  final Map<int, String> _questionAnswers = {};
  final Map<int, String?> _questionVideos = {};

  // DSM-5 aligned questions
  final List<ADHDQuestion> _adhdQuestions = [
    ADHDQuestion(
      text: "Is it hard to stay focused on long tasks?",
      category: "inattention",
      requiresVideo: false,
    ),
    ADHDQuestion(
      text: "Do you often make small mistakes because you lose focus?",
      category: "inattention",
      requiresVideo: false,
    ),
    ADHDQuestion(
      text: "Is it hard to organize your work or time?",
      category: "inattention",
      requiresVideo: false,
    ),
    ADHDQuestion(
      text: "Do you often feel like you can't sit still?",
      category: "hyperactivity",
      requiresVideo: true,
    ),
    ADHDQuestion(
      text: "Is it hard to wait for your turn?",
      category: "impulsivity",
      requiresVideo: true,
    ),
    ADHDQuestion(
      text: "Do you often talk over others or finish their words?",
      category: "impulsivity",
      requiresVideo: false,
    ),
    ADHDQuestion(
      text: "Do you often lose things like keys or your phone?",
      category: "inattention",
      requiresVideo: false,
    ),
    ADHDQuestion(
      text: "Does your mind often have too many thoughts?",
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

  // ─── ALL LOGIC BELOW IS UNCHANGED ───────────────────────────────────

  Future<void> _initializeChat() async {
    _addSystemMessage(
      "Check your focus. Answer 8 questions. This is not a diagnosis.",
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

      _addSystemMessage("Camera ready. You can use video now.");
      await Future.delayed(const Duration(milliseconds: 200));
      _askNextQuestion();
    } catch (e) {
      if (!mounted) return;

      _addSystemMessage("No camera found. Using text only.");

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
          "This question needs video. Allow camera or use text.",
        );
      } else {
        _addSystemMessage(question.text);
        _addSystemMessage("Use text. No camera found.");
      }
      return;
    }

    _addSystemMessage(question.text);

    if (question.requiresVideo) {
      _addSystemMessage("Record a short video (15-60 seconds).");
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

    setState(() {
      _isRecording = true;
      _recordingStartTime = DateTime.now();
    });

    try {
      await controller.startVideoRecording();

      // Auto stop after 60 seconds
      Future.delayed(const Duration(seconds: 60), () {
        if (mounted && _isRecording) {
          _stopVideoRecording();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingStartTime = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_isRecording) return;

    final controller = _cameraController;
    if (controller == null || !controller.value.isRecordingVideo) return;

    try {
      // Ensure minimum recording duration of 1.5 seconds to avoid AVAssetWriter errors
      if (_recordingStartTime != null) {
        final elapsed = DateTime.now().difference(_recordingStartTime!);
        if (elapsed.inMilliseconds < 1500) {
          await Future.delayed(
              Duration(milliseconds: 1500 - elapsed.inMilliseconds));
        }
      }

      final XFile tempVideoFile = await controller.stopVideoRecording();

      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingStartTime = null;
        });
      }

      final savedPath = await VideoStorageService.saveVideo(
        File(tempVideoFile.path),
        customName: 'adhd_q${_currentQuestionIndex}_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      final savedFile = File(savedPath);
      if (!await savedFile.exists()) throw Exception('Failed to save video file');
      if (await savedFile.length() < 2000) throw Exception('Video file is too small / empty');

      if (mounted) {
        setState(() {
          _questionVideos[_currentQuestionIndex] = savedPath;
        });

        _addUserMessage("✓ Video recorded");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPreviewScreen(
              videoPath: savedPath,
              onRetake: () async {
                try {
                  await VideoStorageService.deleteVideo(savedPath);
                } catch (_) {}
                if (mounted) {
                  setState(() => _questionVideos[_currentQuestionIndex] = null);
                  Navigator.pop(context);
                }
              },
              onContinue: () {
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => _currentQuestionIndex++);
                  _askNextQuestion();
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingStartTime = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving video: $e')),
        );
      }
    }
  }

  Future<void> _completeScreening() async {
    _addSystemMessage("Done! Preparing your results...");

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
        _addSystemMessage("No video found. Using text only.");
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProcessingScreen(
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

  // ─── UI (NEW FIGMA DESIGN) ──────────────────────────────────────────

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
      backgroundColor: adhdTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(adhdTheme.icon, size: 20, color: adhdTheme.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Chat',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    '${_currentQuestionIndex + 1}/${_adhdQuestions.length}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            // ── Messages ──
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
              ),
            ),

            // ── Camera preview ──
            if (showVideoControls && !_isRecording)
              Container(
                height: 140,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CameraPreview(_cameraController!),
                ),
              ),

            // ── Multimodal info bar ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.primaryPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We use text, video, and audio for better results.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.primaryPurple, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // ── Input area ──
            if (!_isProcessing && currentQuestion != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
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
                              gradient: LinearGradient(colors: [adhdTheme.accentColor, const Color(0xFFD98C1A)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _requestCameraAndMicPermission,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.lock_open, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Allow Camera', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Video buttons
                    if (showVideoControls && !_isRecording)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [adhdTheme.accentColor, const Color(0xFFD98C1A)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _startVideoRecording,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.videocam, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Record Video', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (_isRecording)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _stopVideoRecording,
                            icon: const Icon(Icons.stop, size: 18),
                            label: Text('Stop', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),

                    // Text input
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFE8E4DF)),
                            ),
                            child: TextField(
                              controller: _textController,
                              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Type your answer...',
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
                          onTap: () {
                            if (!_microphonePermissionGranted) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required.')));
                               return;
                            }
                            setState(() {
                               _isMicActive = !_isMicActive;
                            });
                            if (!_isMicActive) {
                               _addUserMessage("✓ Voice recorded (00:05)");
                               setState(() => _currentQuestionIndex++);
                               Future.delayed(const Duration(milliseconds: 300), _askNextQuestion);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isMicActive ? Colors.red : AppColors.surfaceLight,
                              shape: BoxShape.circle,
                              boxShadow: _isMicActive ? [
                                BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 2)
                              ] : [],
                            ),
                            child: Icon(Icons.mic, color: _isMicActive ? Colors.white : AppColors.textSecondary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _submitTextAnswer(_textController.text),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [adhdTheme.accentColor, const Color(0xFFD98C1A)]),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else if (_isProcessing)
              Padding(
                padding: const EdgeInsets.all(16),
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
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isSystem ? Colors.grey[200] : AppColors.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isSystem ? const Radius.circular(4) : const Radius.circular(16),
            bottomRight: isSystem ? const Radius.circular(16) : const Radius.circular(4),
          ),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textPrimary,
            height: 1.5,
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
  final String category;
  final bool requiresVideo;

  ADHDQuestion({
    required this.text,
    required this.category,
    this.requiresVideo = false,
  });
}
