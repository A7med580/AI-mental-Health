import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/screens/adhd_chat_screen.dart';

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
  final List<Map<String, dynamic>> _questions = [
    {
      "text": "How often do you find it difficult to focus on tasks that require sustained attention?",
      "category": "attention"
    },
    {
      "text": "How often do you feel restless or have difficulty sitting still for extended periods?",
      "category": "activity"
    },
    {
      "text": "How often do you have trouble organizing tasks and activities?",
      "category": "organization"
    },
    {
      "text": "How often do you feel overwhelmed in social situations?",
      "category": "social"
    },
    {
      "text": "How often do you have difficulty following through on instructions or completing tasks?",
      "category": "attention"
    },
    {
      "text": "How often do you feel anxious or worried about everyday situations?",
      "category": "anxiety"
    },
    {
      "text": "How often do you lose things necessary for tasks or activities?",
      "category": "attention"
    },
    {
      "text": "How often do you have difficulty understanding social cues or maintaining conversations?",
      "category": "social"
    },
    {
      "text": "How often do you feel easily distracted by external stimuli?",
      "category": "attention"
    },
    {
      "text": "How often do you have difficulty waiting your turn in conversations or activities?",
      "category": "impulsivity"
    },
    {
      "text": "How often do you feel the need to move constantly or fidget?",
      "category": "activity"
    },
    {
      "text": "How often do you have trouble managing your time effectively?",
      "category": "organization"
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
    // Simple scoring algorithm to estimate prior probabilities
    // This is a placeholder - in production, this would use a trained model
    
    double adhdScore = 0.0;
    double anxietyScore = 0.0;
    double asdScore = 0.0;
    
    for (int i = 0; i < _questions.length; i++) {
      final answer = _answers[i] ?? 2; // Default to neutral if not answered
      final category = _questions[i]["category"] as String;
      
      // Normalize answer (0-4) to weight
      double weight = answer / 4.0;
      
      // Score by category
      if (category == "attention" || category == "organization" || category == "activity" || category == "impulsivity") {
        adhdScore += weight;
      }
      if (category == "anxiety" || category == "social") {
        anxietyScore += weight;
      }
      if (category == "social") {
        asdScore += weight;
      }
    }
    
    // Normalize scores to probabilities (0.0-1.0)
    final totalQuestions = _questions.length.toDouble();
    double adhdProb = (adhdScore / totalQuestions).clamp(0.0, 1.0);
    double anxietyProb = (anxietyScore / totalQuestions).clamp(0.0, 1.0);
    double asdProb = (asdScore / totalQuestions).clamp(0.0, 1.0);
    
    // Create ranked conditions list
    List<Map<String, dynamic>> rankedConditions = [
      {"condition": "ADHD", "probability": adhdProb},
      {"condition": "Anxiety", "probability": anxietyProb},
      {"condition": "ASD", "probability": asdProb},
    ];
    
    // Sort by probability (highest first)
    rankedConditions.sort((a, b) => (b["probability"] as double).compareTo(a["probability"] as double));
    
    // Navigate to ADHD chat if ADHD has highest probability
    final topCondition = rankedConditions[0]["condition"] as String;
    
    if (topCondition == "ADHD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ADHDChatScreen(
            initialProbability: adhdProb,
            questionnaireAnswers: _answers,
          ),
        ),
      );
    } else {
      // For now, if ADHD is not top, still show ADHD flow (as per requirements)
      // In full implementation, would route to appropriate condition
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ADHDChatScreen(
            initialProbability: adhdProb,
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
          'Initial Screening',
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

