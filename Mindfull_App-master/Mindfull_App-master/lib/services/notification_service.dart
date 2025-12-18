import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification model
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? payload;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.payload,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'payload': payload,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }
}

/// Service for managing in-app notifications
class NotificationService {
  static const String _storageKey = 'app_notifications';

  /// Get all notifications
  static Future<List<AppNotification>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
    } catch (e) {
      print('Error loading notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count
  static Future<int> getUnreadCount() async {
    final notifications = await getAllNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  /// Add a new notification
  static Future<void> addNotification(AppNotification notification) async {
    try {
      final notifications = await getAllNotifications();
      notifications.insert(0, notification); // Add to beginning

      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final notifications = await getAllNotifications();
      final index = notifications.indexWhere((n) => n.id == notificationId);
      
      if (index != -1) {
        final notification = notifications[index];
        notifications[index] = AppNotification(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          createdAt: notification.createdAt,
          isRead: true,
          payload: notification.payload,
        );

        final prefs = await SharedPreferences.getInstance();
        final jsonList = notifications.map((n) => n.toJson()).toList();
        await prefs.setString(_storageKey, json.encode(jsonList));
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final notifications = await getAllNotifications();
      final updatedNotifications = notifications.map((n) {
        return AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          createdAt: n.createdAt,
          isRead: true,
          payload: n.payload,
        );
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      final jsonList = updatedNotifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final notifications = await getAllNotifications();
      notifications.removeWhere((n) => n.id == notificationId);

      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  /// Create a notification for ADHD screening result
  static Future<void> createADHDScreeningNotification({
    required String jobId,
    required bool isAdhd,
    required double confidence,
  }) async {
    final notification = AppNotification(
      id: 'adhd_$jobId',
      title: 'Screening Result Ready',
      body: isAdhd
          ? 'Your ADHD screening result indicates patterns consistent with ADHD characteristics (${(confidence * 100).toStringAsFixed(0)}% confidence).'
          : 'Your ADHD screening result indicates low likelihood of ADHD patterns (${(confidence * 100).toStringAsFixed(0)}% confidence).',
      createdAt: DateTime.now(),
      isRead: false,
      payload: {
        'type': 'adhd_screening',
        'jobId': jobId,
        'isAdhd': isAdhd,
        'confidence': confidence,
      },
    );

    await addNotification(notification);
  }
}
