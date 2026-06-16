import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/theme/module_themes.dart';
import 'package:mindful/widgets/animated_gauge.dart';
import 'package:mindful/widgets/animated_scale_button.dart';

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
      backgroundColor: adhdTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
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
                  const SizedBox(width: 12),
                  Icon(adhdTheme.icon, size: 20, color: adhdTheme.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your Result',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDBA74), width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFC2410C), size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This is not a medical diagnosis. Please see a doctor.',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9A3412), fontWeight: FontWeight.w600, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Main Result Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AnimatedGauge(
                            score: fusedConfidence is double ? fusedConfidence : fusedConfidence.toDouble(),
                            label: 'ADHD Risk Score',
                          ),

                          const SizedBox(height: 24),

                          Text(
                            thresholdMet ? 'Signs Found' : 'No Strong Signs',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: thresholdMet ? const Color(0xFFC2410C) : const Color(0xFF16A34A),
                            ),
                          ),

                          const SizedBox(height: 8),
                          Text(
                            'Based on your screening answers.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              explanation,
                              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Model Contributions & Diagnostics
                    Text(
                      'Diagnostic Breakdown',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    if (contributions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'No models could analyze your submission. Check video quality or try again.',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.orange.shade800),
                        ),
                      )
                    else
                      ...contributions.map((contribution) => _buildContributionCard(contribution)),

                    const SizedBox(height: 24),

                    // Next Steps
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb_outline, color: AppColors.primaryPurple),
                              const SizedBox(width: 8),
                              Text(
                                'Next Steps',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildNextStepItem('See a doctor', 'A doctor can give you a true check-up.'),
                          const SizedBox(height: 12),
                          _buildNextStepItem('Keep a journal', 'Write down when you lose focus during the day.'),
                          const SizedBox(height: 12),
                          _buildNextStepItem('Learn new skills', 'Read about how to manage your time and focus better.'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    AnimatedScaleButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [adhdTheme.accentColor, const Color(0xFFD98C1A)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Done',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
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
    final confidence = (contribution['confidence'] ?? 0.0) as num;
    final weight = contribution['weight'] ?? 0.0;
    final confAsDouble = confidence.toDouble();

    // Questionnaire scoring always produces a valid score — no warning needed.
    final hasIssue = confAsDouble < 0.001 && modelType != 'questionnaire';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasIssue ? Colors.orange.shade300 : const Color(0xFFE8E4DF)),
        boxShadow: hasIssue ? [
          BoxShadow(color: Colors.orange.withValues(alpha: 0.1), blurRadius: 4)
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getModelTypeLabel(modelType),
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confidence: ${(confAsDouble * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(fontSize: 13, color: hasIssue ? Colors.orange.shade700 : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(weight * 100).toStringAsFixed(0)}% weight',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (hasIssue) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                modelType == 'eye'
                  ? '⚠ Eye tracking quality too low (video may be too short, or face not clearly visible)'
                  : modelType == 'facial'
                  ? '⚠ Facial features could not be extracted (ensure good lighting and clear face visibility)'
                  : '⚠ This model could not process your input',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade800, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextStepItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primaryPurple,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryPurple)),
              const SizedBox(height: 4),
              Text(description, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
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
        return AppColors.primaryPurple;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getModelTypeLabel(String type) {
    switch (type) {
      case 'questionnaire':
        return 'Your Answers';
      case 'behavior':
        return 'Questions';
      case 'eye':
        return 'Eye Tracking';
      case 'voice':
        return 'Voice Analysis';
      case 'facial':
        return 'Expression Analysis';
      default:
        return type;
    }
  }
}
