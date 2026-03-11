import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/services/model_service.dart';
import 'package:mindful/results_screen.dart';
import 'package:mindful/face_detection.dart';

class AutismQuestionnaireScreen extends StatefulWidget {
  const AutismQuestionnaireScreen({super.key});

  @override
  State<AutismQuestionnaireScreen> createState() => _AutismQuestionnaireScreenState();
}

class _AutismQuestionnaireScreenState extends State<AutismQuestionnaireScreen> {
  final PageController _pageController = PageController();
  final ModelService _modelService = ModelService();

  int _currentQuestionIndex = 0;
  final Map<int, bool> _answers = {};
  bool _isSubmitting = false;

  final List<String> _questions = const [
    "Do you find it difficult to understand what others are feeling by looking at their faces?",
    "Do you often notice small sounds that other people do not notice?",
    "Do you usually focus more on the big picture rather than small details?",
    "Do you find it easy to do more than one thing at the same time?",
    "If you are interrupted, do you find it easy to quickly return to what you were doing?",
    "Do you find it easy to understand hidden meanings or read between the lines when someone is talking to you?",
    "Can you easily tell when the person you are talking to is getting bored?",
    "When you read a story, do you find it easy to imagine what the characters look like?",
    "Do you find social situations easy to handle?",
    "Are you fascinated by dates, numbers, or patterns?",
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _answerQuestion(bool answer) {
    setState(() {
      _answers[_currentQuestionIndex] = answer;
    });

    if (_currentQuestionIndex < _questions.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    } else {
      _submitQuestionnaire();
    }
  }

  List<int> _buildAnswersList() {
    final List<int> answers = [];
    for (int i = 0; i < _questions.length; i++) {
      answers.add(_answers[i] == true ? 1 : 0);
    }
    return answers;
  }

  // ─── Submission logic (UNCHANGED) ─────────────────────────────────────

  Future<void> _submitQuestionnaire() async {
    if (_answers.length != _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final answers = _buildAnswersList();
      final response = await _modelService.predictASDText(answers);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final predictionObj = (response['prediction'] is Map<String, dynamic>)
          ? (response['prediction'] as Map<String, dynamic>)
          : response;

      final String label = (predictionObj['prediction'] ?? '').toString();
      final double confidence = (predictionObj['confidence'] is num)
          ? (predictionObj['confidence'] as num).toDouble()
          : 0.0;

      final double threshold = (predictionObj['threshold'] is num)
          ? (predictionObj['threshold'] as num).toDouble()
          : 0.80;

      final bool isAutism = label.toLowerCase() == 'autism' && confidence >= threshold;

      if (isAutism) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const EmotionDetectionScreen(isAutismScreening: true),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              screeningResult: {
                'detected_condition': null,
                'confidence': confidence,
                'message':
                    'Based on your answers, the screening indicates Non-Autism.\n\n'
                    'This is a screening tool, not a medical diagnosis. '
                    'Please consult a healthcare professional for proper evaluation.',
                'model_type': 'ASD Text Model (AQ-10)',
              },
            ),
          ),
        );
      }
    } on SocketException {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorDialog(
        'Connection Error',
        "Couldn't connect to the AI server.\n\n"
        "Check:\n"
        "• Backend server is running\n"
        "• Correct base URL\n"
        "• Same Wi-Fi (if physical phone)\n",
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorDialog(
        'Request Timeout',
        'The request took too long.\n\n'
        'Try:\n'
        '• Check base URL / network\n'
        '• Restart backend\n'
        '• Try again\n',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorDialog(
        'Error Processing Questionnaire',
        'Error:\n${e.toString()}',
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(message, style: GoogleFonts.inter())),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitQuestionnaire();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ─── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final percent = (progress * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isSubmitting
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(AppColors.primaryPurple),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Processing your answers...',
                      style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_currentQuestionIndex > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Step 1 of 4',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Title ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Autism Screening - Questionnaire',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Step 1 of 4: Answer these questions honestly',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Progress bar ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                            ),
                            Text(
                              '$percent%',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryPurple),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Questions ──
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) => setState(() => _currentQuestionIndex = index),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) => _buildQuestionPage(index),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    final question = _questions[index];
    final currentAnswer = _answers[index];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question ${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  question,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Yes/No cards — side-by-side
          Row(
            children: [
              Expanded(
                child: _buildAnswerCard(true, 'Yes', currentAnswer == true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnswerCard(false, 'No', currentAnswer == false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(bool value, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _answerQuestion(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple.withValues(alpha: 0.06) : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : Colors.grey[300]!,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            // Radio circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryPurple : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primaryPurple : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryPurple : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
