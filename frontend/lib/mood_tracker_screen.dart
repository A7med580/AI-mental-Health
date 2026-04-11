import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/services/mood_service.dart';
import 'package:mindful/widgets/glass_container.dart';
import 'package:mindful/widgets/page_transitions.dart';

// ── Navigation imports ──
import 'package:mindful/dashboard_screen.dart';
import 'package:mindful/chat_screen.dart';
import 'package:mindful/resource_screen.dart';
import 'package:mindful/profile_screen.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({Key? key}) : super(key: key);

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  int? _selectedScore;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  double _averageMood = 0.0;
  int _entryCount = 0;
  String _trend = 'Stable';
  List<MoodEntry> _weeklyEntries = [];

  static const _emojis = ['😢', '😞', '😕', '😐', '🙂', '😊', '😄', '😁', '🤩', '🥳'];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final avg = await MoodService.getAverageMood();
    final count = await MoodService.getEntryCount();
    final trend = await MoodService.getTrend();
    final weekly = await MoodService.getWeeklyEntries();
    if (!mounted) return;
    setState(() {
      _averageMood = avg;
      _entryCount = count;
      _trend = trend;
      _weeklyEntries = weekly;
    });
  }

  Future<void> _saveMood() async {
    if (_selectedScore == null) return;
    setState(() => _isSaving = true);
    await MoodService.logMood(_selectedScore!, note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim());
    _noteController.clear();
    setState(() { _selectedScore = null; _isSaving = false; });
    await _loadStats();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mood logged successfully ✓', style: GoogleFonts.inter()), backgroundColor: AppColors.primaryPurple, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  void dispose() { _noteController.dispose(); super.dispose(); }

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
                      Text('Mood Tracker', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Track how you feel', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      _buildLogMoodCard(),
                      const SizedBox(height: 24),
                      _buildWeeklyOverview(),
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Average Mood', '${_averageMood.toStringAsFixed(1)}/10', 'Last 7 days', Icons.favorite_outline, AppColors.primaryPurple),
        const SizedBox(width: 12),
        _buildStatCard('Entries', '$_entryCount', 'Total', Icons.calendar_today_outlined, Colors.blue),
        const SizedBox(width: 12),
        _buildStatCard('Trend', _trend, _trend == 'Improving' ? 'Keep it up!' : (_trend == 'Declining' ? 'Take care' : 'Steady'),
            _trend == 'Improving' ? Icons.trending_up : (_trend == 'Declining' ? Icons.trending_down : Icons.trending_flat),
            _trend == 'Improving' ? Colors.green : (_trend == 'Declining' ? Colors.red : Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String sub, IconData icon, Color color) {
    return Expanded(
      child: GlassContainer(
        borderRadius: 18,
        opacity: 0.68,
        blur: 12,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 18, color: color), const Spacer()]),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ),
            const SizedBox(height: 2),
            Text(sub, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogMoodCard() {
    return GlassContainer(
      borderRadius: 22,
      opacity: 0.68,
      blur: 14,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.add_circle_outline, color: AppColors.primaryPurple, size: 22),
            const SizedBox(width: 8),
            Text('Log Your Mood', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 8),
          Text('How do you feel?', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, 
              mainAxisSpacing: 10, 
              crossAxisSpacing: 10, 
              childAspectRatio: 0.75,
            ),
            itemCount: 10,
            itemBuilder: (context, index) {
              final score = index + 1;
              final isSelected = _selectedScore == score;
              return GestureDetector(
                onTap: () => setState(() => _selectedScore = score),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryPurple.withValues(alpha: 0.15) : AppColors.surfaceLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? AppColors.primaryPurple : Colors.white.withValues(alpha: 0.4), width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_emojis[index], style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 2),
                      Text('$score', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          Text('Add a note', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Your thoughts...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryPurple)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: _selectedScore != null ? AppColors.primaryGradient : null,
                color: _selectedScore == null ? Colors.grey[300] : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _selectedScore != null ? [BoxShadow(color: AppColors.primaryPurple.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))] : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _selectedScore != null && !_isSaving ? _saveMood : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Log Mood', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final weekday = now.weekday;

    return GlassContainer(
      borderRadius: 22,
      opacity: 0.68,
      blur: 14,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('This Week', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Weekly Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    content: Text('Detailed view coming soon!', style: GoogleFonts.inter()),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                  ),
                );
              },
              child: Text('More →', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primaryPurple)),
            ),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final dayDate = now.subtract(Duration(days: weekday - 1 - i));
                final dayEntries = _weeklyEntries.where((e) => e.timestamp.year == dayDate.year && e.timestamp.month == dayDate.month && e.timestamp.day == dayDate.day);
                final avg = dayEntries.isEmpty ? 0.0 : dayEntries.fold<int>(0, (a, e) => a + e.score) / dayEntries.length;
                final heightFraction = avg / 10.0;
                final isToday = i == weekday - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (avg > 0) Text(avg.toStringAsFixed(0), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryPurple)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: max(4, heightFraction * 100),
                          decoration: BoxDecoration(
                            gradient: avg > 0 ? AppColors.primaryGradient : null,
                            color: avg == 0 ? Colors.grey[200]!.withValues(alpha: 0.5) : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(days[i], style: GoogleFonts.inter(fontSize: 11, fontWeight: isToday ? FontWeight.bold : FontWeight.w500, color: isToday ? AppColors.primaryPurple : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
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
          _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = index == 2;
    return GestureDetector(
      onTap: () {
        if (index == 0) switchTab(context, const DashboardScreen());
        if (index == 1) switchTab(context, const MindfulAIScreen());
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
