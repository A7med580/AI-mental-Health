import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/theme/module_themes.dart';
import 'package:mindful/services/model_service.dart';
import 'package:mindful/results_screen.dart';
import 'package:mindful/face_detection.dart';
import 'package:mindful/widgets/animated_scale_button.dart';

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
    "Is it hard for you to know how people feel from their faces?",
    "Do you hear small sounds that others miss?",
    "Do you look at the big picture instead of small details?",
    "Is it easy for you to do many things at once?",
    "When someone stops you, is it easy to go back to work?",
    "Can you understand hidden hints when people talk?",
    "Can you tell if someone is getting bored?",
    "Can you easily picture characters in a book?",
    "Are social times easy for you?",
    "Do you love dates, numbers, or patterns?",
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
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
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

      final predictionObj = (response['prediction'] is Map)
          ? Map<String, dynamic>.from(response['prediction'] as Map)
          : Map<String, dynamic>.from(response);

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
                    'This does not diagnose you. Please see a doctor.',
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
        "Could not connect. Please check your network.",
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorDialog(
        'Request Timeout',
        "It took too long. Please try again.",
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
      backgroundColor: asdTheme.backgroundColor,
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
                      'Processing answers...',
                      style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_currentQuestionIndex > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOutCubic,
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
                              border: Border.all(color: const Color(0xFFE8E4DF)),
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
                        Row(
                          children: [
                            Icon(asdTheme.icon, size: 22, color: asdTheme.accentColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Autism Questions',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Step 1 of 4: Answer honestly',
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
                              '${_currentQuestionIndex + 1} / ${_questions.length}',
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
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
    return AnimatedScaleButton(
      onPressed: () => _answerQuestion(value),
      shrinkScale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: isSelected ? asdTheme.accentColor.withValues(alpha: 0.06) : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? asdTheme.accentColor : const Color(0xFFE8E4DF),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: asdTheme.accentColor.withValues(alpha: 0.12),
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
                color: isSelected ? asdTheme.accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? asdTheme.accentColor : Colors.grey[400]!,
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
                color: isSelected ? asdTheme.accentColor : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
