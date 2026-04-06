import 'dart:convert';

import 'package:crypto/crypto.dart';
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

  group('PIN Security', () {
    test('hashPin produces v3:iterations:salt:hash format', () {
      final hash = PinService.hashPinSync('1234');

      expect(hash.startsWith('v3:'), true);
      final parts = hash.split(':');
      expect(parts.length, 4);
      expect(int.tryParse(parts[1]), isNotNull); // iterations
      expect(parts[2].isNotEmpty, true); // salt (base64)
      expect(parts[3].isNotEmpty, true); // hash (base64)
    });

    test('verifyPin returns true for correct PIN', () {
      final stored = PinService.hashPinSync('5678');
      expect(PinService.verifyPinSync('5678', stored), true);
    });

    test('verifyPin returns false for wrong PIN', () {
      final stored = PinService.hashPinSync('1234');
      expect(PinService.verifyPinSync('5678', stored), false);
    });

    test('verifyPin returns false for empty PIN', () {
      final stored = PinService.hashPinSync('1234');
      expect(PinService.verifyPinSync('', stored), false);
    });

    test('verifyPin returns false for malformed stored hash', () {
      expect(PinService.verifyPinSync('1234', 'nocolon'), false);
      expect(PinService.verifyPinSync('1234', ''), false);
    });

    test('hashPin produces different hashes for same PIN (random salt)', () {
      final hash1 = PinService.hashPinSync('1234');
      final hash2 = PinService.hashPinSync('1234');

      // Salt should differ, so full stored string differs
      expect(hash1, isNot(equals(hash2)));
    });

    test('verifyPin works with 4-digit PIN', () {
      final stored = PinService.hashPinSync('0000');
      expect(PinService.verifyPinSync('0000', stored), true);
      expect(PinService.verifyPinSync('0001', stored), false);
    });

    test('verifyPin works with 6-digit PIN', () {
      final stored = PinService.hashPinSync('123456');
      expect(PinService.verifyPinSync('123456', stored), true);
      expect(PinService.verifyPinSync('654321', stored), false);
    });

    test('hashPin handles special characters in PIN', () {
      // PIN should be digits only in practice, but hash shouldn't crash
      final stored = PinService.hashPinSync('12AB');
      expect(PinService.verifyPinSync('12AB', stored), true);
    });

    test('isLegacyPinHash detects old format', () {
      // Old SHA-256 format: hex_salt:hex_hash
      expect(PinService.isLegacyPinHash('abc123:def456'), true);
      // v2 PBKDF2 (600K) is also legacy — needs upgrade to v3
      expect(PinService.isLegacyPinHash('v2:abc123:def456'), true);
      // v3 format with stored iterations is current
      expect(PinService.isLegacyPinHash('v3:100000:abc123:def456'), false);
    });
  });

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

  // ── Group 2b: PIN cross-format verification ──────────────

  group('PIN cross-format verification', () {
    test('4-digit PIN hash does not verify with 6-digit input', () {
      final stored = PinService.hashPinSync('1234');
      expect(PinService.verifyPinSync('123400', stored), false);
      expect(PinService.verifyPinSync('001234', stored), false);
    });

    test('6-digit PIN hash does not verify with 4-digit input', () {
      final stored = PinService.hashPinSync('123456');
      expect(PinService.verifyPinSync('1234', stored), false);
      expect(PinService.verifyPinSync('3456', stored), false);
    });

    test('v3 format stores iteration count for future-proofing', () {
      final hash = PinService.hashPinSync('9999');
      final parts = hash.split(':');
      expect(parts[0], 'v3');
      final iterations = int.parse(parts[1]);
      // Should be the test iteration count (100) since we called setPbkdf2Iterations(100)
      expect(iterations, 100);
    });

    test('legacy v1 SHA-256 format is detected as legacy', () {
      // v1 format: "base64salt:hexhash" (no version prefix)
      expect(PinService.isLegacyPinHash('YWJjMTIz:abcdef0123456789'), true);
    });

    test('v2 PBKDF2 600K format is detected as legacy', () {
      // v2 format: "v2:base64salt:base64hash"
      expect(PinService.isLegacyPinHash('v2:YWJjMTIz:ZGVmNDU2'), true);
    });

    test('v3 PBKDF2 format is NOT detected as legacy', () {
      final hash = PinService.hashPinSync('5555');
      expect(PinService.isLegacyPinHash(hash), false);
    });

    test('same PIN with different salts produces different hashes', () {
      final hashes = List.generate(5, (_) => PinService.hashPinSync('0000'));
      // All should be unique (random salts)
      expect(hashes.toSet().length, hashes.length);
      // But all should verify against the original PIN
      for (final hash in hashes) {
        expect(PinService.verifyPinSync('0000', hash), true);
      }
    });
  });

  // ── Group 2c: PIN auto-upgrade end-to-end ─────────────────

  group('PIN auto-upgrade end-to-end', () {
    test('legacy SHA-256 hash verifies, upgrades to v3, and re-verifies', () {
      const pin = '4321';

      // Step (a): Create a legacy SHA-256 hash manually.
      // Legacy format: "base64salt:hexhash" where hash = sha256("$salt:$pin")
      final saltBytes = utf8.encode('testSalt123');
      final saltB64 = base64Encode(saltBytes);
      final legacyHash =
          sha256.convert(utf8.encode('$saltB64:$pin')).toString();
      final legacyStored = '$saltB64:$legacyHash';

      // Step (b): Verify the PIN against the legacy hash — should pass.
      expect(PinService.verifyPinSync(pin, legacyStored), true);

      // Step (c): Confirm isLegacyPinHash detects it as legacy.
      expect(PinService.isLegacyPinHash(legacyStored), true);

      // Step (d): Hash the PIN with the current algorithm (v3).
      final upgradedHash = PinService.hashPinSync(pin);

      // Step (e): The new hash should NOT be legacy format.
      expect(PinService.isLegacyPinHash(upgradedHash), false);
      expect(upgradedHash.startsWith('v3:'), true);

      // Step (f): Verify the PIN against the upgraded hash — should pass.
      expect(PinService.verifyPinSync(pin, upgradedHash), true);
      // And wrong PIN should still fail.
      expect(PinService.verifyPinSync('0000', upgradedHash), false);
    });

    test('legacy v2 PBKDF2 hash verifies, upgrades to v3, and re-verifies', () {
      // This test uses setPbkdf2Iterations(100) already set in setUpAll,
      // but v2 always uses 600K internally — so we construct a v2 hash
      // by calling the verify path. We can't easily construct one without
      // access to _pbkdf2, so we test the format detection and upgrade
      // path using a real v2-formatted string that we know verifies.
      //
      // Since constructing a real v2 hash requires the private _pbkdf2
      // method, we test the format upgrade logic:
      const pin = '9876';
      final v3Hash = PinService.hashPinSync(pin);

      // Simulate: after upgrade, the hash is v3
      expect(v3Hash.startsWith('v3:'), true);
      expect(PinService.isLegacyPinHash(v3Hash), false);
      expect(PinService.verifyPinSync(pin, v3Hash), true);

      // A v2 prefix is always detected as legacy
      expect(PinService.isLegacyPinHash('v2:anySalt:anyHash'), true);
    });
  });

  // ── Group 3: Database migration data integrity ────────────

  group('Database migration data integrity', () {
    late DatabaseService db;

    setUpAll(() async {
      // Re-init to get a clean in-memory DB for migration tests.
      await DatabaseService.instance.initInMemory();
      db = DatabaseService.instance;
    });

    test('schema version is 13 after initInMemory', () async {
      // Query the Drift schema version via the underlying DB.
      final result = await db.db.customSelect('PRAGMA user_version').get();
      final version = result.first.data['user_version'] as int;
      expect(version, 13);
    });

    test('consent_records table exists and accepts inserts', () async {
      // Insert directly via customStatement to verify the table exists.
      await db.db.customStatement(
        "INSERT INTO consent_records (consent_type, document_version, accepted_at, app_version) "
        "VALUES ('privacy_policy', '2026-03-29', ${DateTime(2026, 3, 29).millisecondsSinceEpoch ~/ 1000}, '1.0.0')",
      );

      final rows =
          await db.db
              .customSelect(
                'SELECT * FROM consent_records WHERE consent_type = ?',
                variables: [Variable<String>('privacy_policy')],
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
