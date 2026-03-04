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
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
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
    await Future.delayed(const Duration(milliseconds: 500));
    _askNextQuestion();
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
    if (_currentQuestionIndex >= _questions.length) {
      _completeScreening();
      return;
    }
    _addSystemMessage(_questions[_currentQuestionIndex]);
  }

  Future<void> _submitTextAnswer(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    _addUserMessage(cleaned);
    _questionAnswers[_currentQuestionIndex] = cleaned;
    _textController.clear();

    setState(() => _currentQuestionIndex++);

    await Future.delayed(const Duration(milliseconds: 300));
    _askNextQuestion();
  }

  Future<void> _completeScreening() async {
    setState(() => _isProcessing = true);
    _addSystemMessage("Thank you for sharing that. Preparing your report now...");

    try {
      final Map<String, dynamic> questionnaireData = {
        'condition': 'depression',
      };

      for (final entry in widget.questionnaireAnswers.entries) {
        questionnaireData['initial_q_${entry.key}'] = entry.value;
      }

      for (final entry in _questionAnswers.entries) {
        questionnaireData['depression_q_${entry.key}'] = entry.value;
      }

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
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool onLastQuestion = _currentQuestionIndex >= _questions.length;

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Depression Screening',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'PHQ-9 / DSM-5 Aligned',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(_currentQuestionIndex + 1).clamp(1, _questions.length)}/${_questions.length}',
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

              // ── Input / Processing ──
              if (_isProcessing)
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
