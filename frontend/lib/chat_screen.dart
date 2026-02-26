import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/widgets/glass_container.dart';
import 'package:mindful/widgets/page_transitions.dart';

// Navigation imports
import 'package:mindful/dashboard_screen.dart';
import 'package:mindful/mood_tracker_screen.dart';
import 'package:mindful/resource_screen.dart';
import 'package:mindful/meditation_screen.dart';
import 'package:mindful/services/chat_session_service.dart';

class MindfulAIScreen extends StatefulWidget {
  const MindfulAIScreen({Key? key}) : super(key: key);

  @override
  State<MindfulAIScreen> createState() => _MindfulAIScreenState();
}

class _MindfulAIScreenState extends State<MindfulAIScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<_ChatBubble> _messages = [
    _ChatBubble(
      text: "Hello! I'm your AI Mental Health Companion. I'm here to listen, support, and help you explore your thoughts and feelings.",
      isBot: true,
    ),
    _ChatBubble(
      text: "I'm currently being trained to provide the best support possible. Full conversational AI is coming soon!",
      isBot: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    ChatSessionService.logSession();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pulseController.dispose();
    super.dispose();
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
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: [
                    _buildComingSoonHero(),
                    const SizedBox(height: 20),
                    ..._messages.map(_buildMessageBubble),
                    const SizedBox(height: 12),
                    _buildFeaturePreview(),
                  ],
                ),
              ),
              _buildDisclaimer(),
              _buildInputArea(),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      borderRadius: 0,
      opacity: 0.72,
      blur: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 0.5)),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.psychology, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Mental Health Companion', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Coming Soon', style: GoogleFonts.inter(fontSize: 12, color: Colors.amber[700], fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primaryPurple.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 36),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('AI Chatbot Coming Soon', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('We\'re building an intelligent companion that understands your mental health needs. Stay tuned!',
              textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatBubble msg) {
    return Align(
      alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 10),
        borderRadius: 18,
        opacity: msg.isBot ? 0.75 : 0.5,
        blur: 12,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: msg.isBot ? null : Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.isBot)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, size: 14, color: AppColors.primaryPurple),
                      const SizedBox(width: 4),
                      Text('MindCare AI', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryPurple)),
                    ],
                  ),
                ),
              Text(msg.text, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePreview() {
    final features = [
      {'icon': Icons.chat_bubble_outline, 'title': 'Natural Conversations', 'desc': 'Talk freely about how you\'re feeling', 'color': 0xFF6B46C1},
      {'icon': Icons.shield_outlined, 'title': 'Safe & Private', 'desc': 'End-to-end encrypted and never shared', 'color': 0xFF059669},
      {'icon': Icons.psychology_outlined, 'title': 'Evidence-Based', 'desc': 'Guided by CBT and mindfulness principles', 'color': 0xFF2563EB},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What to Expect', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...features.map((f) {
          final color = Color(f['color'] as int);
          return GlassContainer(
            margin: const EdgeInsets.only(bottom: 10),
            borderRadius: 16,
            opacity: 0.65,
            blur: 10,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(f['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f['title'] as String, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(f['desc'] as String, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return GlassContainer(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      borderRadius: 12,
      opacity: 0.5,
      blur: 8,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.15)),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: AppColors.primaryPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text('This AI companion provides support but is not a replacement for professional therapy.',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.primaryPurple, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return GlassContainer(
      borderRadius: 0,
      opacity: 0.75,
      blur: 16,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 0.5)),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[300]!)),
              child: TextField(
                controller: _messageController,
                enabled: false,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Chat coming soon...',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  prefixIcon: Padding(padding: const EdgeInsets.only(left: 12, right: 4), child: Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary)),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle), child: const Icon(Icons.send, color: Colors.white, size: 20)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return GlassContainer(
      borderRadius: 0,
      opacity: 0.72,
      blur: 24,
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
    final isSelected = index == 1;
    return GestureDetector(
      onTap: () {
        if (index == 1) return;
        if (index == 0) switchTab(context, const DashboardScreen());
        if (index == 2) switchTab(context, const MoodTrackerScreen());
        if (index == 3) switchTab(context, const ResourcesScreen());
        if (index == 4) switchTab(context, const MeditationScreen());
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

class _ChatBubble {
  final String text;
  final bool isBot;
  const _ChatBubble({required this.text, required this.isBot});
}
