import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Smart local notification service for Kapsa.
///
/// Schedules motivational study reminders based on user data:
/// - Streak maintenance ("Don't lose your 5-day streak!")
/// - Exam countdowns ("3 days until your Biology exam")
/// - Daily study nudges at optimal times
/// - Comeback prompts when user hasn't opened the app
///
/// All notifications are LOCAL — no Firebase/server needed.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'kapsa_study';
  static const _channelName = 'Study Reminders';
  static const _prefsKey = 'notifications_enabled';
  static const _prefsTimeKey = 'notification_time_hour';

  /// Initialize the notification plugin.
  ///
  /// Call once at app startup.
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  /// Request notification permissions (iOS).
  ///
  /// Returns true if granted.
  static Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Check if notifications are enabled by the user.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  /// Enable or disable notifications.
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);

    if (!enabled) {
      await cancelAll();
    }
  }

  /// Get the preferred notification hour (default: 20 = 8PM).
  static Future<int> getPreferredHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsTimeKey) ?? 20;
  }

  /// Set the preferred notification hour.
  static Future<void> setPreferredHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsTimeKey, hour);
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ────────────────────────────────────────────────
  // SMART NOTIFICATION SCHEDULING
  // ────────────────────────────────────────────────

  /// Schedule all relevant notifications based on user data.
  ///
  /// Call this when:
  /// - App opens (main.dart)
  /// - User completes a study session
  /// - Course exam date changes
  /// - User enables notifications
  static Future<void> scheduleSmartReminders({
    required int streakDays,
    required List<ExamReminder> upcomingExams,
    required String userName,
  }) async {
    final enabled = await isEnabled();
    if (!enabled) return;

    // Clear old notifications before rescheduling
    await cancelAll();

    final hour = await getPreferredHour();
    int notifId = 0;

    // 1) Daily streak motivation (tomorrow evening)
    final streakMessage = _getStreakMessage(streakDays, userName);
    await _scheduleDailyAt(
      id: notifId++,
      title: streakMessage.title,
      body: streakMessage.body,
      hour: hour,
      minute: 0,
    );

    // 2) Morning study nudge (next day at 9AM)
    final morningMsg = _getMorningMessage(userName);
    await _scheduleDailyAt(
      id: notifId++,
      title: morningMsg.title,
      body: morningMsg.body,
      hour: 9,
      minute: 0,
    );

    // 3) Exam countdown reminders
    for (final exam in upcomingExams) {
      final daysUntil = exam.date.difference(DateTime.now()).inDays;

      // Remind at 7 days, 3 days, 1 day before exam
      for (final d in [7, 3, 1]) {
        if (daysUntil >= d) {
          final examMsg = _getExamMessage(exam.courseName, d);
          final reminderDate = exam.date.subtract(Duration(days: d));
          await _scheduleAt(
            id: notifId++,
            title: examMsg.title,
            body: examMsg.body,
            date: DateTime(reminderDate.year, reminderDate.month,
                reminderDate.day, hour, 0),
          );
        }
      }
    }

    // 4) Comeback nudge (3 days from now — in case user doesn't open)
    final comebackMsg = _getComebackMessage(userName);
    await _scheduleAt(
      id: notifId++,
      title: comebackMsg.title,
      body: comebackMsg.body,
      date: DateTime.now().add(const Duration(days: 3)).copyWith(
            hour: hour,
            minute: 30,
          ),
    );

    if (kDebugMode) {
      debugPrint('📬 Scheduled $notifId smart notifications');
    }
  }

  // ────────────────────────────────────────────────
  // MESSAGE GENERATORS (emotionally engaging)
  // ────────────────────────────────────────────────

  static _NotifMessage _getStreakMessage(int streakDays, String name) {
    final r = Random();

    if (streakDays == 0) {
      final messages = [
        _NotifMessage(
          'Start your streak today! 🔥',
          '$name, just 5 minutes of review can make a huge difference. Your future self will thank you.',
        ),
        _NotifMessage(
          'Your journey starts now ✨',
          'Every expert was once a beginner. Open Kapsa and take the first step, $name.',
        ),
      ];
      return messages[r.nextInt(messages.length)];
    }

    if (streakDays < 3) {
      return _NotifMessage(
        'Keep going! $streakDays-day streak 🔥',
        '$name, you\'re building momentum. Don\'t let it slip — a quick review keeps you sharp.',
      );
    }

    if (streakDays < 7) {
      return _NotifMessage(
        '$streakDays days strong! 🔥🔥',
        'You\'re on fire, $name! You\'re in the top 10% of students who stay consistent. Keep it up!',
      );
    }

    if (streakDays < 30) {
      return _NotifMessage(
        '$streakDays-day streak! You\'re unstoppable 🏆',
        '$name, consistency beats talent every time. Your dedication is paying off — don\'t stop now.',
      );
    }

    return _NotifMessage(
      '$streakDays days! You\'re a legend 👑',
      '$name, most students give up after 3 days. You\'ve been at it for $streakDays. That\'s extraordinary.',
    );
  }

  static _NotifMessage _getMorningMessage(String name) {
    final messages = [
      _NotifMessage(
        'Good morning, $name ☀️',
        'A 10-minute review before your day starts is worth 1 hour of cramming later.',
      ),
      _NotifMessage(
        'Rise and study ☕',
        'Your brain is freshest in the morning. Quick flashcard session?',
      ),
      _NotifMessage(
        'Make today count 💪',
        '$name, students who review in the morning score 23% higher on exams.',
      ),
    ];
    return messages[Random().nextInt(messages.length)];
  }

  static _NotifMessage _getExamMessage(String courseName, int daysUntil) {
    if (daysUntil == 1) {
      return _NotifMessage(
        'Your $courseName exam is TOMORROW! 📚',
        'You\'ve got this. Do a final review of your weakest flashcards tonight. You\'re more prepared than you think.',
      );
    }
    if (daysUntil == 3) {
      return _NotifMessage(
        '$courseName exam in 3 days 📝',
        'Perfect time for a practice quiz. Focus on the topics you\'re least confident about.',
      );
    }
    return _NotifMessage(
      '$courseName exam in $daysUntil days 📅',
      'You still have time! Review a few flashcards each day and you\'ll be ready.',
    );
  }

  static _NotifMessage _getComebackMessage(String name) {
    final messages = [
      _NotifMessage(
        'We miss you, $name! 🥺',
        'Your flashcards are waiting. Even 2 minutes keeps the knowledge fresh in your memory.',
      ),
      _NotifMessage(
        'Don\'t forget your goals 🎯',
        '$name, you started this journey for a reason. Pick up where you left off — it\'s easier than you think.',
      ),
      _NotifMessage(
        'Quick check-in 👋',
        'Hey $name! Spaced repetition works best with consistency. A quick session today?',
      ),
    ];
    return messages[Random().nextInt(messages.length)];
  }

  // ────────────────────────────────────────────────
  // LOW-LEVEL SCHEDULING
  // ────────────────────────────────────────────────

  static Future<void> _scheduleDailyAt({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    final scheduled = tz.TZDateTime.from(date, tz.local);

    // Don't schedule if in the past
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Smart study reminders from Kapsa',
        importance: Importance.high,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}

/// Simple data class for notification content.
class _NotifMessage {
  final String title;
  final String body;
  _NotifMessage(this.title, this.body);
}

/// Exam reminder data passed to the scheduler.
class ExamReminder {
  final String courseName;
  final DateTime date;
  ExamReminder({required this.courseName, required this.date});
}
