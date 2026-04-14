import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mindful/app_colors.dart';
import 'package:mindful/services/mood_service.dart';
import 'package:mindful/services/meditation_service.dart';
import 'package:mindful/services/chat_session_service.dart';
import 'package:mindful/profile_screen.dart';
import 'package:mindful/resource_screen.dart';
import 'package:mindful/chat_screen.dart';
import 'package:mindful/mood_tracker_screen.dart';
import 'package:mindful/meditation_screen.dart';
import 'package:mindful/widgets/glass_container.dart';
import 'package:mindful/widgets/page_transitions.dart';
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

  int _streak = 0;
  String _currentMood = 'No data';
  String _moodTrend = 'Start logging!';

  String _quoteText = '"I am worthy of love and peace. I focus on what I can control."';
  String _quoteAuthor = 'Daily Affirmation';
  bool _isLoadingQuote = true;

  int _weeklyMeditationMins = 0;
  int _monthlyChatSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    _loadStats();
    _fetchDailyQuote();
  }

  Future<void> _loadStats() async {
    final avg = await MoodService.getAverageMood();
    final trend = await MoodService.getTrend();
    final streak = await MoodService.getCurrentStreak();
    final medMins = await MeditationService.getWeeklyMinutes();
    final chatSess = await ChatSessionService.getMonthlySessions();
    
    if (mounted) {
      setState(() {
        _streak = streak;
        _weeklyMeditationMins = medMins;
        _monthlyChatSessions = chatSess;
        if (avg == 0) {
          _currentMood = 'No data';
          _moodTrend = '';
        } else if (avg >= 8) {
          _currentMood = '😁 Great';
        } else if (avg >= 6) {
          _currentMood = '😊 Good';
        } else if (avg >= 4) {
          _currentMood = '😐 Okay';
        } else if (avg >= 2) {
          _currentMood = '😞 Low';
        } else {
          _currentMood = '😢 Very Low';
        }
        if (avg != 0) _moodTrend = trend;
      });
    }
  }

  Future<void> _fetchDailyQuote() async {
    try {
      final response = await http.get(Uri.parse('https://zenquotes.io/api/today'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          if (mounted) {
            setState(() {
              _quoteText = '"${data[0]['q']}"';
              _quoteAuthor = data[0]['a'];
              _isLoadingQuote = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingQuote = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingQuote = false);
    }
  }

  Future<void> _loadNotificationCount() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) setState(() => _unreadNotificationCount = count);
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
      ),
    );
  }

  // ─── TOP BAR (Glass) ──────────────────────────────────────────────

  Widget _buildTopBar() {
    return GlassContainer(
      borderRadius: 0,
      opacity: 0.88,
      blur: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: Border(bottom: BorderSide(color: const Color(0xFFE8E4DF).withValues(alpha: 0.6), width: 0.5)),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.psychology, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text('Mindful AI', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const Spacer(),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
                onPressed: () async {
                  await Navigator.push(context, AppPageRoute(page: const NotificationsScreen()));
                  _loadNotificationCount();
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$_unreadNotificationCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── WELCOME ──────────────────────────────────────────────────────

  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final dateStr = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome Back!', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(dateStr, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  // ─── SCREENING BANNER ─────────────────────────────────────────────

  Widget _buildScreeningBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primaryPurple.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology_outlined, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('AI Test', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('Mental Health\nTest', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
            const SizedBox(height: 10),
            Text('Take our quick test for ADHD and Autism.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), height: 1.5)),
            const SizedBox(height: 16),

            // Button
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => Navigator.push(context, AppPageRoute(page: const InitialQuestionnaireScreen())),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assessment, color: AppColors.primaryPurple, size: 20),
                        const SizedBox(width: 8),
                        Text('Start Test', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryPurple)),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 16, color: AppColors.primaryPurple),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Privacy
            GlassContainer(
              opacity: 0.15,
              blur: 8,
              borderRadius: 14,
              padding: const EdgeInsets.all(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text('100% Private', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Your data is safe.',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, height: 1.3)),
                  const SizedBox(height: 6),
                  _buildBullet('Text, Video, and Audio (ADHD)'),
                  _buildBullet('Text and Face (Autism)'),
                  _buildBullet('Fast results'),
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
          Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 5, right: 6), decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle)),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, height: 1.3))),
        ],
      ),
    );
  }

  // ─── STAT CARDS (Glass) ───────────────────────────────────────────

  Widget _buildStatCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Current Mood', _currentMood, _moodTrend, Icons.favorite, AppColors.moodPink)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Streak', '$_streak Days', _streak > 0 ? 'Keep it up!' : 'Start today!', Icons.trending_up, AppColors.streakGreen)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard('Meditation', '$_weeklyMeditationMins min', 'This week', Icons.self_improvement, AppColors.meditationBlue)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Chat Sessions', '$_monthlyChatSessions', 'This month', Icons.chat_bubble_outline, AppColors.chatTeal)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color iconColor) {
    return GlassContainer(
      borderRadius: 18,
      opacity: 0.82,
      blur: 8,
      padding: const EdgeInsets.all(14),
      border: Border.all(color: const Color(0xFFE8E4DF).withValues(alpha: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(title, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ─── QUICK ACTIONS (Glass) ────────────────────────────────────────

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildQuickAction('Start AI Chat', Icons.chat_bubble_outline, AppColors.primaryPurple, () => switchTab(context, const MindfulAIScreen()))),
            const SizedBox(width: 10),
            Expanded(child: _buildQuickAction('Log Your Mood', Icons.favorite_outline, AppColors.moodPink, () => switchTab(context, const MoodTrackerScreen()))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildQuickAction('Meditate Now', Icons.self_improvement, AppColors.meditationBlue, () => switchTab(context, const MeditationScreen()))),
            const SizedBox(width: 10),
            Expanded(child: _buildQuickAction('View Resources', Icons.menu_book_outlined, AppColors.streakGreen, () => switchTab(context, const ResourcesScreen()))),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GlassContainer(
      borderRadius: 16,
      opacity: 0.82,
      blur: 8,
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        colors: [
           color.withValues(alpha: 0.15),
           Colors.white.withValues(alpha: 0.82),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: const Color(0xFFE8E4DF).withValues(alpha: 0.5)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── DAILY AFFIRMATION ────────────────────────────────────────────

  Widget _buildDailyAffirmation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFD4A97A), Color(0xFFC4917A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: const Color(0xFFD4A97A).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Quote', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              if (_isLoadingQuote) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          Text(_quoteText,
              style: GoogleFonts.inter(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.9), height: 1.5)),
          const SizedBox(height: 6),
          Text('- $_quoteAuthor', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70)),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('💜', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('Take a deep breath', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV (Glass) ───────────────────────────────────────────

  Widget _buildBottomNav() {
    return GlassContainer(
      borderRadius: 0,
      opacity: 0.88,
      blur: 12,
      padding: const EdgeInsets.symmetric(vertical: 8),
      border: Border(top: BorderSide(color: const Color(0xFFE8E4DF).withValues(alpha: 0.6), width: 0.5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
          _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'AI Chat', 1),
          _buildNavItem(Icons.favorite_outline, Icons.favorite, 'Mood', 2),
          _buildNavItem(Icons.library_books_outlined, Icons.library_books, 'Resources', 3),
          _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) return;
        if (index == 1) switchTab(context, const MindfulAIScreen());
        if (index == 2) switchTab(context, const MoodTrackerScreen());
        if (index == 3) switchTab(context, const ResourcesScreen());
        if (index == 4) switchTab(context, const ProfileScreen());
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
