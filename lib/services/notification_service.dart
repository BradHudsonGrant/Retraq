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

  static const _channelId = 'retraq_nudge';
  static const _channelName = 'Daily Nudge';
  static const _channelDescription = 'Daily check-in reminder';
  static const _notificationId = 0;

  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone
    tzdata.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Request notification permissions (Android 13+ and iOS).
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    // Android 13+
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    // iOS
    final ios =
        _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
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

  /// Rotating Retraq notification messages — warm, low-pressure.
  /// Sourced from the Retraq branding guide rotation lists.
  ///
  /// Note: these are kept in code (not the ARB) because the notification
  /// service runs without a BuildContext, so AppLocalizations is not
  /// available. The strings here mirror the branding guide vocabulary.

  /// Daily reminder rotation (morning + general fallbacks).
  @visibleForTesting
  static const dailyReminderMessages = [
    'Quick — what happened today? Even one word counts.',
    '30 seconds. One traq. You\'ll thank yourself later.',
    'Jot something down before today disappears.',
    'Future you wants to know what happened today.',
    'Don\'t let today vanish. Drop a traq.',
  ];

  /// Weekly roundup messaging — fired after a week is "retraqd".
  @visibleForTesting
  static const weeklyRoundupMessages = [
    'Your week\'s been retraqd. Take a look back.',
    'Here\'s what you got up to this week.',
  ];

  /// Re-engagement messages for users who have been inactive a few days.
  @visibleForTesting
  static const reEngagementMessages = [
    'It\'s been a few days. Drop a quick traq so you don\'t lose the week.',
    'Your week is disappearing. Takes 10 seconds to save it.',
  ];

  // ----- Backwards-compatible aliases used by the rotation logic + tests.
  // Each maps to the appropriate brand-aligned list above.

  @visibleForTesting
  static const morningMessages = dailyReminderMessages;

  @visibleForTesting
  static const eveningMessages = dailyReminderMessages;

  @visibleForTesting
  static const generalMessages = dailyReminderMessages;

  @visibleForTesting
  static const weekendMessages = weeklyRoundupMessages;

  @visibleForTesting
  static const streakAtRiskMessages = reEngagementMessages;

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

    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
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

  /// compute the next fire time for a daily-recurring
  /// notification at [hour]:[minute] local, relative to [now].
  /// Exposed as a pure static helper so the schedule-math can be
  /// unit-tested without mocking the flutter_local_notifications
  /// plugin. If the target wall time has already passed today,
  /// rolls forward one day; otherwise fires today.
  ///
  /// Production callers pass no args — defaults are `tz.local` +
  /// `tz.TZDateTime.now(tz.local)`. Tests pass a fixed [now] in a
  /// specified [location] to exercise DST + timezone boundaries.
  @visibleForTesting
  static tz.TZDateTime computeNextFireTime(
    int hour, {
    int minute = 0,
    tz.TZDateTime? now,
    tz.Location? location,
  }) {
    final loc = location ?? tz.local;
    final n = now ?? tz.TZDateTime.now(loc);
    var scheduled = tz.TZDateTime(loc, n.year, n.month, n.day, hour, minute);
    if (scheduled.isBefore(n)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Schedule a daily notification at the given hour (0-23) and minute (0-59).
  /// If [streakAtRisk] is true, picks a streak-warning message.
  Future<void> scheduleDaily(
    int hour, {
    int minute = 0,
    bool streakAtRisk = false,
  }) async {
    await cancel(); // Clear any existing schedule

    final scheduled = computeNextFireTime(hour, minute: minute);

    final message = pickMessage(hour, streakAtRisk: streakAtRisk);

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Retraq',
      body: message,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
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
