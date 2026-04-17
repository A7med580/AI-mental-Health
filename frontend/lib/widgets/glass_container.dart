import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mindful/app_colors.dart';

/// A reusable frosted-glass container with a soft, warm finish.
/// Uses [BackdropFilter] + [ClipRRect] for a subtle blur effect.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final double opacity;
  final Border? border;
  final Gradient? gradient;

  const GlassContainer({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 8,
    this.backgroundColor,
    this.opacity = 0.82,
    this.border,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkGlassWhite : Colors.white;
    final defaultBorder = isDark ? AppColors.darkGlassBorder : const Color(0xFFE8E4DF).withValues(alpha: 0.5);
    final shadowColor = isDark ? const Color(0x0A000000) : const Color(0xFF1A1510).withValues(alpha: 0.04);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: gradient == null ? (backgroundColor ?? defaultBg).withValues(alpha: opacity) : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                    color: defaultBorder,
                    width: 1,
                  ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Soft-frosted bottom navigation bar.
class GlassBottomNav extends StatelessWidget {
  final List<Widget> items;

  const GlassBottomNav({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardColor.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.darkGlassBorder
                    : const Color(0xFFE8E4DF).withValues(alpha: 0.6),
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items,
          ),
        ),
      ),
    );
  }
}
