import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';

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
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Screening Results',
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
                              'This is a screening tool, not a medical diagnosis. Please consult a healthcare professional.',
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
                          // Result Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: detectedCondition != null
                                  ? const Color(0xFFFFF7ED)
                                  : const Color(0xFFF0FDF4),
                            ),
                            child: Icon(
                              detectedCondition != null
                                  ? Icons.flag_outlined
                                  : Icons.check_circle_outline,
                              size: 40,
                              color: detectedCondition != null
                                  ? const Color(0xFFC2410C)
                                  : const Color(0xFF16A34A),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            detectedCondition != null
                                ? 'Indicators Detected'
                                : 'No Strong Indicators',
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

                          if (confidence > 0) ...[
                            // Confidence bar
                            Column(
                              children: [
                                Text(
                                  'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: confidence is double ? confidence : 0.0,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Detailed Results
                    if (allResults != null && allResults!.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Detailed Results',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...allResults!.map((result) => _buildResultCard(result)),
                    ],

                    const SizedBox(height: 24),

                    // Buttons
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text('Return to Home', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/resources'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primaryPurple, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('View Resources', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
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
          color: metThreshold ? AppColors.primaryPurple.withValues(alpha: 0.4) : Colors.grey[300]!,
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
