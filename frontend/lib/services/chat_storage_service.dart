import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A single chat message that can be serialized to/from JSON.
class ChatMessage {
  final String text;
  final bool isBot;
  final bool isError;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isBot,
    this.isError = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isBot': isBot,
        'isError': isError,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'] as String,
        isBot: json['isBot'] as bool,
        isError: json['isError'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Service to persist and retrieve chat messages using SharedPreferences.
///
/// Messages are stored per-user using the Supabase user ID as a key prefix,
/// so different accounts have completely separate chat histories.
class ChatStorageService {
  static const String _keyPrefix = 'chat_history_';

  /// Returns the storage key for the current user.
  /// Falls back to 'anonymous' if no user is logged in.
  static String _getUserKey() {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? 'anonymous';
    return '$_keyPrefix$userId';
  }

  /// Save the full chat history to local storage.
  static Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_getUserKey(), jsonList);
  }

  /// Load saved chat history from local storage.
  /// Returns an empty list if no history exists.
  static Future<List<ChatMessage>> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_getUserKey()) ?? [];
    return raw
        .map((s) => ChatMessage.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  /// Clear all saved chat messages for the current user.
  static Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getUserKey());
  }

  /// Check if the current user has any saved chat history.
  static Future<bool> hasChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_getUserKey());
    return raw != null && raw.isNotEmpty;
  }
}
