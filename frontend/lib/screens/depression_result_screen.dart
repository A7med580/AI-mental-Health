import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/theme/module_themes.dart';
import 'package:mindful/widgets/glass_container.dart';
import 'package:mindful/widgets/page_transitions.dart';

class DepressionResultScreen extends StatelessWidget {
  final Map<String, dynamic> screeningResult;
  final List<dynamic> individualResults;
  final List<String> modalitiesUsed;

  const DepressionResultScreen({
    Key? key,
    required this.screeningResult,
    required this.individualResults,
    required this.modalitiesUsed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int fusedPrediction = screeningResult['fused_prediction'] ?? 0;
    final num fusedConfidence = screeningResult['fused_confidence'] ?? 0.0;
    final bool isDepression = fusedPrediction == 1;

    // Map the modalities out
    String textConfidence = "N/A";
    String audioConfidence = "N/A";
    String visualConfidence = "N/A";

    for (var res in individualResults) {
      if (res is Map<String, dynamic>) {
        final type = res['model_type'];
        final confNum = (res['confidence'] as num?) ?? 0.0;
        final confStr = "${(confNum * 100).toStringAsFixed(1)}%";
        
        if (type == 'text') textConfidence = confStr;
        if (type == 'audio') audioConfidence = confStr;
        if (type == 'visual') visualConfidence = confStr;
      }
    }

    return Scaffold(
      backgroundColor: depressionTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Diagnostic Header ──
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDepression
                        ? AppColors.error.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDepression ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 40,
                    color: isDepression ? AppColors.error : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(depressionTheme.icon,
                      size: 22, color: depressionTheme.accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'Assessment Complete',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isDepression
                    ? 'Significant indicators of depression detected.'
                    : 'No significant indicators of depression detected.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // ── Overall Confidence ──
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Overall Multimodal Confidence',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(fusedConfidence * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Breakdown ──
              Text(
                'Modality Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildModalityRow(
                icon: Icons.chat_bubble_outline,
                title: 'Text Analysis (DistilBERT)',
                confidence: textConfidence,
              ),
              const SizedBox(height: 12),
              if (modalitiesUsed.contains('audio'))
                _buildModalityRow(
                  icon: Icons.graphic_eq,
                  title: 'Voice Acoustics (COVAREP)',
                  confidence: audioConfidence,
                ),
              if (modalitiesUsed.contains('audio')) const SizedBox(height: 12),
              if (modalitiesUsed.contains('visual'))
                _buildModalityRow(
                  icon: Icons.face,
                  title: 'Facial Dynamics (CLNF)',
                  confidence: visualConfidence,
                ),

              const SizedBox(height: 40),

              // ── Actions ──
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: depressionTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Return to Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalityRow({
    required IconData icon,
    required String title,
    required String confidence,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            confidence,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }
}
