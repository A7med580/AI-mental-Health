import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/profile_screen.dart';
import 'package:mindful/resource_screen.dart';
import 'package:mindful/face_detection.dart';
import 'package:mindful/screens/initial_questionnaire_screen.dart';
import 'package:mindful/screens/notifications_screen.dart';
import 'package:mindful/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;
  int _selectedIndex = 0;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotificationCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildWelcomeSection(),
                    const SizedBox(height: 20),
                    _buildScreeningBanner(),
                    const SizedBox(height: 20),
                    _buildStatCards(),
                    const SizedBox(height: 20),
                    _buildQuickActionsSection(),
                    const SizedBox(height: 20),
                    _buildDailyAffirmation(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.cardWhite,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            'MindCare AI',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                  _loadNotificationCount();
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_unreadNotificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WELCOME SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final dateStr = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back!',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              dateStr,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREENING BANNER — ONE UNIFIED BUTTON (like original app)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScreeningBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology_outlined, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'AI-Powered Screening',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              'Mental Health\nScreening',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              'Take our comprehensive multimodal screening for ADHD and Autism. Quick, private, and evidence-based assessment.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // ONE UNIFIED BUTTON — routes to triage questionnaire (same as original app)
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InitialQuestionnaireScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assessment, color: AppColors.primaryPurple, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Start Mental Health Screening',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 16, color: AppColors.primaryPurple),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Privacy info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '100% Private & Secure',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your data is encrypted and never shared. Results are for screening purposes only, not diagnosis.',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  _buildBullet('Text + Video + Audio analysis (ADHD)'),
                  _buildBullet('Text + Facial analysis (Autism)'),
                  _buildBullet('Results in minutes with confidence scores'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 5, right: 6),
            decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, height: 1.3)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAT CARDS (2 cols × 2 rows on mobile)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Current Mood', '😊 Good', '+2 from yesterday', Icons.favorite, AppColors.moodPink)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Streak', '7 Days', 'Keep it up!', Icons.trending_up, AppColors.streakGreen)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard('Meditation', '45 min', 'This week', Icons.self_improvement, AppColors.meditationBlue)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Chat Sessions', '12', 'This month', Icons.chat_bubble_outline, AppColors.chatTeal)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(title, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS (2x2 grid)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildQuickAction('Start AI Chat', Icons.chat_bubble_outline, AppColors.primaryPurple, () {})),
            const SizedBox(width: 10),
            Expanded(child: _buildQuickAction('Log Your Mood', Icons.favorite_outline, AppColors.moodPink, () {})),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildQuickAction('Meditate Now', Icons.self_improvement, AppColors.meditationBlue, () {})),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickAction('View Resources', Icons.menu_book_outlined, AppColors.streakGreen, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourcesScreen()));
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Icon(Icons.arrow_forward, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DAILY AFFIRMATION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDailyAffirmation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Affirmation',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            '"I am worthy of love, peace, and happiness. Today I choose to focus on what I can control and let go of what I cannot."',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('💜', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('Take a deep breath and believe it', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', index: 0),
          _buildNavItem(icon: Icons.emoji_emotions_outlined, activeIcon: Icons.emoji_emotions, label: 'Emotion', index: 1),
          _buildNavItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Resources', index: 2),
          _buildNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 3),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EmotionDetectionScreen()));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourcesScreen()));
        } else if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 22,
            ),
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
