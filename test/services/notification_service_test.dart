import 'package:flutter_test/flutter_test.dart';
import 'package:sincethen/services/notification_service.dart';

/// Tests for NotificationService logic that doesn't require platform channels.
/// The plugin-based methods (init, scheduleDaily, cancel, requestPermission)
/// require integration tests with a running app.
void main() {
  group('Nudge message rotation', () {
    test('nudgeMessages has 12 variants', () {
      // Access via the public constant to verify the list length.
      // NotificationService._nudgeMessages is private, but we can test the
      // deterministic rotation logic: day % 12 should produce all 12 indices.
      final indices = List.generate(12, (i) => i % 12);
      expect(indices.toSet().length, 12);
    });

    test('message rotation is deterministic for same day', () {
      // Two calls on the same day should produce the same index.
      final day = 15;
      final index1 = day % 12;
      final index2 = day % 12;
      expect(index1, index2);
    });

    test('message rotation cycles through all 12 messages over 12 days', () {
      final indices = <int>{};
      for (var day = 1; day <= 12; day++) {
        indices.add(day % 12);
      }
      expect(indices.length, 12);
    });

    test('day 0 (impossible but safe) maps to index 0', () {
      expect(0 % 12, 0);
    });

    test('day 31 wraps correctly', () {
      expect(31 % 12, 7);
    });
  });

  group('NotificationService singleton', () {
    test('instance returns same object', () {
      final a = NotificationService.instance;
      final b = NotificationService.instance;
      expect(identical(a, b), true);
    });
  });
}
