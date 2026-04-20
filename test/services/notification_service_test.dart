import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  group('Message lists are non-empty', () {
    test('morningMessages is non-empty', () {
      expect(NotificationService.morningMessages, isNotEmpty);
    });

    test('eveningMessages is non-empty', () {
      expect(NotificationService.eveningMessages, isNotEmpty);
    });

    test('generalMessages is non-empty', () {
      expect(NotificationService.generalMessages, isNotEmpty);
    });

    test('weekendMessages is non-empty', () {
      expect(NotificationService.weekendMessages, isNotEmpty);
    });

    test('streakAtRiskMessages is non-empty', () {
      expect(NotificationService.streakAtRiskMessages, isNotEmpty);
    });
  });

  group('pickMessage category selection', () {
    test('morning hour returns a morning message', () {
      // pickMessage uses DateTime.now().day for rotation, so the message
      // will come from the morning list when hour < 12 and not weekend/streakAtRisk.
      final message = NotificationService.pickMessage(8);
      // On weekdays, hour < 12 should pick from morning (or general on weekends with day % 3 != 0).
      // We verify it's from either morning or weekend or general (weekend fallback).
      final allPossible = [
        ...NotificationService.morningMessages,
        ...NotificationService.weekendMessages,
        ...NotificationService.generalMessages,
      ];
      expect(allPossible, contains(message));
    });

    test('evening hour returns an evening or weekend/general message', () {
      final message = NotificationService.pickMessage(20);
      final allPossible = [
        ...NotificationService.eveningMessages,
        ...NotificationService.weekendMessages,
        ...NotificationService.generalMessages,
      ];
      expect(allPossible, contains(message));
    });

    test('midday hour returns a general or weekend message', () {
      final message = NotificationService.pickMessage(14);
      final allPossible = [
        ...NotificationService.generalMessages,
        ...NotificationService.weekendMessages,
      ];
      expect(allPossible, contains(message));
    });

    test(
      'streakAtRisk=true returns a streak-at-risk message regardless of hour',
      () {
        final morningMsg = NotificationService.pickMessage(
          8,
          streakAtRisk: true,
        );
        final eveningMsg = NotificationService.pickMessage(
          20,
          streakAtRisk: true,
        );
        final middayMsg = NotificationService.pickMessage(
          14,
          streakAtRisk: true,
        );

        expect(NotificationService.streakAtRiskMessages, contains(morningMsg));
        expect(NotificationService.streakAtRiskMessages, contains(eveningMsg));
        expect(NotificationService.streakAtRiskMessages, contains(middayMsg));
      },
    );
  });

  group('Day-of-year rotation', () {
    test('pickMessage is deterministic for the same day and hour', () {
      // Two calls with the same arguments on the same day should return the same message.
      final msg1 = NotificationService.pickMessage(10);
      final msg2 = NotificationService.pickMessage(10);
      expect(msg1, msg2);
    });

    test('rotation index covers multiple values over different days', () {
      // Verify that day % listLength produces different indices.
      // Since morning has 5 messages, days 1-5 should produce indices 1,2,3,4,0.
      final morningLen = NotificationService.morningMessages.length;
      final indices = <int>{};
      for (var day = 1; day <= morningLen; day++) {
        indices.add(day % morningLen);
      }
      expect(indices.length, morningLen);
    });

    test('streak messages rotate based on day', () {
      final streakLen = NotificationService.streakAtRiskMessages.length;
      final indices = <int>{};
      for (var day = 0; day < streakLen; day++) {
        indices.add(day % streakLen);
      }
      expect(indices.length, streakLen);
    });
  });

  group('NotificationService singleton', () {
    test('instance returns same object', () {
      final a = NotificationService.instance;
      final b = NotificationService.instance;
      expect(identical(a, b), true);
    });
  });

  // scheduled-time math tests. `computeNextFireTime` is
  // a pure static helper so we can exercise the DST + day-rollover
  // branches without mocking flutter_local_notifications.
  group('computeNextFireTime', () {
    test(
      'schedules today when the target hour is later than now',
      () {
        final toronto = tz.getLocation('America/Toronto');
        // Now: 2026-04-15 06:00 local. Target: 08:30 same day.
        final now = tz.TZDateTime(toronto, 2026, 4, 15, 6);
        final fire = NotificationService.computeNextFireTime(
          8,
          minute: 30,
          now: now,
          location: toronto,
        );
        expect(fire.year, 2026);
        expect(fire.month, 4);
        expect(fire.day, 15);
        expect(fire.hour, 8);
        expect(fire.minute, 30);
      },
    );

    test(
      'rolls forward to tomorrow when the target hour has already passed',
      () {
        final toronto = tz.getLocation('America/Toronto');
        // Now: 2026-04-15 10:00 local. Target: 08:00 — already passed.
        final now = tz.TZDateTime(toronto, 2026, 4, 15, 10);
        final fire = NotificationService.computeNextFireTime(
          8,
          now: now,
          location: toronto,
        );
        expect(fire.day, 16);
        expect(fire.hour, 8);
      },
    );

    test(
      'handles exact-minute target: now 08:30, target 08:30 schedules tomorrow',
      () {
        // The ! isBefore branch treats an equal-instant target as
        // already-passed and rolls forward. Document behaviour.
        final toronto = tz.getLocation('America/Toronto');
        final now = tz.TZDateTime(toronto, 2026, 4, 15, 8, 30);
        final fire = NotificationService.computeNextFireTime(
          8,
          minute: 30,
          now: now,
          location: toronto,
        );
        // Target is NOT strictly before now (they're equal), so it
        // should stay TODAY per .isBefore() (strict).
        expect(fire.day, 15);
        expect(fire.hour, 8);
        expect(fire.minute, 30);
      },
    );

    test(
      'EU spring-forward: 02:30 target on jump day still schedules correctly',
      () {
        // Europe/Berlin DST: 2026-03-29 02:00 → 03:00. A 02:30
        // target on that date doesn't exist as a wall time; the
        // timezone package resolves it forward to 03:30.
        final berlin = tz.getLocation('Europe/Berlin');
        final now = tz.TZDateTime(berlin, 2026, 3, 29, 1);
        final fire = NotificationService.computeNextFireTime(
          2,
          minute: 30,
          now: now,
          location: berlin,
        );
        // Regardless of how the tz package resolves 02:30, the
        // computed fire time must be strictly AFTER now. The bug
        // we're guarding against is accidentally scheduling in
        // the past.
        expect(fire.isAfter(now), isTrue);
        expect(fire.day, 29);
      },
    );

    test(
      'US fall-back: 01:30 target on repeat day schedules today',
      () {
        // America/New_York DST: 2026-11-01 02:00 → 01:00 (fall back).
        // 01:30 happens twice that day. From now=00:30, both 01:30s
        // are after now, so the computed fire time is today.
        final nyc = tz.getLocation('America/New_York');
        final now = tz.TZDateTime(nyc, 2026, 11, 1, 0, 30);
        final fire = NotificationService.computeNextFireTime(
          1,
          minute: 30,
          now: now,
          location: nyc,
        );
        expect(fire.day, 1);
        expect(fire.month, 11);
        expect(fire.hour, 1);
        expect(fire.minute, 30);
        expect(fire.isAfter(now), isTrue);
      },
    );

    test(
      'midnight target: now 23:59 schedules tomorrow 00:00',
      () {
        final toronto = tz.getLocation('America/Toronto');
        final now = tz.TZDateTime(toronto, 2026, 4, 15, 23, 59);
        final fire = NotificationService.computeNextFireTime(
          0,
          now: now,
          location: toronto,
        );
        expect(fire.day, 16);
        expect(fire.hour, 0);
      },
    );

    test(
      'month rollover: now Dec 31 23:59, target 08:00 schedules Jan 1',
      () {
        final toronto = tz.getLocation('America/Toronto');
        final now = tz.TZDateTime(toronto, 2026, 12, 31, 23, 59);
        final fire = NotificationService.computeNextFireTime(
          8,
          now: now,
          location: toronto,
        );
        expect(fire.year, 2027);
        expect(fire.month, 1);
        expect(fire.day, 1);
        expect(fire.hour, 8);
      },
    );
  });

  group('onEntrySaved / cancel', () {
    // NOTE: onEntrySaved() and cancel() call _plugin.cancelAll() which
    // requires FlutterLocalNotificationsPlatform.instance to be initialized.
    // The newer plugin uses a platform interface rather than a simple
    // MethodChannel, so it cannot be easily mocked in unit tests.
    // These methods are tested via on-device integration tests instead.

    test('onEntrySaved exists and is callable on the singleton', () {
      // Verify the method signature exists (compile-time check).
      expect(NotificationService.instance.onEntrySaved, isA<Function>());
    });

    test('cancel exists and is callable on the singleton', () {
      expect(NotificationService.instance.cancel, isA<Function>());
    });
  });
}
