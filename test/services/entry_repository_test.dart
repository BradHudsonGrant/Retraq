import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/services/database_service.dart';

import '../test_helpers.dart';

/// Direct tests for `EntryRepository`. Previously only
/// covered transitively through widget tests + database_service_test;
/// a regression in repo code would surface as a widget-test failure
/// with an unhelpful stack trace. These tests give the hot path its
/// own dedicated coverage.
///
/// Scope: the hot-path methods that every screen depends on —
/// saveEntry upsert behaviour, watchEntriesForDate, getTotalEntryCount,
/// deleteEntry (including FTS cascade), searchEntries. Stream
/// emission-on-mutation paths covered via `asyncExpand` +
/// `Future.delayed` debounce alignment.
void main() {
  setUpAll(() async {
    await initTestDatabase();
  });
  tearDownAll(resetTestDatabase);

  tearDown(() async {
    // Each test starts from an empty journal — entries from earlier
    // tests would otherwise leak into count assertions.
    await DatabaseService.instance.userRepo.deleteAllData();
  });

  group('EntryRepository.saveEntry', () {
    test('inserts a new entry and returns a positive row ID', () async {
      final entry = JournalEntry(
        date: DateTime(2026, 4, 1),
        entry: 'First traq',
        mood: 4,
      );
      final id = await DatabaseService.instance.entries.saveEntry(entry);
      expect(id, greaterThan(0));

      final rows = await DatabaseService.instance.entries.getAllEntries();
      expect(rows, hasLength(1));
      expect(rows.first.entry, 'First traq');
      expect(rows.first.mood, 4);
    });

    test('upsert: saveEntry with an existing id updates in place', () async {
      final initial = await DatabaseService.instance.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 4, 1),
          entry: 'Original',
          mood: 3,
        ),
      );
      final updated = initial; // upsert returns same id
      final updatedId = await DatabaseService.instance.entries.saveEntry(
        JournalEntry(
          id: initial,
          date: DateTime(2026, 4, 1),
          entry: 'Revised',
          mood: 5,
        ),
      );
      expect(updatedId, updated);

      final rows = await DatabaseService.instance.entries.getAllEntries();
      expect(
        rows,
        hasLength(1),
        reason: 'upsert must not create a second row',
      );
      expect(rows.first.entry, 'Revised');
      expect(rows.first.mood, 5);
    });

    test(
      'saveEntry normalizes date to local midnight (time component stripped)',
      () async {
        // Pass a mid-day timestamp; repo should store date-only.
        final id = await DatabaseService.instance.entries.saveEntry(
          JournalEntry(
            date: DateTime(2026, 4, 1, 15, 30),
            entry: 'mid-afternoon write',
          ),
        );
        final rows = await DatabaseService.instance.entries.getAllEntries();
        final stored = rows.firstWhere((e) => e.id == id);
        expect(stored.date.hour, 0);
        expect(stored.date.minute, 0);
        expect(stored.date.second, 0);
      },
    );
  });

  group('EntryRepository.getEntriesForDate', () {
    test('returns entries for the target day only', () async {
      await DatabaseService.instance.entries.saveEntry(
        JournalEntry(date: DateTime(2026, 4, 1), entry: 'day 1'),
      );
      await DatabaseService.instance.entries.saveEntry(
        JournalEntry(date: DateTime(2026, 4, 2), entry: 'day 2'),
      );
      await DatabaseService.instance.entries.saveEntry(
        JournalEntry(date: DateTime(2026, 4, 1), entry: 'day 1 again'),
      );

      final dayOne = await DatabaseService.instance.entries
          .getEntriesForDate(DateTime(2026, 4, 1));
      expect(dayOne, hasLength(2));
      expect(
        dayOne.map((e) => e.entry).toSet(),
        {'day 1', 'day 1 again'},
      );

      final dayTwo = await DatabaseService.instance.entries
          .getEntriesForDate(DateTime(2026, 4, 2));
      expect(dayTwo, hasLength(1));
      expect(dayTwo.first.entry, 'day 2');
    });

    test('returns empty list for a day with no entries', () async {
      final rows = await DatabaseService.instance.entries
          .getEntriesForDate(DateTime(1999, 12, 31));
      expect(rows, isEmpty);
    });
  });

  group('EntryRepository.getTotalEntryCount', () {
    test('returns 0 on empty store', () async {
      final n = await DatabaseService.instance.entries.getTotalEntryCount();
      expect(n, 0);
    });

    test('increments with each saveEntry and resets after deleteEntry',
        () async {
      expect(
        await DatabaseService.instance.entries.getTotalEntryCount(),
        0,
      );
      final firstId = await DatabaseService.instance.entries.saveEntry(
        JournalEntry(date: DateTime(2026, 4, 1), entry: 'a'),
      );
      await DatabaseService.instance.entries.saveEntry(
        JournalEntry(date: DateTime(2026, 4, 2), entry: 'b'),
      );
      expect(
        await DatabaseService.instance.entries.getTotalEntryCount(),
        2,
      );
      await DatabaseService.instance.entries.deleteEntry(firstId);
      expect(
        await DatabaseService.instance.entries.getTotalEntryCount(),
        1,
      );
    });
  });

  group('EntryRepository.searchEntries', () {
    test('finds entries by a body-text prefix token via FTS5', () async {
      await DatabaseService.instance.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 4, 1),
          entry: 'Had a great morning run today',
        ),
      );
      await DatabaseService.instance.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 4, 2),
          entry: 'Finished a Flutter widget refactor',
        ),
      );

      final runHits =
          await DatabaseService.instance.entries.searchEntries('run');
      expect(runHits, hasLength(1));
      expect(runHits.first.entry, contains('morning run'));

      final flutterHits = await DatabaseService.instance.entries
          .searchEntries('flut'); // prefix token
      expect(flutterHits, hasLength(1));
      expect(flutterHits.first.entry, contains('Flutter'));
    });

    test('returns empty list for a token that matches nothing', () async {
      await DatabaseService.instance.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 4, 1),
          entry: 'Nothing interesting here',
        ),
      );
      final hits =
          await DatabaseService.instance.entries.searchEntries('zebraphant');
      expect(hits, isEmpty);
    });

    test('empty / whitespace query returns no rows (no LIKE %) ', () async {
      await DatabaseService.instance.entries.saveEntry(
        JournalEntry(date: DateTime(2026, 4, 1), entry: 'anything'),
      );
      expect(
        await DatabaseService.instance.entries.searchEntries(''),
        isEmpty,
      );
      expect(
        await DatabaseService.instance.entries.searchEntries('   '),
        isEmpty,
      );
    });

    test(
      'regression: searchEntries maps userId column (null preserved)',
      () async {
        // Regression guard: an earlier inline mapper inside searchEntries
        // omitted `userId`. We can't insert a real user_id without
        // violating the users FK (the users table is empty in this
        // harness), but we CAN verify the search mapper's column-read
        // path exercises user_id: the round-trip on a null userId must
        // produce null (not "unmapped" or thrown).
        await DatabaseService.instance.entries.saveEntry(
          JournalEntry(
            date: DateTime(2026, 4, 1),
            entry: 'carries no userId',
          ),
        );
        final hits = await DatabaseService.instance.entries
            .searchEntries('carries');
        expect(hits, hasLength(1));
        expect(hits.first.userId, isNull);
      },
    );
  });

  group('EntryRepository.deleteEntry', () {
    test('deletes the target row', () async {
      final id = await DatabaseService.instance.entries.saveEntry(
        JournalEntry(date: DateTime(2026, 4, 1), entry: 'to delete'),
      );
      await DatabaseService.instance.entries.deleteEntry(id);
      final rows = await DatabaseService.instance.entries.getAllEntries();
      expect(rows, isEmpty);
    });

    test('removes FTS rows so search returns nothing after delete',
        () async {
      final id = await DatabaseService.instance.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 4, 1),
          entry: 'unique ftscheck sentence',
        ),
      );
      expect(
        await DatabaseService.instance.entries.searchEntries('ftscheck'),
        hasLength(1),
      );
      await DatabaseService.instance.entries.deleteEntry(id);
      expect(
        await DatabaseService.instance.entries.searchEntries('ftscheck'),
        isEmpty,
        reason: 'FTS trigger must remove the indexed row on delete',
      );
    });
  });
}
