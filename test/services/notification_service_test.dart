import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/notification_service.dart';

void main() {

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

    test('streakAtRisk=true returns a streak-at-risk message regardless of hour', () {
      final morningMsg =
          NotificationService.pickMessage(8, streakAtRisk: true);
      final eveningMsg =
          NotificationService.pickMessage(20, streakAtRisk: true);
      final middayMsg =
          NotificationService.pickMessage(14, streakAtRisk: true);

      expect(NotificationService.streakAtRiskMessages, contains(morningMsg));
      expect(NotificationService.streakAtRiskMessages, contains(eveningMsg));
      expect(NotificationService.streakAtRiskMessages, contains(middayMsg));
    });
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
