// ignore_for_file: prefer_single_quotes
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/utils/date_helpers.dart';

void main() {
  group('formatHour', () {
    test('returns 12:00 AM for hour 0 (midnight)', () {
      expect(formatHour(0), '12:00 AM');
    });

    test('returns 1:00 AM for hour 1', () {
      expect(formatHour(1), '1:00 AM');
    });

    test('returns 11:00 AM for hour 11', () {
      expect(formatHour(11), '11:00 AM');
    });

    test('returns 12:00 PM for hour 12 (noon)', () {
      expect(formatHour(12), '12:00 PM');
    });

    test('returns 1:00 PM for hour 13', () {
      expect(formatHour(13), '1:00 PM');
    });

    test('returns 11:00 PM for hour 23', () {
      expect(formatHour(23), '11:00 PM');
    });
  });

  group('formatDateLabel', () {
    test('returns "Today" for today (capitalized)', () {
      final now = DateTime.now();
      expect(formatDateLabel(now), 'Today');
    });

    test('returns "today" for today (lowercase)', () {
      final now = DateTime.now();
      expect(formatDateLabel(now, capitalize: false), 'today');
    });

    test('returns "Yesterday" for yesterday (capitalized)', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(formatDateLabel(yesterday), 'Yesterday');
    });

    test('returns "yesterday" for yesterday (lowercase)', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(formatDateLabel(yesterday, capitalize: false), 'yesterday');
    });

    test('returns day name for dates 2-6 days ago', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final label = formatDateLabel(threeDaysAgo);
      // Should be a capitalized day name like "Monday", "Tuesday", etc.
      expect(
        ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
        contains(label),
      );
    });

    test('returns day name as-is when capitalize is false (intl already capitalizes)', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final label = formatDateLabel(twoDaysAgo, capitalize: false);
      // intl returns day names already capitalized (e.g., "Sunday"),
      // and capitalize:false only skips the explicit uppercasing step
      expect(
        ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
        contains(label),
      );
    });

    test('returns "MMM d" format for dates 7+ days ago', () {
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
      final label = formatDateLabel(twoWeeksAgo);
      // Should match pattern like "Mar 17" — starts with uppercase letter
      expect(label, matches(RegExp(r'^[A-Z][a-z]{2} \d{1,2}$')));
    });

    test('capitalizes by default', () {
      final now = DateTime.now();
      final label = formatDateLabel(now);
      expect(label[0], label[0].toUpperCase());
    });
  });

  group('startOfNextMonth', () {
    test('returns Feb 1 for January', () {
      expect(startOfNextMonth(DateTime(2026, 1, 15)), DateTime(2026, 2));
    });

    test('handles December -> January year rollover', () {
      expect(startOfNextMonth(DateTime(2026, 12, 1)), DateTime(2027, 1));
    });

    test('returns first day regardless of input day', () {
      final result = startOfNextMonth(DateTime(2026, 3, 31));
      expect(result.day, 1);
      expect(result.month, 4);
    });
  });

  group('strftimeYW', () {
    test('returns correct week label for known date', () {
      // 2026-01-05 is a Monday in week 01
      expect(strftimeYW(DateTime(2026, 1, 5)), '2026-01');
    });

    test('returns week 00 for Jan 1 when it is not Monday', () {
      // 2026-01-01 is Thursday — before the first Monday
      expect(strftimeYW(DateTime(2026, 1, 1)), '2026-00');
    });

    test('returns consistent label for same week', () {
      // Mon and Fri of the same week should match
      final mon = DateTime(2026, 3, 30); // Monday
      final fri = DateTime(2026, 4, 3);  // Friday
      expect(strftimeYW(mon), strftimeYW(fri));
    });
  });

  group('weekStartDate', () {
    test('returns a date that is the correct weekday', () {
      final result = weekStartDate(weekStartDay: DateTime.monday);
      expect(result.weekday, DateTime.monday);
    });

    test('returns today or earlier', () {
      final result = weekStartDate(weekStartDay: DateTime.monday);
      final today = DateTime.now();
      expect(result.isBefore(today) || result.isAtSameMomentAs(DateTime(today.year, today.month, today.day)), true);
    });

    test('respects Sunday as week start', () {
      final result = weekStartDate(weekStartDay: DateTime.sunday);
      expect(result.weekday, DateTime.sunday);
    });
  });
}
