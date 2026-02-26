import 'package:shared_preferences/shared_preferences.dart';

class ChatSessionService {
  static const _key = 'chat_sessions';

  /// Log a chat session. Only logs one session per hour to prevent spamming.
  static Future<void> logSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getAllSessions();
    
    if (sessions.isNotEmpty) {
      final lastSession = DateTime.parse(sessions.last);
      // Wait at least an hour before counting a new session
      if (DateTime.now().difference(lastSession).inMinutes < 60) return;
    }
    
    sessions.add(DateTime.now().toIso8601String());
    await prefs.setStringList(_key, sessions);
  }

  static Future<List<String>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  /// Get total chat sessions logged in the current calendar month.
  static Future<int> getMonthlySessions() async {
    final all = await getAllSessions();
    final now = DateTime.now();
    final monthly = all.where((isoString) {
      final date = DateTime.parse(isoString);
      return date.year == now.year && date.month == now.month;
    });
    return monthly.length;
  }
}
