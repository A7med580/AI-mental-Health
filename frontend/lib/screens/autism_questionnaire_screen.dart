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
  final Map<int, bool> _answers = {}; // question_index -> answer (true = Yes, false = No)
  bool _isSubmitting = false;

  final List<String> _questions = const [
    "Do you often notice small sounds that other people do not notice?",
    "Do you usually focus more on the big picture rather than small details?",
    "Do you find it easy to do more than one thing at the same time?",
    "If you are interrupted, do you find it easy to quickly return to what you were doing?",
    "Do you find it easy to understand hidden meanings or read between the lines when someone is talking to you?",
    "Can you easily tell when the person you are talking to is getting bored?",
    "When you read a story, do you find it easy to imagine what the characters look like?",
    "Do you find it easy to understand what someone is thinking or feeling just by looking at their face?",
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

      // Expected backend response:
      // { "success": true, "prediction": { "prediction": "Autism"/"Non-Autism", "confidence": 0.xx, ... } }
      final predictionObj = (response['prediction'] is Map<String, dynamic>)
          ? (response['prediction'] as Map<String, dynamic>)
          : response;

      final String label = (predictionObj['prediction'] ?? '').toString();
      final double confidence = (predictionObj['confidence'] is num)
          ? (predictionObj['confidence'] as num).toDouble()
          : 0.0;

      // Use backend threshold if present, otherwise 0.80 (your config)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Autism Screening',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing your answers...'),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_currentQuestionIndex + 1) / _questions.length,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_currentQuestionIndex + 1}/${_questions.length}',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
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
    );
  }

  Widget _buildQuestionPage(int index) {
    final question = _questions[index];
    final currentAnswer = _answers[index];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            question,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 60),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnswerOption(true, "Yes", currentAnswer == true),
                const SizedBox(height: 16),
                _buildAnswerOption(false, "No", currentAnswer == false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(bool value, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _answerQuestion(value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!, width: 2),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
