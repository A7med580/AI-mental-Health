<<<<<<< HEAD
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/screens/processing_screen.dart';
import 'package:mindful/widgets/glass_container.dart';
import 'package:mindful/widgets/page_transitions.dart';

/// Depression-specific chat interview screen.
/// Questions are PHQ-9 / DSM-5 Major Depressive Episode aligned.
=======
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

/// Depression-specific chat interview screen.
/// DAIC-WOZ aligned clinical interview with video recording capabilities.
/// Questions elicit affect, energy, sleep, interest, and concentration signals
/// that the PHQ-8 model expects from the DAIC-WOZ dataset.
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
class DepressionQuestionnaireScreen extends StatefulWidget {
  final Map<int, String> questionnaireAnswers;

  const DepressionQuestionnaireScreen({
    Key? key,
    required this.questionnaireAnswers,
  }) : super(key: key);

  @override
  State<DepressionQuestionnaireScreen> createState() =>
      _DepressionQuestionnaireScreenState();
}

class _DepressionQuestionnaireScreenState
    extends State<DepressionQuestionnaireScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

<<<<<<< HEAD
  final List<ChatMessage> _messages = [];
  int _currentQuestionIndex = 0;
  bool _isProcessing = false;

  final Map<int, String> _questionAnswers = {};

  // PHQ-9 / DSM-5 Major Depressive Episode aligned questions
  final List<String> _questions = [
    "Over the past two weeks, how often have you felt little interest or pleasure in things you usually enjoy?",
    "Have you been feeling down, hopeless, or empty recently? Can you describe what that's been like for you?",
    "Have you noticed changes in your sleep — either sleeping much more than usual, or struggling to sleep at all?",
    "How has your energy been? Do you often feel fatigued or that even small tasks feel exhausting?",
    "Has your appetite changed recently — eating significantly more or less than usual?",
    "Have you been feeling bad about yourself — like you've let people down, or that you're a failure in some way?",
    "Have you found it harder than usual to concentrate on things like reading, watching TV, or making decisions?",
    "Have you ever had thoughts that life isn't worth living, or that you'd be better off not being here?",
=======
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

  // DAIC-WOZ aligned clinical interview questions
  final List<DepressionQuestion> _depressionQuestions = [
    DepressionQuestion(
      text:
          "How have you been feeling lately? Can you describe your general mood over the past few weeks?",
      category: "affect",
      requiresVideo: true,
    ),
    DepressionQuestion(
      text:
          "Over the past two weeks, how often have you had little interest or pleasure in doing things you usually enjoy?",
      category: "interest",
      requiresVideo: false,
    ),
    DepressionQuestion(
      text:
          "Have you been feeling down, hopeless, or empty recently? Can you describe what that's been like for you?",
      category: "mood",
      requiresVideo: true,
    ),
    DepressionQuestion(
      text:
          "Have you noticed changes in your sleep — sleeping much more than usual, or struggling to sleep?",
      category: "sleep",
      requiresVideo: false,
    ),
    DepressionQuestion(
      text:
          "How has your energy been? Do you often feel fatigued or that even small tasks feel exhausting?",
      category: "energy",
      requiresVideo: false,
    ),
    DepressionQuestion(
      text:
          "Have you been feeling bad about yourself — like you've let people down, or that you're a failure?",
      category: "self-worth",
      requiresVideo: false,
    ),
    DepressionQuestion(
      text:
          "Have you found it harder than usual to concentrate on things like reading, watching TV, or making decisions?",
      category: "concentration",
      requiresVideo: false,
    ),
    DepressionQuestion(
      text:
          "Is there anything else you'd like to share about how you've been feeling?",
      category: "open",
      requiresVideo: true,
    ),
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
<<<<<<< HEAD
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    _addSystemMessage(
      "Hi, I'm here with you. Based on your earlier responses, I'd like to ask you a few more questions about how you've been feeling lately.\n\n"
      "There are no right or wrong answers — just share what feels true for you. This is a confidential screening tool, not a medical diagnosis.",
    );
=======
    _precheckPermissions();
  }

  // ─── LOGIC ──────────────────────────────────────────────────────────────

  Future<void> _initializeChat() async {
    _addSystemMessage(
      "Hi, I'm here with you. Based on your earlier responses, I'd like "
      "to understand more about how you've been feeling lately.\n\n"
      "There are no right or wrong answers — just share what feels true for you. "
      "Some questions will ask you to record a short video so we can better "
      "understand your experience. This is a confidential screening tool, not a medical diagnosis.",
    );

>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
    await Future.delayed(const Duration(milliseconds: 500));
    _askNextQuestion();
  }

<<<<<<< HEAD
  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isSystem: true, timestamp: DateTime.now()));
=======
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

      _addSystemMessage(
          "Camera access granted. You can now record your response.");
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

    final front = cameras
        .where((c) => c.lensDirection == CameraLensDirection.front)
        .toList();
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
      _cameraPermissionGranted =
          cam.isGranted || controller.value.isInitialized;
    });
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(
          ChatMessage(text: text, isSystem: true, timestamp: DateTime.now()));
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
<<<<<<< HEAD
      _messages.add(ChatMessage(text: text, isSystem: false, timestamp: DateTime.now()));
=======
      _messages.add(
          ChatMessage(text: text, isSystem: false, timestamp: DateTime.now()));
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
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
<<<<<<< HEAD
    if (_currentQuestionIndex >= _questions.length) {
      _completeScreening();
      return;
    }
    _addSystemMessage(_questions[_currentQuestionIndex]);
=======
    if (_currentQuestionIndex >= _depressionQuestions.length) {
      _completeScreening();
      return;
    }

    final question = _depressionQuestions[_currentQuestionIndex];

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
        "Please record a short video (30–60 seconds). Speak naturally and be yourself.",
      );
    }
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
  }

  Future<void> _submitTextAnswer(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    _addUserMessage(cleaned);
    _questionAnswers[_currentQuestionIndex] = cleaned;
    _textController.clear();

<<<<<<< HEAD
    setState(() => _currentQuestionIndex++);
=======
    setState(() {
      _currentQuestionIndex++;
    });
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad

    await Future.delayed(const Duration(milliseconds: 300));
    _askNextQuestion();
  }

<<<<<<< HEAD
  Future<void> _completeScreening() async {
    setState(() => _isProcessing = true);
    _addSystemMessage("Thank you for sharing that. Preparing your report now...");
=======
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
      final String _ =
          '${appDocDir.path}/depression_q${_currentQuestionIndex}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await controller.startVideoRecording();

      setState(() {
        _isRecording = true;
      });

      // Auto stop after 60 seconds
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
        customName:
            'depression_q${_currentQuestionIndex}_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      final savedFile = File(savedPath);
      if (!await savedFile.exists()) {
        throw Exception('Failed to save video file');
      }
      if (await savedFile.length() < 2000) {
        throw Exception('Video file is too small / empty');
      }

      setState(() {
        _questionVideos[_currentQuestionIndex] = savedPath;
      });

      if (!mounted) return;

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
              setState(
                  () => _questionVideos[_currentQuestionIndex] = null);
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
    _addSystemMessage(
        "Thank you for sharing that. Preparing your report now...");

    setState(() => _isProcessing = true);
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad

    try {
      final Map<String, dynamic> questionnaireData = {
        'condition': 'depression',
      };

      for (final entry in widget.questionnaireAnswers.entries) {
        questionnaireData['initial_q_${entry.key}'] = entry.value;
      }

      for (final entry in _questionAnswers.entries) {
<<<<<<< HEAD
        questionnaireData['depression_q_${entry.key}'] = entry.value;
=======
        questionnaireData['depression_q_${entry.key}_text'] = entry.value;
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
      if (!await videoFile.exists()) {
        throw Exception("Video file not found");
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        AppPageRoute(
          page: ProcessingScreen(
<<<<<<< HEAD
            videoFile: null,
=======
            videoFile: videoFile,
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
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
<<<<<<< HEAD
  Widget build(BuildContext context) {
    final bool onLastQuestion = _currentQuestionIndex >= _questions.length;
=======
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _currentQuestionIndex < _depressionQuestions.length
        ? _depressionQuestions[_currentQuestionIndex]
        : null;

    final needsVideo =
        currentQuestion != null && currentQuestion.requiresVideo;

    final showVideoControls = needsVideo &&
        _cameraPermissionGranted &&
        _cameraController != null &&
        _cameraController!.value.isInitialized;
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEEF0FF),
              Color(0xFFE3E8FF),
              Color(0xFFF2EEFF),
              Color(0xFFE8E3FF),
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
<<<<<<< HEAD
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
=======
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
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
<<<<<<< HEAD
                          child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
=======
                          child: const Icon(Icons.arrow_back,
                              size: 20, color: AppColors.textPrimary),
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Depression Screening',
<<<<<<< HEAD
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'PHQ-9 / DSM-5 Aligned',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
=======
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                            Text(
                              'DAIC-WOZ Clinical Interview',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
                            ),
                          ],
                        ),
                      ),
                      Container(
<<<<<<< HEAD
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
=======
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
<<<<<<< HEAD
                          '${(_currentQuestionIndex + 1).clamp(1, _questions.length)}/${_questions.length}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
=======
                          '${(_currentQuestionIndex + 1).clamp(1, _depressionQuestions.length)}/${_depressionQuestions.length}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
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
<<<<<<< HEAD
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                ),
              ),

              // ── Input / Processing ──
              if (_isProcessing)
=======
                  itemBuilder: (context, index) =>
                      _buildMessageBubble(_messages[index]),
                ),
              ),

              // ── Camera preview ──
              if (showVideoControls && !_isRecording)
                Container(
                  height: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primaryPurple.withValues(alpha: 0.3),
                        width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CameraPreview(_cameraController!),
                  ),
                ),

              // ── Multimodal info bar ──
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.primaryPurple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Multimodal Assessment: Video, voice, and text analysis for comprehensive depression screening.',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
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
                        if (needsVideo &&
                            !_cameraPermissionGranted &&
                            !_cameraPermissionRequested)
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.lock_open,
                                              color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Allow Camera & Microphone',
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Video record button
                        if (showVideoControls && !_isRecording)
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
                                    onTap: _startVideoRecording,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.videocam,
                                              color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Record Video Response',
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Stop recording button
                        if (_isRecording)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _stopVideoRecording,
                                icon: const Icon(Icons.stop, size: 18),
                                label: Text('Stop Recording',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),

                        // Empathy note
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_border,
                                  size: 14,
                                  color: AppColors.primaryPurple),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Your answers are confidential — be honest with yourself',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500),
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
                                  color:
                                      Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.6)),
                                ),
                                child: TextField(
                                  controller: _textController,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Share your thoughts...',
                                    hintStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.textSecondary),
                                    border: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                  ),
                                  onSubmitted: _submitTextAnswer,
                                  maxLines: null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  _submitTextAnswer(_textController.text),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPurple
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.send,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else if (_isProcessing)
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
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
<<<<<<< HEAD
                            valueColor: AlwaysStoppedAnimation(AppColors.primaryPurple),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Preparing your report...', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else if (!onLastQuestion)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Empathy note
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_border, size: 14, color: AppColors.primaryPurple),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Your answers are confidential — be honest with yourself',
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
                                    hintText: 'Share your thoughts...',
                                    hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  onSubmitted: _submitTextAnswer,
                                  maxLines: null,
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
=======
                            valueColor: AlwaysStoppedAnimation(
                                AppColors.primaryPurple),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Preparing your report...',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary)),
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
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
<<<<<<< HEAD
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
=======
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSystem
              ? Colors.white.withValues(alpha: 0.55)
              : AppColors.primaryPurple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16).copyWith(
<<<<<<< HEAD
            bottomLeft: isSystem ? const Radius.circular(4) : const Radius.circular(16),
            bottomRight: isSystem ? const Radius.circular(16) : const Radius.circular(4),
=======
            bottomLeft: isSystem
                ? const Radius.circular(4)
                : const Radius.circular(16),
            bottomRight: isSystem
                ? const Radius.circular(16)
                : const Radius.circular(4),
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
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
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ─── Data models ─────────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isSystem;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isSystem,
    required this.timestamp,
  });
}
<<<<<<< HEAD
=======

class DepressionQuestion {
  final String text;
  final String category;
  final bool requiresVideo;

  const DepressionQuestion({
    required this.text,
    required this.category,
    this.requiresVideo = false,
  });
}
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
