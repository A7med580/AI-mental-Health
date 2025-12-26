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
      "text": "How often do you feel the need to adhere to strict routines or rituals?", // Corrected Q6 wording for sensory/routine
      "category": "autism"
    },

    // --- Impact Section (Optional/Last) ---
    {
      "text": "How often so these difficulties interfere with your daily life (work, school, relationships)?",
      "category": "impact"
    },
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

    if (_currentQuestionIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _calculateProbabilities();
    }
  }

  void _calculateProbabilities() {
    // -------------------------------------------------------------------------
    // NEW TRIAGE ROUTING LOGIC (ADHD vs Autism Only)
    // -------------------------------------------------------------------------
    
    int _toBinary(int index) {
      final val = _answers[index] ?? 0;
      // 0-4 scale: Never(0), Rarely(1), Sometimes(2), Often(3), Very Often(4)
      // Convention: >= 2 (Sometimes+) counts as "Yes" (1)
      return val >= 2 ? 1 : 0;
    }

    // 1. Calculate Scores
    // Q1-Q3 (Indices 0, 1, 2) -> ADHD
    final int adhdScore = _toBinary(0) + _toBinary(1) + _toBinary(2);

    // Q4-Q6 (Indices 3, 4, 5) -> Autism
    final int autismScore = _toBinary(3) + _toBinary(4) + _toBinary(5);

    print('Routing Logic: ADHD Score = $adhdScore, Autism Score = $autismScore');

    bool navigateToAutism = false;

    // 2. Logic Implementation
    if (autismScore > adhdScore) {
      // Autism score higher -> Autism Flow
      navigateToAutism = true;
    } else if (adhdScore > autismScore) {
      // ADHD score higher -> ADHD Flow
      navigateToAutism = false;
    } else {
      // Tie-breaker (adhdScore == autismScore)
      // "If Q5 or Q6 (Autism indices 4 or 5) is the highest answer value?"
      // We look at raw 0-4 values.
      
      final int q5Raw = _answers[4] ?? 0; // Social cues
      final int q6Raw = _answers[5] ?? 0; // Routines
      
      // Get max value among ALL first 6 questions to compare
      int maxAll = 0;
      for (int i = 0; i < 6; i++) {
        int val = _answers[i] ?? 0;
        if (val > maxAll) maxAll = val;
      }

      // If Q5 or Q6 is among the maximums -> Autism wins
      if (q5Raw == maxAll || q6Raw == maxAll) {
         navigateToAutism = true;
      } else {
         navigateToAutism = false; // Default to ADHD
      }
    }

    // 3. Execute Navigation
    if (navigateToAutism) {
      print('Route Decision: Autism');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AutismQuestionnaireScreen()),
      );
    } else {
      print('Route Decision: ADHD');
      // Calculate normalized probability for ADHD chat screen (0.0 to 1.0)
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
          'Triage Questionnaire',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
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
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
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
            question["text"] as String,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 60),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnswerOption(0, "Never", currentAnswer == 0),
                const SizedBox(height: 16),
                _buildAnswerOption(1, "Rarely", currentAnswer == 1),
                const SizedBox(height: 16),
                _buildAnswerOption(2, "Sometimes", currentAnswer == 2),
                const SizedBox(height: 16),
                _buildAnswerOption(3, "Often", currentAnswer == 3),
                const SizedBox(height: 16),
                _buildAnswerOption(4, "Very Often", currentAnswer == 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(int value, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _answerQuestion(value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 2,
          ),
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

