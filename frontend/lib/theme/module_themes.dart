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
  accentColor: Color(0xFF7BA3CF),      // soft steel blue
  backgroundColor: Color(0xFFF5F2EF),  // warm cream with blue hint
  icon: Icons.cloud_outlined,
  displayName: 'Depression',
);

const adhdTheme = ModuleTheme(
  accentColor: Color(0xFFD4A05A),      // warm amber
  backgroundColor: Color(0xFFFAF6F0),  // warm cream with amber hint
  icon: Icons.bolt_outlined,
  displayName: 'ADHD',
);

const asdTheme = ModuleTheme(
  accentColor: Color(0xFF6BAF8D),      // sage green
  backgroundColor: Color(0xFFF3F7F4),  // warm cream with green hint
  icon: Icons.psychology_outlined,
  displayName: 'ASD',
);
