import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  // Legacy (keep for backward compat in screens we don't touch)
  static Color primary = const Color(0xFF9C27B0);
  static Color secondary = const Color(0xFF7A9EAE);

  // ── Primary Gradient (Purple → Pink) ──
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color primaryPink = Color(0xFFE91E63);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Backgrounds ──
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF1F5F9);

  // ── Text ──
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnGradient = Color(0xFFFFFFFF);

  // ── Likert Scale Colors ──
  static const Color likertNever = Color(0xFF4CAF50);
  static const Color likertRarely = Color(0xFF2196F3);
  static const Color likertSometimes = Color(0xFFFFC107);
  static const Color likertOften = Color(0xFFFF9800);
  static const Color likertVeryOften = Color(0xFFF44336);

  // ── Accent / Status ──
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // ── Stat card icon colors ──
  static const Color moodPink = Color(0xFFE91E63);
  static const Color streakGreen = Color(0xFF4CAF50);
  static const Color meditationBlue = Color(0xFF7C4DFF);
  static const Color chatTeal = Color(0xFF26A69A);
}