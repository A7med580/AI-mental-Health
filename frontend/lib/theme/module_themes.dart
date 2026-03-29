import 'package:flutter/material.dart';

class ModuleTheme {
  final Color accentColor;
  final Color backgroundColor;
  final IconData icon;
  final String displayName;

  const ModuleTheme({
    required this.accentColor,
    required this.backgroundColor,
    required this.icon,
    required this.displayName,
  });
}

const depressionTheme = ModuleTheme(
  accentColor: Color(0xFF5B8DEF),
  backgroundColor: Color(0xFFF0F4FF),
  icon: Icons.cloud_outlined,
  displayName: 'Depression',
);

const adhdTheme = ModuleTheme(
  accentColor: Color(0xFFF4A335),
  backgroundColor: Color(0xFFFFF8ED),
  icon: Icons.bolt_outlined,
  displayName: 'ADHD',
);

const asdTheme = ModuleTheme(
  accentColor: Color(0xFF4CAF82),
  backgroundColor: Color(0xFFF0FAF4),
  icon: Icons.psychology_outlined,
  displayName: 'ASD',
);
