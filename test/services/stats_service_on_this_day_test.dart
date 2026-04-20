// ignore_for_file: prefer_single_quotes

import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/services/database_service.dart';

import '../test_helpers.dart';

/// direct tests for StatsService.onThisDayEntries.
///
/// The rule previously lived inline inside stats_screen.dart (pre-
/// extraction), so there was no way to exercise leap-day or empty-
/// state behaviour without booting the full widget tree. Now that
/// it's on the service, a handful of focused cases pin:
///
/// - Entries from exactly one year ago surface
/// - Entries from TWO years ago (on a yearsBack=1 call) do NOT
/// - Feb 29 requested from a non-leap target year snaps to Feb 28
///   (never silently jumps to Mar 1 via Dart's DateTime normalisation)
/// - Empty state returns an empty list, never null
/// - Multiple entries on the target day are ALL returned, not just
///   the first one — screen may show only the first but the service
///   must expose the full set so future UX (carousel, list) can
///   consume it without a second round-trip.
void main() {
  setUpAll(() async {
    await initTestDatabase();
  });
  tearDownAll(resetTestDatabase);

  tearDown(() async {
    await DatabaseService.instance.userRepo.deleteAllData();
  });

  group('StatsService.onThisDayEntries', () {
    test('returns entries from exactly one year ago when yearsBack=1',
        () async {
      final today = DateTime(2026, 5, 15);
      final lastYear = DateTime(2025, 5, 15);
      await DatabaseService.instance.entries.saveEntry(
        JournalEntry(
          date: lastYear,
          entry: 'a year ago today',
          createdAt: lastYear.add(const Duration(hours: 10)),
        ),
      );
      await DatabaseService.instance.entries.saveEntry(
        JournalEntry(
          date: DateTime(2025, 5, 14),
          entry: 'a day too early',
          createdAt: DateTime(2025, 5, 14, 10),
        ),
      );

      final result = await DatabaseService.instance.stats
          .onThisDayEntries(today: today);
      expect(result, hasLength(1));
      expect(result.first.entry, equals('a year ago today'));
    });

    test('yearsBack=2 reaches two years back and ignores year 1', () async {
      final today = DateTime(2026, 6, 1);
      await DatabaseService.instance.entries.saveEntry(
        JournalEntry(
          date: DateTime(2024, 6, 1),
          entry: 'two years ago',
          createdAt: DateTime(2024, 6, 1, 9),
        ),
      );
      await DatabaseService.instance.entries.saveEntry(
        JournalEntry(
          date: DateTime(2025, 6, 1),
          entry: 'one year ago',
          createdAt: DateTime(2025, 6, 1, 9),
        ),
      );

      final result = await DatabaseService.instance.stats
          .onThisDayEntries(today: today, yearsBack: 2);
      expect(result, hasLength(1));
      expect(result.first.entry, equals('two years ago'));
    });

    test(
      'Feb 29 from a non-leap target year snaps to Feb 28, not Mar 1',
      () async {
        // 2024 is leap, 2025 is not. Requesting "today = 2028-02-29,
        // yearsBack=3" targets 2025-02-29, which Dart normalises to
        // 2025-03-01 if you write DateTime(2025, 2, 29). The service
        // must snap to 2025-02-28 to keep the surface on the right
        // calendar day.
        final today = DateTime(2028, 2, 29); // leap year
        await DatabaseService.instance.entries.saveEntry(
          JournalEntry(
            date: DateTime(2025, 2, 28),
            entry: 'snapped to feb 28',
            createdAt: DateTime(2025, 2, 28, 9),
          ),
        );
        await DatabaseService.instance.entries.saveEntry(
          JournalEntry(
            date: DateTime(2025, 3, 1),
            entry: 'wrong! would appear if we fell through',
            createdAt: DateTime(2025, 3, 1, 9),
          ),
        );

        final result = await DatabaseService.instance.stats
            .onThisDayEntries(today: today, yearsBack: 3);
        expect(result, hasLength(1));
        expect(result.first.entry, equals('snapped to feb 28'),
            reason:
                'Feb 29 request on a non-leap target year must snap to '
                'Feb 28 — never jump to Mar 1.');
      },
    );

    test(
      'Feb 29 from a leap target year returns the Feb 29 entry directly',
      () async {
        // 2032 is leap. Requesting yearsBack=4 from 2036-02-29 targets
        // 2032-02-29 which IS a real calendar day.
        final today = DateTime(2036, 2, 29);
        await DatabaseService.instance.entries.saveEntry(
          JournalEntry(
            date: DateTime(2032, 2, 29),
            entry: 'actual leap day',
            createdAt: DateTime(2032, 2, 29, 9),
          ),
        );

        final result = await DatabaseService.instance.stats
            .onThisDayEntries(today: today, yearsBack: 4);
        expect(result, hasLength(1));
        expect(result.first.entry, equals('actual leap day'));
      },
    );

    test('empty state returns an empty list, not null, when no matches',
        () async {
      final today = DateTime(2026, 11, 12);
      // No entries seeded at all — clean DB.
      final result = await DatabaseService.instance.stats
          .onThisDayEntries(today: today);
      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('returns ALL entries on the target day (caller can paginate)',
        () async {
      // The screen UI shows the first entry only, but the service
      // must return the full list so future UX can iterate without a
      // second round-trip.
      final today = DateTime(2026, 9, 9);
      final target = DateTime(2025, 9, 9);
      for (var i = 0; i < 3; i++) {
        await DatabaseService.instance.entries.saveEntry(
          JournalEntry(
            date: target,
            entry: 'memory #$i',
            createdAt: target.add(Duration(hours: 8 + i)),
          ),
        );
      }
      final result = await DatabaseService.instance.stats
          .onThisDayEntries(today: today);
      expect(result, hasLength(3));
      final texts = result.map((e) => e.entry).toSet();
      expect(texts, {'memory #0', 'memory #1', 'memory #2'});
    });

    test('asserts yearsBack is positive', () {
      expect(
        () =>
            DatabaseService.instance.stats.onThisDayEntries(yearsBack: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () =>
            DatabaseService.instance.stats.onThisDayEntries(yearsBack: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
