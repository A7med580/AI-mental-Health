import 'package:flutter/material.dart';
import 'package:mindful/profile_screen.dart';

import 'chat_screen.dart';
import 'face_detection.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({Key? key}) : super(key: key);

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Center(
                child: Text(
                  'Resources',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Row 1
                    Row(
                      children: [
                        Expanded(
                          child: _buildResourceCard(
                            icon: Icons.air,
                            title: 'Breathing\nExercises',
                            subtitle: 'Calming techniques\nfor relaxation',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildResourceCard(
                            icon: Icons.self_improvement,
                            title: 'Meditation\nGuides',
                            subtitle: 'Find peace with\nguided meditations',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Row 2
                    Row(
                      children: [
                        Expanded(
                          child: _buildResourceCard(
                            icon: Icons.nightlight_round,
                            title: 'Sleep Hygiene',
                            subtitle: 'Improve your sleep\nquality',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildResourceCard(
                            icon: Icons.sentiment_dissatisfied_outlined,
                            title: 'Stress\nManagement',
                            subtitle: 'Cope with daily\nstressors',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Row 3
                    Row(
                      children: [
                        Expanded(
                          child: _buildResourceCard(
                            icon: Icons.sentiment_satisfied_alt,
                            title: 'Mindfulness\nPractices',
                            subtitle: 'Practice being\npresent',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildResourceCard(
                            icon: Icons.phone,
                            title: 'Crisis Hotlines',
                            subtitle: 'Get immediate\nsupport',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: const Color(0xFFE0E7EE)),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.chat_bubble,
                    label: 'Chat',
                    index: 0,

                  ),
                  _buildNavItem(
                    icon: Icons.emoji_emotions_outlined,
                    label: 'Emotion',
                    index: 1,

                  ),
                  _buildNavItem(
                    icon: Icons.menu_book_outlined,
                    label: 'Resources',
                    index: 2,
                    isSelected: true,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    index: 3,

                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7EE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 32,
            color: const Color(0xFF424242),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF42A5F5),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        // Navigate based on selection
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MindfulAIScreen(),
            ),
          ); // Go back to chat
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EmotionDetectionScreen(),
            ),
          );
        }
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: isSelected ? const EdgeInsets.all(8) : null,
            decoration: isSelected
                ? BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            )
                : null,
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.lightBlue,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.black87 : const Color(0xFF90A4AE),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}