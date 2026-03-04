import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/services/meditation_service.dart';
import 'package:mindful/widgets/glass_container.dart';
import 'package:mindful/widgets/page_transitions.dart';

import 'package:mindful/dashboard_screen.dart';
import 'package:mindful/chat_screen.dart';
import 'package:mindful/mood_tracker_screen.dart';
import 'package:mindful/resource_screen.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({Key? key}) : super(key: key);

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> with TickerProviderStateMixin {
  bool _breathingActive = false;
  String _breathingPhase = 'Inhale';
  int _breathingSeconds = 4;
  Timer? _breathingTimer;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  int _phaseIndex = 0;
  final Stopwatch _meditationStopwatch = Stopwatch();

  static const _phases = [
    {'label': 'Inhale', 'duration': 4},
    {'label': 'Hold', 'duration': 4},
    {'label': 'Exhale', 'duration': 4},
  ];

  static const _meditations = [
    {'title': 'Deep Breathing', 'desc': 'Calm your nervous system with guided deep breathing exercises', 'duration': '5 min', 'icon': Icons.air, 'color': 0xFF6B46C1},
    {'title': 'Body Scan', 'desc': 'Release tension by bringing awareness to each part of your body', 'duration': '10 min', 'icon': Icons.accessibility_new, 'color': 0xFF2563EB},
    {'title': 'Loving Kindness', 'desc': 'Cultivate compassion for yourself and others', 'duration': '8 min', 'icon': Icons.favorite, 'color': 0xFFE11D48},
    {'title': 'Sleep Meditation', 'desc': 'Gentle guided imagery to help you drift into restful sleep', 'duration': '15 min', 'icon': Icons.nights_stay, 'color': 0xFF7C3AED},
    {'title': 'Morning Energy', 'desc': 'Energizing visualization to start your day with clarity', 'duration': '7 min', 'icon': Icons.wb_sunny, 'color': 0xFFF59E0B},
    {'title': 'Anxiety Relief', 'desc': 'Grounding techniques to calm an anxious mind quickly', 'duration': '12 min', 'icon': Icons.spa, 'color': 0xFF059669},
  ];

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _breathingAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut));
  }

  @override
  void dispose() { 
    if (_meditationStopwatch.isRunning) {
      _meditationStopwatch.stop();
      MeditationService.logMeditation(_meditationStopwatch.elapsed.inSeconds);
    }
    _breathingTimer?.cancel(); 
    _breathingController.dispose(); 
    super.dispose(); 
  }

  void _toggleBreathing() {
    if (_breathingActive) {
      _breathingTimer?.cancel();
      _breathingController.stop();
      _meditationStopwatch.stop();
      MeditationService.logMeditation(_meditationStopwatch.elapsed.inSeconds);
      _meditationStopwatch.reset();
      setState(() { _breathingActive = false; _breathingPhase = 'Inhale'; _breathingSeconds = 4; _phaseIndex = 0; });
    } else {
      _meditationStopwatch.start();
      setState(() => _breathingActive = true);
      _startPhase();
    }
  }

  void _startPhase() {
    final phase = _phases[_phaseIndex % _phases.length];
    final dur = phase['duration'] as int;
    setState(() { _breathingPhase = phase['label'] as String; _breathingSeconds = dur; });

    _breathingController.duration = Duration(seconds: dur);
    if (_breathingPhase == 'Inhale') _breathingController.forward(from: 0);
    else if (_breathingPhase == 'Exhale') _breathingController.reverse(from: 1);

    _breathingTimer?.cancel();
    int remaining = dur;
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) { timer.cancel(); _phaseIndex++; if (_breathingActive) _startPhase(); }
      else { setState(() => _breathingSeconds = remaining); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.meshBackground),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meditation', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Find your inner peace with guided exercises', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      _buildBreathingExercise(),
                      const SizedBox(height: 28),
                      Text('Meditation Library', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      _buildMeditationGrid(),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingExercise() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primaryPurple.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Text('Quick Breathing Exercise', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('4-4-4 Box Breathing', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 24),

          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              final size = 100 + (_breathingAnimation.value - 0.6) * 200;
              return Container(
                width: size, height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 5)],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_breathingPhase, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${_breathingSeconds}s', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: _toggleBreathing,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: Text(_breathingActive ? 'Stop' : 'Start Breathing', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryPurple)),
            ),
          ),

          if (!_breathingActive) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPhaseLabel('Inhale', '4s'),
                _buildPhaseDot(),
                _buildPhaseLabel('Hold', '4s'),
                _buildPhaseDot(),
                _buildPhaseLabel('Exhale', '4s'),
                _buildPhaseDot(),
                _buildPhaseLabel('Repeat', ''),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseLabel(String label, String time) {
    return Column(children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      if (time.isNotEmpty) Text(time, style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
    ]);
  }

  Widget _buildPhaseDot() => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white54));

  Widget _buildMeditationGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _meditations.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.85),
      itemBuilder: (context, index) {
        final m = _meditations[index];
        final color = Color(m['color'] as int);
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${m['title']} session coming soon!', style: GoogleFonts.inter()), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
          },
          child: GlassContainer(
            borderRadius: 20,
            opacity: 0.68,
            blur: 12,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(m['icon'] as IconData, color: color, size: 22)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(m['duration'] as String, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(m['title'] as String, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Expanded(child: Text(m['desc'] as String, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return GlassContainer(
      borderRadius: 0, opacity: 0.72, blur: 24,
      padding: const EdgeInsets.symmetric(vertical: 8),
      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 0.5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
          _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'AI Chat', 1),
          _buildNavItem(Icons.favorite_outline, Icons.favorite, 'Mood', 2),
          _buildNavItem(Icons.library_books_outlined, Icons.library_books, 'Resources', 3),
          _buildNavItem(Icons.self_improvement_outlined, Icons.self_improvement, 'Meditate', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = index == 4;
    return GestureDetector(
      onTap: () {
        if (index == 0) switchTab(context, const DashboardScreen());
        if (index == 1) switchTab(context, const MindfulAIScreen());
        if (index == 2) switchTab(context, const MoodTrackerScreen());
        if (index == 3) switchTab(context, const ResourcesScreen());
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary, size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary)),
        ],
      ),
    );
  }
}
