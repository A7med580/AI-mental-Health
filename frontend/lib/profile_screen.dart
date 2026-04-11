import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/dashboard_screen.dart';
import 'package:mindful/face_detection.dart';
import 'package:mindful/resource_screen.dart';
import 'package:mindful/widgets/page_transitions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindful/screens/legal/terms_of_service_screen.dart';
import 'package:mindful/screens/legal/privacy_policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  String userName = 'Loading...';
  String userEmail = '';
  String userPhone = '';
  String firstName = '';
  String lastName = '';
  String memberSince = '';
  bool _isLoading = true;
  bool _isEditing = false;

  int _selectedIndex = 3;

  // Notification settings
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _moodReminders = true;
  bool _weeklyReports = true;

  // Editable controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ─── ALL LOGIC BELOW IS UNCHANGED ───────────────────────────────────

  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          setState(() {
            firstName = data['first_name'] ?? '';
            lastName = data['last_name'] ?? '';
            userName = '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
            userEmail = data['email'] ?? user.email ?? '';
            userPhone = data['phone_number'] ?? '';
            memberSince = _formatDate(data['created_at']);
            _isLoading = false;
          });
        } else {
          setState(() {
            userName = user.email ?? 'No Name';
            userEmail = user.email ?? '';
            _isLoading = false;
          });
        }
        _nameController.text = userName;
        _emailController.text = userEmail;
        _phoneController.text = userPhone;
      }
    } catch (e) {
      setState(() {
        userName = 'Error loading';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleSave() {
    setState(() {
      _isEditing = false;
      userName = _nameController.text;
      userEmail = _emailController.text;
      userPhone = _phoneController.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved!')),
    );
  }

  String _getInitials() {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l'.isEmpty ? '?' : '$f$l';
  }

  // ── ──────────────────────────────────────────────────────────────

  Future<void> _downloadMyData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in.')));
        return;
      }
      
      final data = await supabase.from('users').select().eq('id', user.id).maybeSingle();
      if (!mounted) return;
      Navigator.pop(context); // close loading

      if (data != null) {
        final formattedData = const JsonEncoder.withIndent('  ').convert(data);
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.download_done, color: AppColors.primaryPurple),
                const SizedBox(width: 10),
                Text('Your Data', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.1)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  formattedData,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close', style: GoogleFonts.inter(color: AppColors.textSecondary)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: formattedData));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data copied to clipboard!'), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                label: Text('Copy JSON', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data found.')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  // ─── UI (MATCHING REACT REFERENCE) ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.primaryPurple),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header ──
                          Text(
                            'Your Profile',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your account and track your progress',
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                          ),

                          const SizedBox(height: 24),

                          // ── Profile Card ──
                          _buildProfileCard(),

                          const SizedBox(height: 20),

                          // ── Stats Grid ──
                          _buildStatsGrid(),

                          const SizedBox(height: 20),

                          // ── Goals Progress ──
                          _buildGoalsProgress(),

                          const SizedBox(height: 20),

                          // ── Notification Preferences ──
                          _buildNotificationPreferences(),

                          const SizedBox(height: 20),

                          // ── Legal & Privacy ──
                          _buildLegalPrivacy(),

                          const SizedBox(height: 20),

                          // ── Account Actions ──
                          _buildAccountActions(),
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

  // ── Profile Card ──────────────────────────────────────────────────

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar row + Edit button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                ),
                child: Center(
                  child: Text(
                    _getInitials(),
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name + badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      memberSince.isNotEmpty
                          ? 'Member since $memberSince'
                          : 'Member',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildBadge('Active User', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
                        _buildBadge('47 Day Streak 🔥', const Color(0xFFF3E8FF), const Color(0xFF7C3AED)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Edit button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => setState(() => _isEditing = !_isEditing),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isEditing ? 'Cancel' : 'Edit Profile',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Form fields
          _buildFormField(Icons.person_outline, 'Full Name', _nameController),
          const SizedBox(height: 14),
          _buildFormField(Icons.email_outlined, 'Email', _emailController, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autocorrect: false),
          const SizedBox(height: 14),
          _buildFormField(Icons.phone_outlined, 'Phone', _phoneController),
          const SizedBox(height: 14),
          _buildFormField(Icons.calendar_today_outlined, 'Member Since', null, value: memberSince.isEmpty ? 'Unknown' : memberSince),
          const SizedBox(height: 14),

          // Change Password
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('Password', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Change password coming soon!')),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E4DF)),
              ),
              child: Text(
                'Change Password',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          ),

          // Save button
          if (_isEditing) ...[
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _handleSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.save, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  Widget _buildFormField(IconData icon, String label, TextEditingController? controller, {String? value, TextInputType? keyboardType, TextInputAction? textInputAction, bool autocorrect = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        if (controller != null)
          TextField(
            controller: controller,
            enabled: _isEditing,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autocorrect: autocorrect,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: _isEditing ? Colors.white : AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE8E4DF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE8E4DF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE8E4DF)),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E4DF)),
            ),
            child: Text(
              value ?? '',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
      ],
    );
  }

  // ── Stats Grid ────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    final stats = [
      {'label': 'Days Active', 'value': '47', 'icon': Icons.calendar_today_outlined},
      {'label': 'Mood Entries', 'value': '145', 'icon': Icons.person_outline},
      {'label': 'Meditation Min', 'value': '380', 'icon': Icons.visibility_outlined},
      {'label': 'Chat Sessions', 'value': '23', 'icon': Icons.email_outlined},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: stats.map((stat) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(stat['icon'] as IconData, size: 20, color: AppColors.primaryPurple),
              Text(
                stat['value'] as String,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurple,
                ),
              ),
              Text(
                stat['label'] as String,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Goals Progress ────────────────────────────────────────────────

  Widget _buildGoalsProgress() {
    final goals = [
      {'title': 'Daily Mood Check-in', 'progress': 0.85, 'color': const Color(0xFF8B5CF6)},
      {'title': 'Weekly Meditation', 'progress': 0.60, 'color': const Color(0xFFEC4899)},
      {'title': 'Resource Reading', 'progress': 0.40, 'color': const Color(0xFF3B82F6)},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Goals Progress',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          ...goals.map((goal) {
            final progress = goal['progress'] as double;
            final color = goal['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        goal['title'] as String,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFE8E4DF),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Notification Preferences ──────────────────────────────────────

  Widget _buildNotificationPreferences() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_outlined, size: 22, color: AppColors.primaryPurple),
              const SizedBox(width: 10),
              Text(
                'Notification Preferences',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildToggleRow('Email Notifications', 'Receive updates via email', _emailNotifications, (v) => setState(() => _emailNotifications = v)),
          const SizedBox(height: 10),
          _buildToggleRow('Push Notifications', 'Get notifications on your device', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
          const SizedBox(height: 10),
          _buildToggleRow('Daily Mood Reminders', 'Remind me to log my mood', _moodReminders, (v) => setState(() => _moodReminders = v)),
          const SizedBox(height: 10),
          _buildToggleRow('Weekly Progress Reports', 'Get weekly summaries', _weeklyReports, (v) => setState(() => _weeklyReports = v)),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, String description, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(description, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: value ? AppColors.primaryPurple : const Color(0xFFE8E4DF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Legal & Privacy ───────────────────────────────────────────────

  Widget _buildLegalPrivacy() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legal & Privacy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F4788),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Color(0xFF2E5C99)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Terms of Service', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Review our terms and conditions', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.privacy_tip, color: Color(0xFF2E5C99)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('How we protect and use your data', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Account Actions ───────────────────────────────────────────────

  Widget _buildAccountActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Actions',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          _buildActionRow('Download My Data', const Color(0xFFFAF5FF), AppColors.textPrimary, AppColors.primaryPurple, _downloadMyData),
          const SizedBox(height: 10),
          _buildActionRow('Sign Out', const Color(0xFFFEF2F2), AppColors.error, AppColors.error, _logout, icon: Icons.logout),
        ],
      ),
    );
  }

  Widget _buildActionRow(String label, Color bgColor, Color textColor, Color arrowColor, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
              ),
            ),
            Text('→', style: TextStyle(fontSize: 16, color: arrowColor)),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE8E4DF))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, 'Home', 0),
          _buildNavItem(Icons.emoji_emotions_outlined, 'Emotion', 1),
          _buildNavItem(Icons.menu_book_outlined, 'Resources', 2),
          _buildNavItem(Icons.person, 'Profile', 3),
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
          Navigator.pushReplacement(context, AppPageRoute(page: const DashboardScreen()));
        } else if (index == 1) {
          Navigator.pushReplacement(context, AppPageRoute(page: const EmotionDetectionScreen()));
        } else if (index == 2) {
          Navigator.pushReplacement(context, AppPageRoute(page: const ResourcesScreen()));
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
