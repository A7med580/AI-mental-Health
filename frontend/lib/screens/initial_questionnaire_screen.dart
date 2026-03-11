import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/screens/adhd_chat_screen.dart';
import 'package:mindful/screens/autism_questionnaire_screen.dart';
import 'package:mindful/screens/depression_questionnaire_screen.dart';


import 'package:mindful/widgets/page_transitions.dart';

/// Initial triage questionnaire — 3 conditions, 11 questions.
/// Covers ADHD, Autism (ASD), and Depression (PHQ-9 based).
/// Routes user to the most probable condition's deep-dive screen.
class InitialQuestionnaireScreen extends StatefulWidget {
  const InitialQuestionnaireScreen({Key? key}) : super(key: key);

  @override
  State<InitialQuestionnaireScreen> createState() =>
      _InitialQuestionnaireScreenState();
}

class _InitialQuestionnaireScreenState
    extends State<InitialQuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  final Map<int, int> _answers = {}; // question_index -> answer (0–4 scale)

  // ─────────────────────────────────────────────────────────────────────────
  // QUESTION BANK  (11 questions total)
  //
  // Q0–Q2  : ADHD     (3 questions)
  // Q3–Q5  : Autism   (3 questions)
  // Q6–Q9  : Depression — adapted from PHQ-9 (public domain, Pfizer/Spitzer)
  //          4 highest-discriminative PHQ-9 items, reworded for Likert-5 UX
  // Q10    : Impact / severity (1 question)
  // ─────────────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _questions = [
    // ── ADHD ──────────────────────────────────────────────────────────────
    {
      "text":
          "How often do you find it difficult to focus on tasks that require sustained attention?",
      "category": "adhd",
    },
    {
      "text":
          "How often do you feel restless or have difficulty sitting still for extended periods?",
      "category": "adhd",
    },
    {
      "text": "How often do you have trouble organizing tasks and activities?",
      "category": "adhd",
    },

    // ── AUTISM (ASD) ───────────────────────────────────────────────────────
    {
      "text": "How often do you feel overwhelmed in social situations?",
      "category": "autism",
    },
    {
      "text":
          "How often do you have difficulty understanding social cues or maintaining conversations?",
      "category": "autism",
    },
    {
      "text":
          "How often do you feel the need to adhere to strict routines or rituals?",
      "category": "autism",
    },

    // ── DEPRESSION  (PHQ-9 — public domain, adapted to 5-point Likert) ────
    // Source: Kroenke, Spitzer & Williams (2001). PHQ-9 is in the public
    // domain; no permission required (Pfizer Inc. statement, 2023).
    // Original PHQ-9 uses 0–3 (Not at all → Nearly every day).
    // Adapted here to 0–4 (Never → Very Often) to match app's Likert scale.
    {
      "text":
          "Over the past two weeks, how often have you had little interest or pleasure in doing things you usually enjoy?",
      "category": "depression",
    },
    {
      "text":
          "Over the past two weeks, how often have you been feeling down, hopeless, or empty?",
      "category": "depression",
    },
    {
      "text":
          "Over the past two weeks, how often have you felt tired, low in energy, or had little motivation to start things?",
      "category": "depression",
    },
    {
      "text":
          "Over the past two weeks, how often have you had trouble concentrating on everyday activities such as reading or watching TV?",
      "category": "depression",
    },

    // ── IMPACT (cross-cutting severity) ───────────────────────────────────
    {
      "text":
          "How often do these difficulties interfere with your daily life (work, school, or relationships)?",
      "category": "impact",
    },
  ];

  // Likert options — unchanged from original design
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

  // ═════════════════════════════════════════════════════════════════════════
  // TRIAGE ROUTING LOGIC — 3-CONDITION PROBABILISTIC ROUTING
  //
  // Strategy:
  //   1. Convert each answer to binary (0 = Never/Rarely, 1 = Sometimes+).
  //   2. Sum binary scores per condition → raw signal score out of max items.
  //   3. Normalize to [0,1] probability estimate.
  //   4. Route to the condition with the highest probability.
  //   5. Tie-break: favor the condition whose individual answers were highest.
  // ═════════════════════════════════════════════════════════════════════════
  void _calculateProbabilities() {
    // Binary threshold: ≥2 (Sometimes) counts as a positive signal
    int _toBinary(int index) => (_answers[index] ?? 0) >= 2 ? 1 : 0;

    // Raw sum scores
    final int adhdScore =
        _toBinary(0) + _toBinary(1) + _toBinary(2); // max 3

    final int autismScore =
        _toBinary(3) + _toBinary(4) + _toBinary(5); // max 3

    final int depressionScore =
        _toBinary(6) + _toBinary(7) + _toBinary(8) + _toBinary(9); // max 4

    // Normalize scores to comparable [0,1] probabilities
    final double adhdProb = adhdScore / 3.0;
    final double autismProb = autismScore / 3.0;
    final double depressionProb = depressionScore / 4.0;

    print(
      'Triage Probabilities → '
      'ADHD: ${adhdProb.toStringAsFixed(2)}, '
      'Autism: ${autismProb.toStringAsFixed(2)}, '
      'Depression: ${depressionProb.toStringAsFixed(2)}',
    );

    // Find the winning condition
    final Map<String, double> probs = {
      'adhd': adhdProb,
      'autism': autismProb,
      'depression': depressionProb,
    };

    String winner = probs.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    // Tie-break: if multiple conditions share the max probability,
    // pick the one with the highest single raw answer value
    final double maxProb = probs[winner]!;
    final List<String> tied =
        probs.entries.where((e) => e.value == maxProb).map((e) => e.key).toList();

    if (tied.length > 1) {
      // Map each tied condition to its highest individual raw answer
      final Map<String, int> conditionIndices = {
        'adhd': _maxRawInRange(0, 2),
        'autism': _maxRawInRange(3, 5),
        'depression': _maxRawInRange(6, 9),
      };
      winner = tied.reduce(
        (a, b) => (conditionIndices[a] ?? 0) >= (conditionIndices[b] ?? 0)
            ? a
            : b,
      );
    }

    print('Route Decision: $winner');
    _navigate(winner);
  }

  /// Returns the highest raw answer value within a question index range (inclusive).
  int _maxRawInRange(int start, int end) {
    int maxVal = 0;
    for (int i = start; i <= end; i++) {
      final v = _answers[i] ?? 0;
      if (v > maxVal) maxVal = v;
    }
    return maxVal;
  }

  void _navigate(String condition) {
    final answersAsStrings =
        _answers.map((k, v) => MapEntry(k, v.toString()));

    switch (condition) {
      case 'autism':
        Navigator.pushReplacement(
          context,
          AppPageRoute(page: const AutismQuestionnaireScreen()),
        );
        break;

      case 'depression':
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            page: DepressionQuestionnaireScreen(
              questionnaireAnswers: answersAsStrings,
            ),
          ),
        );
        break;



      case 'adhd':
      default:
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            page: ADHDChatScreen(
              questionnaireAnswers: _answers,
              initialProbability: 0.5,
            ),
          ),
        );
        break;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // UI — Unchanged from original design
  // ═════════════════════════════════════════════════════════════════════════

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
          // Progress bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: AppColors.cardWhite,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          (_currentQuestionIndex + 1) / _questions.length,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryPurple),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Question pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) =>
                  setState(() => _currentQuestionIndex = index),
              itemCount: _questions.length,
              itemBuilder: (context, index) => _buildQuestionPage(index),
            ),
          ),

          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    final question = _questions[index];
    final currentAnswer = _answers[index];

    // Category label shown above the question
    final String categoryLabel = _categoryLabel(question['category'] as String);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Category chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              categoryLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question['text'] as String,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
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

  String _categoryLabel(String category) {
    switch (category) {
      case 'adhd':
        return 'Attention & Activity';
      case 'autism':
        return 'Social & Routine';
      case 'depression':
        return 'Mood & Energy';

      case 'impact':
        return 'Daily Impact';
      default:
        return '';
    }
  }

  Widget _buildLikertOption(
      int value, String label, Color dotColor, bool isSelected) {
    return GestureDetector(
      onTap: () => _answerQuestion(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple.withValues(alpha: 0.05)
              : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppColors.primaryPurple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryPurple
                      : Colors.grey[400]!,
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
    final isLastQuestion =
        _currentQuestionIndex == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      color: AppColors.cardWhite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goToPreviousQuestion,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        hasAnswer ? AppColors.primaryGradient : null,
                    color: hasAnswer ? null : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: hasAnswer ? _goToNextQuestion : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastQuestion
                                  ? 'Submit'
                                  : 'Next Question',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: hasAnswer
                                    ? Colors.white
                                    : Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: hasAnswer
                                  ? Colors.white
                                  : Colors.grey[500],
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Note: This screening tool is not a diagnostic instrument. '
              'Results should be discussed with a qualified healthcare professional.',
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