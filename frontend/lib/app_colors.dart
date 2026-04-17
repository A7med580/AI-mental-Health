import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  // Legacy (keep for backward compat in screens we don't touch)
  static Color primary = const Color(0xFF8B7EC8);
  static Color secondary = const Color(0xFFA8B8D8);

  // ── Primary (Muted Lavender) ──
  static const Color primaryPurple = Color(0xFF8B7EC8);
  static const Color primaryPink = Color(0xFFA8B8D8); // now soft sky

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B7EC8), Color(0xFFA8B8D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Warm accent ──
  static const Color accentWarm = Color(0xFFD4A97A);

  // ── Glass / Soft-Frost Palette ──
  static const Color glassWhite = Color(0xFFFFFFFF);
  static const double glassOpacity = 0.82;
  static const double glassBlur = 8.0;
  static const Color glassBorder = Color(0x80E8E4DF); // warm 50%
  static const Color glassShadow = Color(0x0F1A1510); // warm 6%

  // ── Backgrounds (warm cream) ── LIGHT ──
  static const Color background = Color(0xFFFAF8F5);      // warm cream
  static const Color backgroundAlt = Color(0xFFF3F0EB);   // warm grey
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF3F0EB);

  // ── Text ── LIGHT ──
  static const Color textPrimary = Color(0xFF2D2A32);    // warm charcoal
  static const Color textSecondary = Color(0xFF8A8591);   // warm grey
  static const Color textOnGradient = Color(0xFFFFFFFF);

  // ── Likert Scale Colors (muted pastels) ──
  static const Color likertNever = Color(0xFF7BC4A0);     // soft sage
  static const Color likertRarely = Color(0xFF7BA3CF);    // soft steel
  static const Color likertSometimes = Color(0xFFD4B96A); // warm gold
  static const Color likertOften = Color(0xFFD4A05A);     // warm amber
  static const Color likertVeryOften = Color(0xFFD97B7B); // soft rose

  // ── Accent / Status ──
  static const Color success = Color(0xFF6BAF8D);   // sage green
  static const Color warning = Color(0xFFD4A05A);   // warm amber
  static const Color error = Color(0xFFD97B7B);     // soft rose
  static const Color info = Color(0xFF7BA3CF);      // soft steel blue

  // ── Stat card icon colors ──
  static const Color moodPink = Color(0xFFC88BA0);       // dusty rose
  static const Color streakGreen = Color(0xFF6BAF8D);     // sage
  static const Color meditationBlue = Color(0xFF8B7EC8);  // lavender
  static const Color chatTeal = Color(0xFF6BA8A0);        // soft teal

  // ── Mesh / ambient background gradient for screens ──
  static const LinearGradient meshBackground = LinearGradient(
    colors: [Color(0xFFFAF8F5), Color(0xFFF3F0EB), Color(0xFFF0EDE8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ═══════════════════════════════════════════════════════════════════
  //  DARK MODE — calming, mental-health-matching palette
  //  Uses deep lavender-navy tones instead of plain grey/black
  // ═══════════════════════════════════════════════════════════════════

  // ── Backgrounds ── DARK ──
  static const Color darkBackground      = Color(0xFF1B1929);  // deep lavender-navy
  static const Color darkBackgroundAlt    = Color(0xFF221F33);  // slightly lifted
  static const Color darkCardColor        = Color(0xFF262340);  // lavender-tinted card
  static const Color darkSurfaceLight     = Color(0xFF2E2B47);  // elevated surface

  // ── Text ── DARK ──
  static const Color darkTextPrimary      = Color(0xFFEAE6F2);  // warm lavender-white
  static const Color darkTextSecondary    = Color(0xFF9B95AE);  // muted lavender-grey

  // ── Glass / Frost ── DARK ──
  static const Color darkGlassWhite      = Color(0xFF2A2745);
  static const double darkGlassOpacity   = 0.72;
  static const Color darkGlassBorder     = Color(0x40605C70);  // subtle purple edge
  static const Color darkGlassShadow     = Color(0x0A000000);

  // ── Mesh gradient ── DARK ──
  static const LinearGradient darkMeshBackground = LinearGradient(
    colors: [Color(0xFF1B1929), Color(0xFF221F33), Color(0xFF1E1B2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ═══════════════════════════════════════════════════════════════════
  //  HELPER: context-aware color getters
  //  Usage:  AppColors.bg(context)  instead of  AppColors.background
  // ═══════════════════════════════════════════════════════════════════

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      _isDark(context) ? darkBackground : background;

  static Color bgAlt(BuildContext context) =>
      _isDark(context) ? darkBackgroundAlt : backgroundAlt;

  static Color card(BuildContext context) =>
      _isDark(context) ? darkCardColor : cardWhite;

  static Color surface(BuildContext context) =>
      _isDark(context) ? darkSurfaceLight : surfaceLight;

  static Color txtPrimary(BuildContext context) =>
      _isDark(context) ? darkTextPrimary : textPrimary;

  static Color txtSecondary(BuildContext context) =>
      _isDark(context) ? darkTextSecondary : textSecondary;

  static Color glass(BuildContext context) =>
      _isDark(context) ? darkGlassWhite : glassWhite;

  static Color glassBorderColor(BuildContext context) =>
      _isDark(context) ? darkGlassBorder : glassBorder;

  static LinearGradient mesh(BuildContext context) =>
      _isDark(context) ? darkMeshBackground : meshBackground;

  /// Subtle border color used throughout cards
  static Color border(BuildContext context) =>
      _isDark(context) ? const Color(0xFF3D3A56) : const Color(0xFFE8E4DF);

  /// Toggle row / form field background
  static Color fieldBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF2E2B47) : const Color(0xFFFAF5FF);
}
