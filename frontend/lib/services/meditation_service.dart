import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MeditationEntry {
  final int seconds;
  final DateTime timestamp;

  MeditationEntry({required this.seconds, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'seconds': seconds,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MeditationEntry.fromJson(Map<String, dynamic> json) =>
      MeditationEntry(
        seconds: json['seconds'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class MeditationService {
  static const _key = 'meditation_entries';

  /// Log a new meditation session in seconds.
  static Future<void> logMeditation(int seconds) async {
    if (seconds < 10) return; // Ignore very short sessions under 10s
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAllEntries();
    entries.add(MeditationEntry(seconds: seconds));
    final jsonList = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  /// Get all logged sessions.
  static Future<List<MeditationEntry>> getAllEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => MeditationEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  /// Get total meditation minutes for the last 7 days.
  static Future<int> getWeeklyMinutes() async {
    final all = await getAllEntries();
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final weekly = all.where((e) => e.timestamp.isAfter(cutoff));
    final totalSeconds = weekly.fold<int>(0, (sum, e) => sum + e.seconds);
    return totalSeconds ~/ 60;
  }
}
