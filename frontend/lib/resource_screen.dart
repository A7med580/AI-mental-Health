import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/models/content_item.dart';
import 'package:mindful/widgets/glass_container.dart';
import 'package:mindful/widgets/page_transitions.dart';
import 'package:url_launcher/url_launcher.dart';

// Navigation imports
import 'package:mindful/dashboard_screen.dart';
import 'package:mindful/chat_screen.dart';
import 'package:mindful/mood_tracker_screen.dart';
import 'package:mindful/profile_screen.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({Key? key}) : super(key: key);

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
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
                      Text('Resources', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Educational content and support resources', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      _buildCrisisSection(),
                      const SizedBox(height: 28),
                      _buildSectionHeader('Articles & Guides', Icons.article_outlined),
                      const SizedBox(height: 12),
                      _buildArticlesList(),
                      const SizedBox(height: 28),
                      _buildSectionHeader('Videos & Courses', Icons.play_circle_outline),
                      const SizedBox(height: 12),
                      _buildVideosList(),
                      const SizedBox(height: 28),
                      _buildSectionHeader('Service Directories', Icons.link),
                      const SizedBox(height: 12),
                      _buildServiceDirectories(),
                      const SizedBox(height: 28),
                      _buildSectionHeader('Featured Content', Icons.star_outline),
                      const SizedBox(height: 12),
                      _buildFeaturedContent(),
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

  // ─── CRISIS ───────────────────────────────────────────────────────

  Widget _buildCrisisSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.emergency_outlined, color: Colors.red.shade700, size: 22),
            const SizedBox(width: 8),
            Text('Crisis Support', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
          ]),
          const SizedBox(height: 8),
          Text('If you\'re in crisis, please reach out immediately.', style: GoogleFonts.inter(fontSize: 13, color: Colors.red.shade600)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildCrisisButton('988', 'Suicide Prevention', Icons.phone, () => _launchUrl('tel:988'))),
            const SizedBox(width: 12),
            Expanded(child: _buildCrisisButton('741741', 'Crisis Text Line', Icons.textsms, () => _launchUrl('sms:741741'))),
          ]),
        ],
      ),
    );
  }

  Widget _buildCrisisButton(String number, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(number, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white70), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: AppColors.primaryPurple, size: 20),
      const SizedBox(width: 8),
      Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    ]);
  }

  // ─── ARTICLES / VIDEOS ────────────────────────────────────────────

  Widget _buildArticlesList() => Column(children: ContentItem.sampleArticles.map((item) => _buildContentCard(item)).toList());
  Widget _buildVideosList() => Column(children: ContentItem.sampleVideos.map((item) => _buildContentCard(item, isVideo: true)).toList());

  Widget _buildContentCard(ContentItem item, {bool isVideo = false}) {
    return GestureDetector(
      onTap: () {
        final url = isVideo ? item.videoUrl : item.articleUrl;
        if (url != null && url.isNotEmpty) {
          _launchUrl(url);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.title} link coming soon!', style: GoogleFonts.inter()),
              backgroundColor: AppColors.primaryPurple,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        borderRadius: 18,
        opacity: 0.68,
        blur: 10,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: isVideo ? Colors.blue.shade50.withValues(alpha: 0.8) : AppColors.primaryPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(isVideo ? Icons.play_circle_filled : Icons.article, color: isVideo ? Colors.blue : AppColors.primaryPurple, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(item.description, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primaryPurple.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(item.duration, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryPurple)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SERVICE DIRECTORIES ──────────────────────────────────────────

  Widget _buildServiceDirectories() {
    final services = [
      {'title': 'Find a Therapist', 'desc': 'Psychology Today directory', 'url': 'https://www.psychologytoday.com'},
      {'title': 'BetterHelp', 'desc': 'Online therapy services', 'url': 'https://www.betterhelp.com'},
      {'title': 'NAMI', 'desc': 'Mental Illness Alliance', 'url': 'https://www.nami.org'},
      {'title': 'MentalHealth.gov', 'desc': 'Government resources', 'url': 'https://www.mentalhealth.gov'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3),
      itemBuilder: (context, index) {
        final s = services[index];
        return GestureDetector(
          onTap: () => _launchUrl(s['url']!),
          child: GlassContainer(
            borderRadius: 18,
            opacity: 0.68,
            blur: 10,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.library_books_outlined, size: 20, color: AppColors.primaryPurple),
                  const Spacer(),
                  Icon(Icons.open_in_new, size: 16, color: AppColors.textSecondary),
                ]),
                const SizedBox(height: 10),
                Text(s['title']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Expanded(child: Text(s['desc']!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── FEATURED ─────────────────────────────────────────────────────

  Widget _buildFeaturedContent() {
    final featured = [
      {'title': 'Understanding Therapy', 'color': 0xFF6B46C1},
      {'title': 'Self-Care Practices', 'color': 0xFF059669},
    ];

    return Row(
      children: featured.map((f) {
        final color = Color(f['color'] as int);
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: f == featured.first ? 6 : 0, left: f == featured.last ? 6 : 0),
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(f['title'] as String, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Coming soon', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $url'), backgroundColor: Colors.red));
    }
  }

  // ─── BOTTOM NAV ───────────────────────────────────────────────────

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
    final isSelected = index == 3;
    return GestureDetector(
      onTap: () {
        if (index == 0) switchTab(context, const DashboardScreen());
        if (index == 1) switchTab(context, const MindfulAIScreen());
        if (index == 2) switchTab(context, const MoodTrackerScreen());
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