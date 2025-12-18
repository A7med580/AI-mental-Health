import 'package:flutter/material.dart';
import 'package:mindful/profile_screen.dart';
import 'package:mindful/resource_screen.dart';
import 'package:mindful/face_detection.dart';
import 'package:mindful/screens/initial_questionnaire_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MindfulAIScreen extends StatefulWidget {
  const MindfulAIScreen({Key? key}) : super(key: key);

  @override
  State<MindfulAIScreen> createState() => _MindfulAIScreenState();
}

class _MindfulAIScreenState extends State<MindfulAIScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  int _selectedIndex = 0;

  late Map<String, dynamic> currentUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        currentUser = {
          'id': user.id,
          'email': user.email,
        };
        print("Logged in as: ${currentUser['email']}");
      }
    } catch (e) {
      print("Error getting current user: $e");
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      await supabase.from('messages').insert({
        'user_id': currentUser['id'],
        'message': message.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
      _messageController.clear();
    } catch (e) {
      print("Failed to send message: $e");
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Center(
                child: Text(
                  'MindfulAI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            // Start Screening Button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InitialQuestionnaireScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assessment),
                  label: const Text('Start Mental Health Screening'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            // Privacy Banner
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Your privacy matters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Messages List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('messages')
                    .stream(primaryKey: ['id'])
                    .order('created_at', ascending: true)
                    .execute()
                    .map((maps) => List<Map<String, dynamic>>.from(maps)),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['user_id'] == currentUser['id'];
                      return Align(
                        alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[200] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['message'],
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Input Area
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        sendMessage(_messageController.text);
                      },
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
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.chat,
                    label: 'Chat',
                    index: 0,
                    isSelected: _selectedIndex == 0,
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
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EmotionDetectionScreen(),
            ),
          );
        }
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ResourcesScreen(),
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
              color: isSelected ? Colors.black87 : Colors.grey[500],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
