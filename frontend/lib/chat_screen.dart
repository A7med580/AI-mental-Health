import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/widgets/glass_container.dart';
import 'package:mindful/widgets/page_transitions.dart';

// Navigation imports
import 'package:mindful/dashboard_screen.dart';
import 'package:mindful/mood_tracker_screen.dart';
import 'package:mindful/resource_screen.dart';
import 'package:mindful/profile_screen.dart';
import 'package:mindful/services/chat_session_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mindful/services/gemini_service.dart';

class MindfulAIScreen extends StatefulWidget {
  const MindfulAIScreen({Key? key}) : super(key: key);

  @override
  State<MindfulAIScreen> createState() => _MindfulAIScreenState();
}

class _MindfulAIScreenState extends State<MindfulAIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isWaitingForResponse = false;
  final List<_ChatBubble> _messages = [
    _ChatBubble(
      text: "Hello! I'm MindCare AI, your Mental Health Companion. I'm here to listen to whatever is on your mind today.",
      isBot: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    ChatSessionService.logSession();
    // Reset conversation on open so it's a fresh chat every time
    GeminiService().resetConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty || _isWaitingForResponse) return;

    _messageController.clear();
    setState(() {
      _messages.add(_ChatBubble(text: text, isBot: false));
      _isWaitingForResponse = true;
    });
    _scrollToBottom();
    FocusScope.of(context).unfocus();

    try {
      final response = await GeminiService().sendMessage(text);
      setState(() {
        _isWaitingForResponse = false;
        _messages.add(_ChatBubble(text: response, isBot: true));
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isWaitingForResponse = false;
        _messages.add(_ChatBubble(text: 'Oops. I had trouble connecting. Please try again.', isBot: true, isError: true));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),
              if (_isWaitingForResponse) _buildTypingIndicator(),
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
                Text('MindCare AI Companion', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Online', style: GoogleFonts.inter(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatBubble msg) {
    return Align(
      alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 16),
        borderRadius: 18,
        opacity: msg.isBot ? (msg.isError ? 0.3 : 0.75) : 0.9,
        blur: 15,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: msg.isBot 
            ? (msg.isError ? Colors.red.withOpacity(0.1) : null) 
            : AppColors.primaryPurple,
        border: msg.isBot ? Border.all(color: AppColors.glassBorder) : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.isBot)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, size: 14, color: msg.isError ? Colors.red : AppColors.primaryPurple),
                      const SizedBox(width: 4),
                      Text('MindCare AI', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: msg.isError ? Colors.red : AppColors.primaryPurple)),
                    ],
                  ),
                ),
              Text(
                msg.text, 
                style: GoogleFonts.inter(
                  fontSize: 14, 
                  color: msg.isBot ? (msg.isError ? Colors.red[800] : AppColors.textPrimary) : Colors.white, 
                  height: 1.5
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
      child: Row(
        children: [
          GlassContainer(
            borderRadius: 18,
            opacity: 0.75,
            blur: 15,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: Border.all(color: AppColors.glassBorder),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                _dot(1),
                _dot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.primaryPurple,
        shape: BoxShape.circle,
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .scale(
      duration: 600.ms,
      delay: (index * 200).ms,
      begin: const Offset(0.5, 0.5),
      end: const Offset(1.5, 1.5),
      curve: Curves.easeInOutSine,
    )
    .then()
    .scale(
      duration: 600.ms,
      begin: const Offset(1.5, 1.5),
      end: const Offset(0.5, 0.5),
      curve: Curves.easeInOutSine,
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
          const Icon(Icons.info_outline, size: 14, color: AppColors.primaryPurple),
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
                focusNode: _focusNode,
                enabled: !_isWaitingForResponse,
                textInputAction: TextInputAction.send,
                onSubmitted: _handleSubmitted,
                maxLines: null,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _isWaitingForResponse ? Colors.grey[400] : AppColors.primaryPurple,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _isWaitingForResponse ? null : () => _handleSubmitted(_messageController.text),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
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
          _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 4),
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

class _ChatBubble {
  final String text;
  final bool isBot;
  final bool isError;
  const _ChatBubble({required this.text, required this.isBot, this.isError = false});
}
