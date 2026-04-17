import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/theme/module_themes.dart';
import 'package:mindful/widgets/glass_container.dart';
import 'package:mindful/widgets/page_transitions.dart';
import 'package:mindful/widgets/animated_gauge.dart';
import 'package:mindful/widgets/animated_scale_button.dart';

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
              // ── Main Result Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    AnimatedGauge(
                      score: fusedConfidence is double ? fusedConfidence : fusedConfidence.toDouble(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isDepression
                          ? 'Signs of depression found.'
                          : 'No strong signs found.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Breakdown ──
              Text(
                'Details',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildModalityRow(
                icon: Icons.chat_bubble_outline,
                title: 'Text Analysis',
                confidence: textConfidence,
              ),
              const SizedBox(height: 12),
              if (modalitiesUsed.contains('audio'))
                _buildModalityRow(
                  icon: Icons.graphic_eq,
                  title: 'Voice Analysis',
                  confidence: audioConfidence,
                ),
              if (modalitiesUsed.contains('audio')) const SizedBox(height: 12),
              if (modalitiesUsed.contains('visual'))
                _buildModalityRow(
                  icon: Icons.face,
                  title: 'Expression Analysis',
                  confidence: visualConfidence,
                ),

              const SizedBox(height: 40),

              // ── Actions ──
              AnimatedScaleButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: depressionTheme.accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Home',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
