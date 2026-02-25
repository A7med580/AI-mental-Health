import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/screens/adhd_chat_screen.dart';
import 'package:mindful/screens/autism_questionnaire_screen.dart';

/// Initial screening questionnaire to determine which condition to screen for
/// This is a general, non-diagnostic questionnaire that estimates prior probabilities
class InitialQuestionnaireScreen extends StatefulWidget {
  const InitialQuestionnaireScreen({Key? key}) : super(key: key);

  @override
  State<InitialQuestionnaireScreen> createState() => _InitialQuestionnaireScreenState();
}

class _InitialQuestionnaireScreenState extends State<InitialQuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  final Map<int, int> _answers = {}; // question_index -> answer (0-4 scale)

  // General screening questions (neutral, non-diagnostic)
  // Triage Screening Questions
  // Q1-Q3: ADHD
  // Q4-Q6: Autism
  // Q7: Impact (Optional/Severity)
  final List<Map<String, dynamic>> _questions = [
    // --- ADHD Section ---
    {
      "text": "How often do you find it difficult to focus on tasks that require sustained attention?",
      "category": "adhd"
    },
    {
      "text": "How often do you feel restless or have difficulty sitting still for extended periods?",
      "category": "adhd"
    },
    {
      "text": "How often do you have trouble organizing tasks and activities?",
      "category": "adhd"
    },

    // --- Autism Section ---
    {
      "text": "How often do you feel overwhelmed in social situations?",
      "category": "autism"
    },
    {
      "text": "How often do you have difficulty understanding social cues or maintaining conversations?",
      "category": "autism"
    },
    {
      "text": "How often do you feel the need to adhere to strict routines or rituals?",
      "category": "autism"
    },

    // --- Impact Section (Optional/Last) ---
    {
      "text": "How often do these difficulties interfere with your daily life (work, school, relationships)?",
      "category": "impact"
    },
  ];

  // Likert options with color coding (matching Figma)
  final List<Map<String, dynamic>> _likertOptions = [
    {'label': 'Never', 'value': 0, 'color': AppColors.likertNever},
    {'label': 'Rarely', 'value': 1, 'color': AppColors.likertRarely},
    {'label': 'Sometimes', 'value': 2, 'color': AppColors.likertSometimes},
    {'label': 'Often', 'value': 3, 'color': AppColors.likertOften},
    {'label': 'Very Often', 'value': 4, 'color': AppColors.likertVeryOften},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _answerQuestion(int answer) {
    setState(() {
      _answers[_currentQuestionIndex] = answer;
    });
  }

  void _goToNextQuestion() {
    if (_answers[_currentQuestionIndex] == null) return;

    if (_currentQuestionIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _calculateProbabilities();
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRIAGE ROUTING LOGIC — COMPLETELY UNCHANGED FROM ORIGINAL
  // ═══════════════════════════════════════════════════════════════════════════

  void _calculateProbabilities() {
    int _toBinary(int index) {
      final val = _answers[index] ?? 0;
      return val >= 2 ? 1 : 0;
    }

    // Q1-Q3 (Indices 0, 1, 2) -> ADHD
    final int adhdScore = _toBinary(0) + _toBinary(1) + _toBinary(2);

    // Q4-Q6 (Indices 3, 4, 5) -> Autism
    final int autismScore = _toBinary(3) + _toBinary(4) + _toBinary(5);

    print('Routing Logic: ADHD Score = $adhdScore, Autism Score = $autismScore');

    bool navigateToAutism = false;

    if (autismScore > adhdScore) {
      navigateToAutism = true;
    } else if (adhdScore > autismScore) {
      navigateToAutism = false;
    } else {
      final int q5Raw = _answers[4] ?? 0;
      final int q6Raw = _answers[5] ?? 0;

      int maxAll = 0;
      for (int i = 0; i < 6; i++) {
        int val = _answers[i] ?? 0;
        if (val > maxAll) maxAll = val;
      }

      if (q5Raw == maxAll || q6Raw == maxAll) {
        navigateToAutism = true;
      } else {
        navigateToAutism = false;
      }
    }

    // Execute Navigation
    if (navigateToAutism) {
      print('Route Decision: Autism');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AutismQuestionnaireScreen()),
      );
    } else {
      print('Route Decision: ADHD');
      final double normalizedProb = adhdScore > 0 ? (adhdScore / 3.0) : 0.0;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ADHDChatScreen(
            initialProbability: normalizedProb,
            questionnaireAnswers: _answers,
          ),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI — REDESIGNED TO MATCH FIGMA
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Triage Questionnaire',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: AppColors.cardWhite,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / _questions.length,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Questions
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentQuestionIndex = index;
                });
              },
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return _buildQuestionPage(index);
              },
            ),
          ),

          // Bottom: Back + Next + Disclaimer
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    final question = _questions[index];
    final currentAnswer = _answers[index];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            question["text"] as String,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          // Likert options with color dots and radio buttons
          ..._likertOptions.map((option) {
            final value = option['value'] as int;
            final label = option['label'] as String;
            final color = option['color'] as Color;
            final isSelected = currentAnswer == value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildLikertOption(value, label, color, isSelected),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLikertOption(int value, String label, Color dotColor, bool isSelected) {
    return GestureDetector(
      onTap: () => _answerQuestion(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple.withValues(alpha: 0.05) : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Label
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Color dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Radio circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryPurple : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final hasAnswer = _answers[_currentQuestionIndex] != null;
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      color: AppColors.cardWhite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back + Next buttons
          Row(
            children: [
              // Back button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goToPreviousQuestion,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Next / Submit button (gradient)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: hasAnswer ? AppColors.primaryGradient : null,
                    color: hasAnswer ? null : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: hasAnswer ? _goToNextQuestion : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastQuestion ? 'Submit' : 'Next Question',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: hasAnswer ? Colors.white : Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: hasAnswer ? Colors.white : Colors.grey[500],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Note: This screening tool is not a diagnostic instrument. Results should be discussed with a qualified healthcare professional.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
