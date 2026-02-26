import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A single mood entry logged by the user.
class MoodEntry {
  final int score; // 1–10
  final String? note;
  final DateTime timestamp;

  MoodEntry({
    required this.score,
    this.note,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'score': score,
        'note': note,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        score: json['score'] as int,
        note: json['note'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Service to persist and query mood entries using SharedPreferences.
class MoodService {
  static const _key = 'mood_entries';

  /// Save a new mood entry.
  static Future<void> logMood(int score, {String? note}) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAllEntries();
    entries.add(MoodEntry(score: score, note: note));
    final jsonList = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  /// Get all mood entries, ordered by timestamp (oldest first).
  static Future<List<MoodEntry>> getAllEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entries = raw
        .map((s) => MoodEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return entries;
  }

  /// Get mood entries from the last 7 days.
  static Future<List<MoodEntry>> getWeeklyEntries() async {
    final all = await getAllEntries();
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return all.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  /// Get the total number of entries.
  static Future<int> getEntryCount() async {
    final all = await getAllEntries();
    return all.length;
  }

  /// Average mood over the last 7 days.
  static Future<double> getAverageMood() async {
    final weekly = await getWeeklyEntries();
    if (weekly.isEmpty) return 0.0;
    final sum = weekly.fold<int>(0, (acc, e) => acc + e.score);
    return sum / weekly.length;
  }

  /// Trend direction: "Improving", "Declining", or "Stable".
  static Future<String> getTrend() async {
    final weekly = await getWeeklyEntries();
    if (weekly.length < 2) return 'Stable';

    final mid = weekly.length ~/ 2;
    final firstHalf = weekly.sublist(0, mid);
    final secondHalf = weekly.sublist(mid);

    final avgFirst =
        firstHalf.fold<int>(0, (a, e) => a + e.score) / firstHalf.length;
    final avgSecond =
        secondHalf.fold<int>(0, (a, e) => a + e.score) / secondHalf.length;

    if (avgSecond - avgFirst > 0.5) return 'Improving';
    if (avgFirst - avgSecond > 0.5) return 'Declining';
    return 'Stable';
  }

  /// Calculate the current logging streak in days.
  static Future<int> getCurrentStreak() async {
    final entries = await getAllEntries();
    if (entries.isEmpty) return 0;
    
    // Sort descending by date
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    int streak = 0;
    DateTime? lastProcessedDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (var entry in entries) {
      final entryDate = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      
      if (lastProcessedDate == null) {
        // First entry check (must be today or yesterday to have a streak > 0)
        final diff = today.difference(entryDate).inDays;
        if (diff == 0 || diff == 1) {
          streak = 1;
          lastProcessedDate = entryDate;
        } else {
          return 0; // Streak broken
        }
      } else {
        // Check difference from the last processed date
        if (lastProcessedDate.difference(entryDate).inDays == 1) {
          streak++;
          lastProcessedDate = entryDate;
        } else if (lastProcessedDate.difference(entryDate).inDays == 0) {
          // Multiple entries on the same day, don't break the streak but don't increment
          continue;
        } else {
          // Gap of > 1 day, streak broken
          break;
        }
      }
    }
    return streak;
  }
}
