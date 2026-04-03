import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'sincethen_nudge';
  static const _channelName = 'Daily Nudge';
  static const _channelDescription = 'Daily check-in reminder';
  static const _notificationId = 0;

  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone
    tzdata.initializeTimeZones();
    final locationName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(locationName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Request notification permissions (Android 13+ and iOS).
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    // Android 13+
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    // iOS
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
    return true; // Other platforms
  }

  /// Rotating ADHD-friendly notification messages — warm, low-pressure.
  /// Categorised by time-of-day for contextual relevance.
  @visibleForTesting
  static const morningMessages = [
    'Good morning! Set an intention for today — even one word counts.',
    'Rise and write. What are you looking forward to today?',
    'Morning check-in: how are you feeling right now?',
    'Start your day with a thought. Your journal is ready.',
    'A fresh page for a fresh day. What\'s on your mind?',
  ];

  @visibleForTesting
  static const eveningMessages = [
    'What happened today? Even one sentence counts.',
    'Take a moment to capture today before it slips away.',
    'How was your day? A few words is all it takes.',
    'Hey, how did today go? Your journal would love to know.',
    'What\'s the TL;DR of today?',
    'Capture the vibe. Was today a 10 or a meh?',
    'What made today different from yesterday?',
    'The best time to journal was this morning. The second best time is now.',
    'What surprised you today? Write it down before you forget.',
  ];

  @visibleForTesting
  static const generalMessages = [
    'Your journal is waiting. No pressure, just jot something down.',
    'Ready to write? Your future self will thank you.',
    'Just checking in. What\'s on your mind today?',
    'One small entry, one big habit. You\'ve got this.',
    'Today deserves to be remembered. What stood out?',
    'Your journal, your pace. Write as much or as little as you\'d like.',
    'Time for a brain dump? Open up and let it flow.',
    'A quick note now saves a forgotten memory later.',
    'Future you is curious about today. Leave a note.',
    'Even busy days deserve a sentence or two.',
    'You don\'t need perfect words. Just real ones.',
    'Quick check: anything worth remembering today?',
    'One minute, one entry. You can do this.',
    'What would you tell a friend about today?',
    'No rules, no word count. Just you and today.',
    'A few taps now, a whole memory saved forever.',
    'Your journal doesn\'t judge. It just listens.',
    'Plot twist: you actually have time for this. Promise.',
  ];

  @visibleForTesting
  static const weekendMessages = [
    'Lazy weekend? Perfect journaling weather.',
    'Weekends fly by. Capture this one before it does.',
    'No rush today. Take a moment to reflect.',
  ];

  @visibleForTesting
  static const streakAtRiskMessages = [
    'Your streak called. It misses you.',
    'Don\'t let today break your streak — one sentence is enough.',
    'You\'ve been consistent. Keep it going with a quick entry.',
  ];

  /// Pick a contextually relevant message based on hour and day of week.
  @visibleForTesting
  static String pickMessage(int hour, {bool streakAtRisk = false}) {
    final now = DateTime.now();
    // Use day-of-year instead of day-of-month for better distribution across
    // all message lists (avoids repeating after 28-31 days).
    final day = now.difference(DateTime(now.year)).inDays;

    if (streakAtRisk) {
      return streakAtRiskMessages[day % streakAtRiskMessages.length];
    }

    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    if (isWeekend) {
      // Mix weekend-specific with general messages
      if (day % 3 == 0) {
        return weekendMessages[day % weekendMessages.length];
      }
    }

    if (hour < 12) {
      return morningMessages[day % morningMessages.length];
    } else if (hour >= 18) {
      return eveningMessages[day % eveningMessages.length];
    }
    return generalMessages[day % generalMessages.length];
  }

  /// Schedule a daily notification at the given hour (0-23) and minute (0-59).
  /// If [streakAtRisk] is true, picks a streak-warning message.
  Future<void> scheduleDaily(int hour, {int minute = 0, bool streakAtRisk = false}) async {
    await cancel(); // Clear any existing schedule

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final message = pickMessage(hour, streakAtRisk: streakAtRisk);

    await _plugin.zonedSchedule(
      _notificationId,
      'SinceThen',
      message,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a daily notification, but skip if the user already journaled today.
  /// [hasEntriesToday] should return true if today has at least one entry.
  /// [currentStreak] is checked: if > 0, streak-at-risk messaging is used.
  Future<void> scheduleDailyIfNeeded({
    required int hour,
    int minute = 0,
    required Future<bool> Function() hasEntriesToday,
    int currentStreak = 0,
  }) async {
    final journaledToday = await hasEntriesToday();
    if (journaledToday) {
      await cancel();
      return;
    }
    await scheduleDaily(hour, minute: minute, streakAtRisk: currentStreak > 0);
  }

  /// Called by home_screen after an entry is saved.
  /// Cancels today's remaining notification since the user already journaled.
  Future<void> onEntrySaved() async {
    await cancel();
  }

  /// Cancel all scheduled notifications.
  Future<void> cancel() async {
    await _plugin.cancelAll();
  }
}
