import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/services/database_service.dart';

import '../test_helpers.dart';

/// concurrent-write regression tests for
/// EntryRepository.
///
/// Scope: race-condition surface where a user mashes the save button,
/// a widget auto-save fires during an import, or parallel saves from
/// different UI paths hit saveEntry() at the same time. Drift wraps
/// each write in a transaction internally, but we still need explicit
/// coverage that 100 simultaneous saveEntry() calls produce exactly
/// 100 rows — not 95 (lost write) or 105 (double-committed).
///
/// Stream-ordering races (HomeScreen / StatsScreen subscriber
/// out-of-order emissions) are harder to test without FakeAsync; they
/// live in a separate follow-up. Lockout controller races are covered
/// in the dedicated lockout_controller_test.dart expansion.
void main() {
  setUpAll(() async {
    await initTestDatabase();
  });
  tearDownAll(resetTestDatabase);

  tearDown(() async {
    // Fresh DB per test — concurrent-write counts are meaningless
    // otherwise.
    await DatabaseService.instance.userRepo.deleteAllData();
  });

  group('EntryRepository concurrent saves', () {
    test('100 concurrent saveEntry calls produce 100 distinct rows',
        () async {
      final base = DateTime(2026, 6, 1);
      final futures = List<Future<int>>.generate(
        100,
        (i) => DatabaseService.instance.entries.saveEntry(
          JournalEntry(
            date: base,
            entry: 'Concurrent entry $i',
            createdAt: base.add(Duration(milliseconds: i)),
          ),
        ),
      );
      await Future.wait(futures);

      final count =
          await DatabaseService.instance.entries.getTotalEntryCount();
      expect(count, 100,
          reason:
              '100 concurrent saveEntry must produce exactly 100 rows. '
              'Fewer means a transaction swallowed a write; more means '
              'a double-commit race.');
    });

    test(
      'concurrent saves on the SAME day do not lose rows',
      () async {
        // Same-day concurrency is the realistic scenario: user rapidly
        // saves five entries for today.
        final day = DateTime(2026, 6, 10);
        final futures = List<Future<int>>.generate(
          20,
          (i) => DatabaseService.instance.entries.saveEntry(
            JournalEntry(
              date: day,
              entry: 'Rapid-fire $i',
              createdAt: DateTime(2026, 6, 10, 9, i),
            ),
          ),
        );
        final ids = await Future.wait(futures);
        expect(ids.toSet().length, 20,
            reason: 'every saveEntry must return a unique row ID');

        final entries = await DatabaseService.instance.entries
            .getEntriesForDate(day);
        expect(entries, hasLength(20));
      },
    );

    test('concurrent deletes do not double-remove', () async {
      // Seed 50 rows, delete them all concurrently, expect 0 remaining.
      final base = DateTime(2026, 7, 1);
      final ids = <int>[];
      for (int i = 0; i < 50; i++) {
        final id = await DatabaseService.instance.entries.saveEntry(
          JournalEntry(
            date: base,
            entry: 'To delete $i',
            createdAt: base.add(Duration(milliseconds: i)),
          ),
        );
        ids.add(id);
      }
      expect(
        await DatabaseService.instance.entries.getTotalEntryCount(),
        50,
      );

      final futures =
          ids.map((id) => DatabaseService.instance.entries.deleteEntry(id));
      await Future.wait(futures);

      expect(
        await DatabaseService.instance.entries.getTotalEntryCount(),
        0,
        reason:
            'concurrent deleteEntry calls must not double-remove (would '
            'throw on second delete of same row) and must not miss any',
      );
    });

    test(
      'interleaved saves + deletes converge to the correct row count',
      () async {
        // 50 saves, 25 deletes interleaved — final count must be 25.
        final base = DateTime(2026, 8, 1);
        final ops = <Future<Object?>>[];
        for (int i = 0; i < 25; i++) {
          ops.add(
            DatabaseService.instance.entries.saveEntry(
              JournalEntry(
                date: base,
                entry: 'Interleaved-save $i',
                createdAt: base.add(Duration(milliseconds: i)),
              ),
            ),
          );
        }
        await Future.wait(ops);
        // Now query the IDs so we can schedule concurrent deletes.
        final entries =
            await DatabaseService.instance.entries.getEntriesForDate(base);
        expect(entries, hasLength(25));

        // Delete half concurrently with another 25 saves.
        final mixed = <Future<Object?>>[];
        for (int i = 0; i < 13; i++) {
          mixed.add(
            DatabaseService.instance.entries.deleteEntry(entries[i].id!),
          );
        }
        for (int i = 0; i < 25; i++) {
          mixed.add(
            DatabaseService.instance.entries.saveEntry(
              JournalEntry(
                date: base,
                entry: 'Phase-2 save $i',
                createdAt:
                    base.add(Duration(milliseconds: 1000 + i)),
              ),
            ),
          );
        }
        await Future.wait(mixed);

        // Expected: 25 - 13 + 25 = 37 rows.
        expect(
          await DatabaseService.instance.entries.getTotalEntryCount(),
          37,
          reason:
              'interleaved save/delete must converge to 25-13+25=37 rows '
              'regardless of execution order',
        );
      },
    );
  });

  group('EntryRepository concurrent read+write', () {
    test(
      'getTotalEntryCount during concurrent saves returns a valid int',
      () async {
        // Fire 30 saves + 10 count reads in parallel. Each count read
        // should return some value in 0..30 (never negative, never
        // NaN, never throw).
        final base = DateTime(2026, 9, 1);
        final ops = <Future<Object?>>[];
        for (int i = 0; i < 30; i++) {
          ops.add(
            DatabaseService.instance.entries.saveEntry(
              JournalEntry(
                date: base,
                entry: 'Concurrent-RW $i',
                createdAt: base.add(Duration(milliseconds: i)),
              ),
            ),
          );
        }
        final readResults = <int>[];
        for (int i = 0; i < 10; i++) {
          ops.add(
            DatabaseService.instance.entries
                .getTotalEntryCount()
                .then(readResults.add),
          );
        }
        await Future.wait(ops);

        expect(readResults, hasLength(10));
        for (final n in readResults) {
          expect(n, greaterThanOrEqualTo(0));
          expect(n, lessThanOrEqualTo(30));
        }
        // Final count is deterministic.
        expect(
          await DatabaseService.instance.entries.getTotalEntryCount(),
          30,
        );
      },
    );
  });
}
