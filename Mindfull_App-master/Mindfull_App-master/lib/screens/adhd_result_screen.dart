import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';

/// ADHD-specific result screen with proper disclaimers and next steps
class ADHDResultScreen extends StatelessWidget {
  final Map<String, dynamic> screeningResult;
  final List<dynamic> individualResults;
  final List<String> modalitiesUsed;

  const ADHDResultScreen({
    Key? key,
    required this.screeningResult,
    required this.individualResults,
    required this.modalitiesUsed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fusedConfidence = screeningResult['fused_confidence'] ?? 0.0;
    final confidenceLevel = screeningResult['confidence_level'] ?? 'Low';
    final explanation = screeningResult['explanation'] ?? '';
    final thresholdMet = screeningResult['threshold_met'] ?? false;
    final contributions = screeningResult['model_contributions'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: Text(
          'Screening Results',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Critical Disclaimer Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is a screening tool, NOT a medical diagnosis. '
                      'Please consult a qualified healthcare professional for proper evaluation.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Main Result Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Result Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: thresholdMet
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                    ),
                    child: Icon(
                      thresholdMet ? Icons.info_outline : Icons.check_circle_outline,
                      size: 40,
                      color: thresholdMet
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Result Title
                  Text(
                    thresholdMet
                        ? 'Patterns Suggestive of ADHD'
                        : 'Low Likelihood of ADHD Patterns',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Confidence Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(confidenceLevel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getConfidenceColor(confidenceLevel),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '$confidenceLevel Confidence',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getConfidenceColor(confidenceLevel),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confidence Score
                  Text(
                    'Confidence: ${(fusedConfidence * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Explanation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      explanation,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Model Contributions
            if (contributions.isNotEmpty) ...[
              Text(
                'Assessment Methods Used',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...contributions.map((contribution) => _buildContributionCard(contribution)),
            ],

            const SizedBox(height: 32),

            // Next Steps
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Recommended Next Steps',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNextStepItem(
                    'Consult a healthcare professional',
                    'A qualified professional can provide proper evaluation and diagnosis.',
                  ),
                  const SizedBox(height: 12),
                  _buildNextStepItem(
                    'Keep a symptom journal',
                    'Track patterns in attention, focus, and daily activities.',
                  ),
                  const SizedBox(height: 12),
                  _buildNextStepItem(
                    'Explore coping strategies',
                    'Learn about time management, organization, and focus techniques.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Return to Home',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionCard(Map<String, dynamic> contribution) {
    final modelType = contribution['model_type'] ?? 'unknown';
    final confidence = contribution['confidence'] ?? 0.0;
    final weight = contribution['weight'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getModelTypeLabel(modelType),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(weight * 100).toStringAsFixed(0)}% weight',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.blue.shade800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getModelTypeLabel(String type) {
    switch (type) {
      case 'behavior':
        return 'Questionnaire Analysis';
      case 'eye':
        return 'Eye-Tracking Analysis';
      case 'voice':
        return 'Voice Pattern Analysis';
      case 'facial':
        return 'Facial Expression Analysis';
      default:
        return type;
    }
  }
}

