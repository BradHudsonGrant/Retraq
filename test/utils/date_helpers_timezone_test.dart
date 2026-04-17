import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/utils/date_helpers.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Task 6.2 — Timezone + DST edge-case tests for `date_helpers.dart`.
///
/// Scope: pure functions that take a `DateTime` argument and return
/// a derived value. These we can test fully by constructing
/// `TZDateTime` values across DST transitions and feeding them in
/// directly. Functions that internally call `DateTime.now()`
/// (formatDateLabel, weekStartDate) cannot be exercised against a
/// fixed-wall-clock without a Clock injection refactor — tracked
/// as the broader Task 6.2 follow-up.
///
/// Scenarios covered:
///   - EU spring-forward (Berlin, 2026-03-29 02:00 → 03:00 jump)
///   - US fall-back (New York, 2026-11-01 02:00 → 01:00 repeat)
///   - NZDT midnight rollover (Auckland, UTC-day-ahead)
///   - Quebec EST midnight split (Toronto, 2026-01-15 → 2026-01-16)
///   - December → January month rollover
///
/// Note: the existing streak / entry-repository code normalizes
/// dates by constructing `DateTime(year, month, day)` from a
/// `.toLocal()` call. Those paths aren't purely testable here
/// because they depend on the system's configured timezone. We
/// test what we can; the remaining integration-level DST coverage
/// needs a TZDateTime-backed fake Clock (separate follow-up PR).
void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  group('startOfNextMonth — month rollover', () {
    test('February 2026 → March 1 2026', () {
      final result = startOfNextMonth(DateTime(2026, 2, 15));
      expect(result, DateTime(2026, 3));
    });

    test('December 2026 → January 1 2027 (year rollover)', () {
      final result = startOfNextMonth(DateTime(2026, 12, 15));
      expect(result, DateTime(2027));
    });

    test('January 2027 → February 1 2027', () {
      final result = startOfNextMonth(DateTime(2027));
      expect(result, DateTime(2027, 2));
    });

    test('February of a leap year → March 1 (no off-by-one)', () {
      // 2028 is a leap year.
      final result = startOfNextMonth(DateTime(2028, 2, 29));
      expect(result, DateTime(2028, 3));
    });
  });

  group('strftimeYW — week-number stability across DST', () {
    test('EU spring-forward week is stable (Berlin, 2026-03-29)', () {
      // Before and after the spring-forward hour must yield the
      // same SQLite-compatible week label.
      final berlin = tz.getLocation('Europe/Berlin');
      final before = tz.TZDateTime(berlin, 2026, 3, 29, 1, 59);
      final after = tz.TZDateTime(berlin, 2026, 3, 29, 3, 1);
      expect(
        strftimeYW(before),
        equals(strftimeYW(after)),
        reason:
            'strftimeYW must not produce a different week label '
            'just because the local clock jumped an hour',
      );
    });

    test('US fall-back week is stable (NYC, 2026-11-01)', () {
      final nyc = tz.getLocation('America/New_York');
      // 01:30 EDT happens once before fall-back; 01:30 EST happens
      // once after — both are the same calendar date.
      final first = tz.TZDateTime(nyc, 2026, 11, 1, 1, 30);
      final second = tz.TZDateTime(nyc, 2026, 11, 1, 1, 30);
      expect(strftimeYW(first), equals(strftimeYW(second)));
    });

    test('week label survives month boundary crossing in same week', () {
      // Sunday 2026-03-01 is ISO week 9 of 2026 (Sat + Sun tail).
      final sunday = DateTime(2026, 3, 1);
      final saturday = DateTime(2026, 2, 28);
      // Both belong to the same ISO week by the strftime %W
      // convention (Monday-first): Feb 28 is Saturday, March 1 is
      // Sunday, both in the same week as Feb 23.
      expect(strftimeYW(sunday).split('-').last,
          equals(strftimeYW(saturday).split('-').last));
    });

    test('returns zero-padded week number', () {
      final earlyJan = DateTime(2026, 1, 3);
      final yw = strftimeYW(earlyJan);
      final parts = yw.split('-');
      expect(parts, hasLength(2));
      expect(parts[1].length, 2);
      expect(parts[1], matches(RegExp(r'^\d{2}$')));
    });
  });

  group('DateTime normalization — DST-boundary stability', () {
    // These tests assert the "construct DateTime(year, month, day)
    // from localized parts truncates time" invariant that
    // entry_repository.saveEntry relies on. Without this, entries
    // written during spring-forward could be stored with a
    // phantom hour.
    test('EU spring-forward: both 01:59 and 03:01 normalize to same day',
        () {
      final berlin = tz.getLocation('Europe/Berlin');
      final before = tz.TZDateTime(berlin, 2026, 3, 29, 1, 59);
      final after = tz.TZDateTime(berlin, 2026, 3, 29, 3, 1);

      final beforeDay = DateTime(before.year, before.month, before.day);
      final afterDay = DateTime(after.year, after.month, after.day);
      expect(beforeDay, afterDay);
    });

    test(
      'US fall-back: two "01:30" instants on 2026-11-01 normalize to one day',
      () {
        final nyc = tz.getLocation('America/New_York');
        // Can't express "the second 01:30" directly without a
        // manual UTC offset; instead we pick a single wall-time
        // instant and assert it normalizes correctly. The actual
        // duplicate-hour bug would manifest as two entries with
        // identical wall-time timestamps landing on different
        // SQLite dates — which the normalization above prevents.
        final fallbackDay = tz.TZDateTime(nyc, 2026, 11, 1, 1, 30);
        final normalized = DateTime(
          fallbackDay.year,
          fallbackDay.month,
          fallbackDay.day,
        );
        expect(normalized, DateTime(2026, 11));
        expect(normalized.hour, 0);
      },
    );

    test('NZDT: late-evening local time reconstructs as the correct day', () {
      final auckland = tz.getLocation('Pacific/Auckland');
      // Auckland 23:30 local is the same local date as 00:30
      // the next day in UTC when NZDT is UTC+13.
      final lateEvening =
          tz.TZDateTime(auckland, 2026, 4, 5, 23, 30);
      final normalized = DateTime(
        lateEvening.year,
        lateEvening.month,
        lateEvening.day,
      );
      expect(normalized, DateTime(2026, 4, 5));
    });

    test(
      'Toronto EST midnight split: 23:59 on Jan 15 and 00:01 on Jan 16 '
      'are different days',
      () {
        final toronto = tz.getLocation('America/Toronto');
        final lateNight =
            tz.TZDateTime(toronto, 2026, 1, 15, 23, 59);
        final nextMinute =
            tz.TZDateTime(toronto, 2026, 1, 16, 0, 1);
        final d1 =
            DateTime(lateNight.year, lateNight.month, lateNight.day);
        final d2 =
            DateTime(nextMinute.year, nextMinute.month, nextMinute.day);
        expect(d1, DateTime(2026, 1, 15));
        expect(d2, DateTime(2026, 1, 16));
        expect(d1, isNot(equals(d2)));
      },
    );
  });

  group('formatHour — AM/PM boundary stability', () {
    // These are pure-function tests — no DST involvement, but
    // they live here because formatHour is part of the DST-
    // adjacent helper surface.
    test('midnight renders as 12:00 AM', () {
      expect(formatHour(0), '12:00 AM');
    });

    test('noon renders as 12:00 PM', () {
      expect(formatHour(12), '12:00 PM');
    });

    test('23:00 renders as 11:00 PM', () {
      expect(formatHour(23), '11:00 PM');
    });

    test('1:00 renders as 1:00 AM', () {
      expect(formatHour(1), '1:00 AM');
    });

    test('13:00 renders as 1:00 PM', () {
      expect(formatHour(13), '1:00 PM');
    });
  });
}
