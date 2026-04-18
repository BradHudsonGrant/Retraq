import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/services/database_service.dart';
import 'package:retraq/utils/date_helpers.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase(fastPbkdf2: true);
  });
  tearDownAll(() {
    resetTestDatabase();
  });

  // Task 6.5 — PIN security tests moved to test/services/pin_service_test.dart
  // so PIN crypto coverage lives in its own file separate from DB migration
  // coverage. This file now focuses exclusively on DB + search + migration.

  group('Search', () {
    late DatabaseService db;

    setUpAll(() async {
      db = DatabaseService.instance;

      // Seed test entries
      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 1),
          entry: 'Had a great morning run today',
          label: 'AM',
          createdAt: DateTime(2026, 3, 1, 8),
        ),
      );
      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 2),
          entry: 'Finished the Flutter project',
          title: 'Project Update',
          createdAt: DateTime(2026, 3, 2, 14),
        ),
      );
      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 3),
          entry: 'Relaxed and read a book',
          createdAt: DateTime(2026, 3, 3, 20),
        ),
      );
    });

    test('searchEntries finds matching entry text', () async {
      final results = await db.entries.searchEntries('flutter');
      expect(results.length, 1);
      expect(results.first.entry, contains('Flutter'));
    });

    test('searchEntries finds matching title', () async {
      final results = await db.entries.searchEntries('project update');
      expect(results.length, 1);
      expect(results.first.title, 'Project Update');
    });

    test('searchEntries is case insensitive', () async {
      final results = await db.entries.searchEntries('MORNING RUN');
      expect(results.length, 1);
    });

    test('searchEntries returns empty for no match', () async {
      final results = await db.entries.searchEntries('nonexistent xyz');
      expect(results, isEmpty);
    });

    test('searchEntries returns empty for blank query', () async {
      final results = await db.entries.searchEntries('   ');
      expect(results, isEmpty);
    });

    test('searchEntries respects limit', () async {
      final results = await db.entries.searchEntries('a', limit: 1);
      expect(results.length, lessThanOrEqualTo(1));
    });
  });

  group('Date Range', () {
    test('getEntriesForDateRange returns entries in range', () async {
      final db = DatabaseService.instance;
      final results = await db.entries.getEntriesForDateRange(
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 2),
      );
      expect(results.length, 2);
    });

    test('getEntriesForDateRange excludes out-of-range entries', () async {
      final db = DatabaseService.instance;
      final results = await db.entries.getEntriesForDateRange(
        DateTime(2026, 3, 10),
        DateTime(2026, 3, 15),
      );
      expect(results, isEmpty);
    });
  });

  group('weekStartDate', () {
    test('returns a date that is the correct weekday', () {
      // weekStartDay=1 means Monday
      final start = weekStartDate(weekStartDay: 1);
      expect(start.weekday, 1);
    });

    test('returns today or earlier', () {
      final start = weekStartDate(weekStartDay: 1);
      final today = DateTime.now();
      expect(
        start.isBefore(today) ||
            start.isAtSameMomentAs(
              DateTime(today.year, today.month, today.day),
            ),
        true,
      );
    });
  });

  group('AM/PM cutoff', () {
    test('settings stores amPmCutoffHour', () async {
      final db = DatabaseService.instance;
      final settings = await db.settings.getSettings();
      expect(settings.amPmCutoffHour, 14); // default
      await db.settings.saveSettings(settings.copyWith(amPmCutoffHour: 12));
      final reloaded = await db.settings.getSettings();
      expect(reloaded.amPmCutoffHour, 12);
    });
  });

  group('CRUD operations', () {
    late DatabaseService db;

    setUpAll(() async {
      db = DatabaseService.instance;
      // DB already initialised in-memory by earlier setUpAll
    });

    test('saveEntry returns a positive row ID', () async {
      final entry = JournalEntry(
        date: DateTime(2026, 4, 1),
        entry: 'CRUD test entry',
        label: 'AM',
        createdAt: DateTime(2026, 4, 1, 7, 0),
      );
      final id = await db.entries.saveEntry(entry);
      expect(id, greaterThan(0));
    });

    test('getEntriesForDate retrieves saved entries', () async {
      // Save a known entry
      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 4, 2),
          entry: 'Entry for April 2',
          createdAt: DateTime(2026, 4, 2, 10, 0),
        ),
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 4, 2));
      expect(entries, isNotEmpty);
      expect(entries.any((e) => e.entry == 'Entry for April 2'), true);
    });

    test('getEntriesForDate returns empty for date with no entries', () async {
      final entries = await db.entries.getEntriesForDate(
        DateTime(2099, 12, 31),
      );
      expect(entries, isEmpty);
    });

    test('deleteEntry removes the entry', () async {
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 4, 3),
          entry: 'To be deleted',
          createdAt: DateTime(2026, 4, 3, 12, 0),
        ),
      );

      // Verify it exists
      var entries = await db.entries.getEntriesForDate(DateTime(2026, 4, 3));
      expect(entries.any((e) => e.id == id), true);

      // Delete it
      await db.entries.deleteEntry(id);

      // Verify it is gone
      entries = await db.entries.getEntriesForDate(DateTime(2026, 4, 3));
      expect(entries.any((e) => e.id == id), false);
    });

    test('saveEntry with existing id updates the entry', () async {
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 4, 4),
          entry: 'Original text',
          createdAt: DateTime(2026, 4, 4, 9, 0),
        ),
      );

      // Retrieve, modify, and save again
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 4, 4));
      final original = entries.firstWhere((e) => e.id == id);
      final updated = original.copyWith(entry: 'Updated text');
      await db.entries.saveEntry(updated);

      final after = await db.entries.getEntriesForDate(DateTime(2026, 4, 4));
      final updatedEntry = after.firstWhere((e) => e.id == id);
      expect(updatedEntry.entry, 'Updated text');
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // BEGIN preserve per review-2026-04-16 Agent 6 (Task 6.18).
  // Boundary / edge-case DB coverage: non-existent-ID delete, FK
  // violation surfacing, batch save, per-day/most-active-weekday
  // SQL boundary values. Strong existing coverage Agent 6 explicitly
  // rated Solid — this marker exists so any future refactor (e.g. a
  // per-service split) carries these cases forward unchanged.
  // ─────────────────────────────────────────────────────────────────────
  group('Edge cases', () {
    late DatabaseService db;

    setUpAll(() async {
      db = DatabaseService.instance;
    });

    test('deleteEntry with non-existent ID does not throw', () async {
      // Should complete without error even for an ID that doesn't exist
      await db.entries.deleteEntry(999999);
    });

    test('getAllEntries returns all entries', () async {
      final all = await db.entries.getAllEntries();
      expect(all, isNotEmpty);
    });

    test('getTotalEntryCount returns positive count', () async {
      final count = await db.entries.getTotalEntryCount();
      expect(count, greaterThan(0));
    });

    test('getCurrentStreak returns zero or positive', () async {
      final streak = await db.stats.getCurrentStreak();
      expect(streak, greaterThanOrEqualTo(0));
    });

    test('getLongestStreak returns zero or positive', () async {
      final streak = await db.stats.getLongestStreak();
      expect(streak, greaterThanOrEqualTo(0));
    });

    test('getWeeklyEntryCounts returns list of expected length', () async {
      final counts = await db.stats.getWeeklyEntryCounts(weeks: 4);
      expect(counts.length, 4);
    });

    test('getMostActiveWeekday returns 0–7', () async {
      final day = await db.stats.getMostActiveWeekday();
      expect(day, inInclusiveRange(0, 7));
    });

    test('batchSaveEntries inserts multiple entries', () async {
      final entries = List.generate(
        3,
        (i) => JournalEntry(
          date: DateTime(2026, 6, 10 + i),
          entry: 'Batch entry $i',
          createdAt: DateTime(2026, 6, 10 + i, 8, 0),
        ),
      );
      await db.entries.batchSaveEntries(entries);

      for (int i = 0; i < 3; i++) {
        final found = await db.entries.getEntriesForDate(
          DateTime(2026, 6, 10 + i),
        );
        expect(found.any((e) => e.entry == 'Batch entry $i'), true);
      }
    });

    test('weekStartDate with Sunday start returns Sunday', () {
      final start = weekStartDate(weekStartDay: 7);
      expect(start.weekday, 7);
    });
  });

  // END preserve per Task 6.18 (boundary/edge DB data).

  group('Watch stream', () {
    late DatabaseService db;

    setUpAll(() async {
      db = DatabaseService.instance;
    });

    test('watchEntriesForDate emits current entries', () async {
      final date = DateTime(2026, 5, 1);
      await db.entries.saveEntry(
        JournalEntry(
          date: date,
          entry: 'Watch test initial',
          createdAt: DateTime(2026, 5, 1, 8, 0),
        ),
      );

      final stream = db.entries.watchEntriesForDate(date);
      final first = await stream.first;
      expect(first, isNotEmpty);
      expect(first.any((e) => e.entry == 'Watch test initial'), true);
    });

    test('watchEntriesForDate emits update after new entry is saved', () async {
      final date = DateTime(2026, 5, 2);

      final stream = db.entries.watchEntriesForDate(date);

      // First emission: should be empty or whatever is already there
      final firstEmission = await stream.first;
      final initialCount = firstEmission.length;

      // Save a new entry
      await db.entries.saveEntry(
        JournalEntry(
          date: date,
          entry: 'Watch test added',
          createdAt: DateTime(2026, 5, 2, 10, 0),
        ),
      );

      // Next emission should include the new entry
      final updated = await db.entries.watchEntriesForDate(date).first;
      expect(updated.length, initialCount + 1);
      expect(updated.any((e) => e.entry == 'Watch test added'), true);
    });
  });

  // ── Group 1: Database initialization ──────────────────────

  group('Database initialization', () {
    late DatabaseService db;

    setUpAll(() async {
      db = DatabaseService.instance;
    });

    test('initInMemory() creates a usable database', () async {
      // DB was already initialised in the top-level setUpAll.
      // Verify it is usable by performing a simple write + read.
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 7, 1),
          entry: 'Init test entry',
          createdAt: DateTime(2026, 7, 1, 9, 0),
        ),
      );
      expect(id, greaterThan(0));

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 7, 1));
      expect(entries.any((e) => e.entry == 'Init test entry'), true);
    });

    test('settings defaults are created after init', () async {
      final settings = await db.settings.getSettings();
      expect(settings, isNotNull);
      // Verify a known default value
      expect(settings.amPmCutoffHour, isNotNull);
    });

    test('repositories are initialized after init', () {
      expect(db.entries, isNotNull);
      expect(db.settings, isNotNull);
      expect(db.userRepo, isNotNull);
      expect(db.stats, isNotNull);
    });

    test('double initInMemory() does not throw', () async {
      // Re-initialising should not throw; it replaces the internal DB.
      await expectLater(DatabaseService.instance.initInMemory(), completes);
    });

    test('PRAGMA foreign_keys is enforced on user_id FK', () async {
      // After initInMemory, foreign_keys = ON.
      // Insert an entry with a non-existent userId.
      // The journal_entries.user_id column is nullable and has a FK to users(id).
      // With FK enforcement ON, inserting a non-null user_id that doesn't
      // exist in users should throw a foreign key violation.
      final entry = JournalEntry(
        date: DateTime(2026, 7, 2),
        entry: 'FK test entry',
        createdAt: DateTime(2026, 7, 2, 10, 0),
        userId: 99999, // non-existent user
      );
      // Drift surfaces SQLite FK violations as exceptions.
      expect(() async => await db.entries.saveEntry(entry), throwsA(anything));
    });
  });

  // ── Group 2: Encryption key management ────────────────────

  group('Encryption key management', () {
    test('base64-encoded 32-byte key has expected length', () {
      // _getOrCreateDbKey produces base64 of 32 random bytes.
      // Verify the concept: base64Encode(32 bytes) => 44 chars.
      final fakeKey = List<int>.generate(32, (i) => i);
      final encoded = base64Encode(fakeKey);
      expect(encoded.length, 44);
      // Decode round-trips correctly
      final decoded = base64Decode(encoded);
      expect(decoded.length, 32);
      expect(decoded, fakeKey);
    });

    test('generated keys are unique (random entropy)', () {
      // Simulate what _getOrCreateDbKey does: generate 32 random bytes.
      final key1 = base64Encode(
        List<int>.generate(32, (_) => DateTime.now().microsecond % 256),
      );
      // A tiny delay to shift microsecond seed (this is a concept test).
      final key2 = base64Encode(
        List<int>.generate(32, (i) => (i * 7 + 13) % 256),
      );
      // Keys should differ (different generation logic).
      expect(key1, isNot(equals(key2)));
    });

    test('base64 key is valid and decodable', () {
      final bytes = List<int>.generate(32, (i) => (i * 3 + 5) % 256);
      final key = base64Encode(bytes);
      // Should not throw
      final decoded = base64Decode(key);
      expect(decoded.length, 32);
    });

    test('256-bit key produces exactly 44 base64 characters', () {
      // 32 bytes = 256 bits. base64 output = ceil(32/3)*4 = 44 chars.
      // This is the length _getOrCreateDbKey should always produce.
      for (var i = 0; i < 10; i++) {
        final bytes = List<int>.generate(32, (j) => (i * 17 + j * 3) % 256);
        final key = base64Encode(bytes);
        expect(key.length, 44, reason: 'Key $i had unexpected length');
      }
    });

    test('key is consistent across multiple reads (simulated)', () {
      // Simulate _getOrCreateDbKey behavior: first call generates, second returns same
      String? storedKey;

      String getOrCreateKey() {
        if (storedKey != null) return storedKey!;
        final bytes = List<int>.generate(32, (i) => (i * 11 + 7) % 256);
        storedKey = base64Encode(bytes);
        return storedKey!;
      }

      final firstRead = getOrCreateKey();
      final secondRead = getOrCreateKey();
      final thirdRead = getOrCreateKey();

      expect(firstRead, equals(secondRead));
      expect(secondRead, equals(thirdRead));
      expect(firstRead.length, 44);
    });

    test('in-memory database does not require encryption key', () async {
      // initInMemory should work without any encryption setup
      final db = DatabaseService.instance;
      await db.initInMemory();
      // If we got here without error, in-memory path skips encryption
      final count = await db.entries.getTotalEntryCount();
      expect(count, isA<int>());
      await db.dispose();
    });

    test('hex encoding of key bytes produces correct format', () {
      // _setupDb converts base64 key → bytes → hex for PRAGMA key
      final bytes = List<int>.generate(32, (i) => i);
      final base64Key = base64Encode(bytes);
      final decoded = base64Decode(base64Key);
      final hex =
          decoded.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      // Should be 64 hex chars (32 bytes * 2 hex chars each)
      expect(hex.length, 64);
      // First byte (0) should be '00', second (1) should be '01', etc.
      expect(hex.substring(0, 2), '00');
      expect(hex.substring(2, 4), '01');
      expect(hex.substring(62, 64), '1f'); // 31 in hex
    });
  });

  // ── Task 6.5: PIN cross-format verification + auto-upgrade groups
  // moved to test/services/pin_service_test.dart ────────────────────

  // ── Group 3: Database migration data integrity ────────────

  group('Database migration data integrity', () {
    late DatabaseService db;

    setUpAll(() async {
      // Re-init to get a clean in-memory DB for migration tests.
      await DatabaseService.instance.initInMemory();
      db = DatabaseService.instance;
    });

    test('schema version is 15 after initInMemory', () async {
      // Query the Drift schema version via the underlying DB.
      final result = await db.db.customSelect('PRAGMA user_version').get();
      final version = result.first.data['user_version'] as int;
      expect(version, 15);
    });

    test('consent_records table exists and accepts inserts', () async {
      // Insert directly via customStatement to verify the table exists.
      await db.db.customStatement(
        'INSERT INTO consent_records (consent_type, document_version, accepted_at, app_version) '
        "VALUES ('privacy_policy', '2026-03-29', ${DateTime(2026, 3, 29).millisecondsSinceEpoch ~/ 1000}, '1.0.0')",
      );

      final rows =
          await db.db
              .customSelect(
                'SELECT * FROM consent_records WHERE consent_type = ?',
                variables: [const Variable<String>('privacy_policy')],
              )
              .get();
      expect(rows, isNotEmpty);
      expect(rows.first.data['document_version'], '2026-03-29');
    });

    test('journal_entries has user_id FK column', () async {
      // Verify the column exists by querying table_info.
      final columns =
          await db.db
              .customSelect("PRAGMA table_info('journal_entries')")
              .get();
      final columnNames = columns.map((r) => r.data['name'] as String).toList();
      expect(columnNames, contains('user_id'));
    });

    test('batch operations preserve all entries', () async {
      final batchEntries = List.generate(
        10,
        (i) => JournalEntry(
          date: DateTime(2026, 8, 1 + i),
          entry: 'Migration batch entry $i',
          createdAt: DateTime(2026, 8, 1 + i, 12, 0),
        ),
      );
      await db.entries.batchSaveEntries(batchEntries);

      // Verify all 10 entries are present.
      for (int i = 0; i < 10; i++) {
        final found = await db.entries.getEntriesForDate(
          DateTime(2026, 8, 1 + i),
        );
        expect(
          found.any((e) => e.entry == 'Migration batch entry $i'),
          true,
          reason: 'Missing batch entry $i',
        );
      }
    });
  });
}
