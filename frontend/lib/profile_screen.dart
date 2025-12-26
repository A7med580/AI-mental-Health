import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  int _selectedIndex = 3;

  String userName = 'Loading...';
  String userEmail = 'Loading...';
  String phoneNumber = 'Loading...';
  String memberSince = 'Loading...';
  String firstName = '';
  String lastName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data == null) {
          // User not found in DB
          setState(() {
            userEmail = user.email ?? 'No email';
            userName = 'User';
            phoneNumber = 'Not provided';
            memberSince = 'Recently joined';
          });
        } else {
          setState(() {
            firstName = data['first_name'] ?? '';
            lastName = data['last_name'] ?? '';
            userName = data['full_name'] ?? '$firstName $lastName';
            userEmail = data['email'] ?? user.email ?? 'No email';
            phoneNumber = data['phone_number'] ?? 'Not provided';

            if (data['created_at'] != null) {
              final date = DateTime.parse(data['created_at']);
              memberSince = '${_getMonthName(date.month)} ${date.year}';
            } else {
              memberSince = 'Recently joined';
            }
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userName = 'Error loading data';
        userEmail = 'Error';
        phoneNumber = 'Error';
        memberSince = 'Error';
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<void> _handleLogout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      print('Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error logging out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                  'Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            // Main Content - Scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Profile Picture
                      Stack(
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF42A5F5),
                                  Color(0xFF1976D2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                firstName.isNotEmpty && lastName.isNotEmpty
                                    ? '${firstName[0]}${lastName[0]}'.toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFF42A5F5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // TODO: Add image picker functionality
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // User Name
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // User Email
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Info Cards
                      _buildInfoCard(
                        Icons.email_outlined,
                        'Email',
                        userEmail,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        Icons.phone_outlined,
                        'Phone',
                        phoneNumber,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        Icons.person_outline,
                        'First Name',
                        firstName.isEmpty ? 'Not provided' : firstName,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        Icons.person_outline,
                        'Last Name',
                        lastName.isEmpty ? 'Not provided' : lastName,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        Icons.calendar_today_outlined,
                        'Member Since',
                        memberSince,
                      ),

                      const SizedBox(height: 32),

                      // Edit Profile Button
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit profile feature coming soon!'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF42A5F5),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Logout Button
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Logout'),
                                content: const Text('Are you sure you want to logout?'),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _handleLogout();
                                    },
                                    child: const Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade500,
                          minimumSize: const Size(double.infinity, 56),
                          side: BorderSide(
                            color: Colors.red.shade300,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
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
                  _buildNavItem(icon: Icons.chat_bubble, label: 'Chat', index: 0),
                  _buildNavItem(icon: Icons.emoji_emotions_outlined, label: 'Emotion', index: 1),
                  _buildNavItem(icon: Icons.menu_book_outlined, label: 'Resources', index: 2),
                  _buildNavItem(icon: Icons.person_outline, label: 'Profile', index: 3, isSelected: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB3E5FC), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1976D2)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
              ],
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
        setState(() => _selectedIndex = index);

        // Navigate based on selection
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/chat');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, '/emotion');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/resources');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: isSelected ? const EdgeInsets.all(8) : null,
            decoration: isSelected
                ? BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8))
                : null,
            child: Icon(icon, color: isSelected ? Colors.white : Colors.lightBlue, size: 24),
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
