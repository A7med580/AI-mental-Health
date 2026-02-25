import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/dashboard_screen.dart';
import 'package:mindful/face_detection.dart';
import 'package:mindful/profile_screen.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Text(
                    'Resources',
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Crisis hotline banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.phone, color: AppColors.error, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Crisis Hotline',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'If you or someone you know is in crisis, call 988',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please call 988 for crisis support'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Call',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Wellness Resources',
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),

                    const SizedBox(height: 12),

                    // Resource grid
                    Row(
                      children: [
                        Expanded(child: _buildResourceCard(Icons.air, 'Breathing\nExercises', 'Calming techniques')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildResourceCard(Icons.self_improvement, 'Meditation\nGuides', 'Find inner peace')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildResourceCard(Icons.nightlight_round, 'Sleep\nHygiene', 'Better sleep habits')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildResourceCard(Icons.favorite_outline, 'Stress\nManagement', 'Reduce stress')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildResourceCard(Icons.psychology, 'ADHD\nResources', 'Learn about ADHD')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildResourceCard(Icons.diversity_3, 'Autism\nResources', 'Learn about ASD')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildResourceCard(Icons.spa, 'Mindfulness\nExercises', 'Stay present')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildResourceCard(Icons.fitness_center, 'Physical\nWellness', 'Exercise tips')),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Bottom Nav ──
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, 'Home', 0),
          _buildNavItem(Icons.emoji_emotions_outlined, 'Emotion', 1),
          _buildNavItem(Icons.menu_book, 'Resources', 2),
          _buildNavItem(Icons.person_outline, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == _selectedIndex) return;
        setState(() => _selectedIndex = index);

        if (index == 0) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
        } else if (index == 1) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EmotionDetectionScreen()));
        } else if (index == 3) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: isSelected ? const EdgeInsets.all(8) : null,
            decoration: isSelected
                ? BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  )
                : null,
            child: Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}