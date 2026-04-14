import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/widgets/animated_gauge.dart';
import 'package:mindful/widgets/animated_scale_button.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> screeningResult;
  final List<Map<String, dynamic>>? allResults;

  const ResultsScreen({
    Key? key,
    required this.screeningResult,
    this.allResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detectedCondition = screeningResult['detected_condition'];
    final confidence = screeningResult['confidence'] ?? 0.0;
    final message = screeningResult['message'] ?? '';
    final modelType = screeningResult['model_type'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  Text(
                    'Test Results',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Disclaimer Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDBA74)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFC2410C), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This is a test, not an official diagnosis. Please see a doctor.',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9A3412), fontWeight: FontWeight.w500),
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
                            score: confidence is double ? confidence : confidence.toDouble(),
                          ),

                          const SizedBox(height: 24),

                          Text(
                            detectedCondition != null
                                ? 'Signs Found'
                                : 'No Strong Signs',
                            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),

                          const SizedBox(height: 12),

                          if (detectedCondition != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                detectedCondition,
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryPurple),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (modelType.isNotEmpty) ...[
                            Text(
                              'Model: $modelType',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                          ],

                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                          ),

                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE8E4DF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('What This Means', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 8),
                                Text(
                                  (confidence is double ? confidence : confidence.toDouble()) > 0.7
                                      ? "High Risk: We strongly recommend scheduling a consultation with a certified mental health professional to discuss these results."
                                      : (confidence is double ? confidence : confidence.toDouble()) > 0.4
                                          ? "Medium Risk: Consider monitoring your symptoms and exploring the resources provided below. Reach out to a professional if things do not improve."
                                          : "Low Risk: Keep practicing healthy habits. Re-take the assessment if you start feeling overwhelmed or if your symptoms change.",
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Detailed Results
                    if (allResults != null && allResults!.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Details',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...allResults!.map((result) => _buildResultCard(result)),
                    ],

                    const SizedBox(height: 24),

                    AnimatedScaleButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Go Home',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    AnimatedScaleButton(
                      onPressed: () => Navigator.pushNamed(context, '/resources'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryPurple, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'View Resources',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPurple,
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

  Widget _buildResultCard(Map<String, dynamic> result) {
    final condition = result['condition'] ?? 'Unknown';
    final modelType = result['model_type'] ?? '';
    final confidence = result['confidence'] ?? 0.0;
    final threshold = result['threshold'] ?? 0.5;
    final metThreshold = confidence >= threshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: metThreshold ? AppColors.primaryPurple.withValues(alpha: 0.4) : const Color(0xFFE8E4DF),
          width: metThreshold ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            metThreshold ? Icons.flag : Icons.remove_circle_outline,
            color: metThreshold ? AppColors.primaryPurple : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$condition - $modelType',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${(confidence * 100).toStringAsFixed(1)}% (Threshold: ${(threshold * 100).toStringAsFixed(0)}%)',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
