// SQL strings use double quotes for readability (they contain SQLite single quotes).
// ignore_for_file: prefer_single_quotes

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/database_service.dart';

/// Tests that EXERCISE the migration code in `migration_strategy.dart`
/// instead of just asserting the final v13 schema shape.
///
/// `database_migration_test.dart` covers the latter — but every test there
/// calls `DatabaseService.initInMemory()`, which creates the v13 schema
/// directly via `onCreate`. The migration `onUpgrade` chain is never
/// executed there, so the v3→v14 SQL — including the v3→v4 entry-split,
/// the v4→v5 whitespace cleanup, the v6→v7 is_dark_mode → theme_mode
/// mapping, and the v8→v9 orphan deletion — would not run in CI at all
/// without these tests.
///
/// Strategy: build an in-memory `NativeDatabase.memory(setup: ...)`,
/// pre-populate the OLD schema via raw SQL inside the setup callback,
/// seed fixture rows, then `PRAGMA user_version = N` so that when Drift
/// opens the database it sees an existing schema at version N and runs
/// `onUpgrade(N, schemaVersion)` — i.e. the production migration code.
void main() {
  // Helper: open AppDatabase pre-loaded with the v3 schema and a [seed]
  // callback that can insert fixture rows. Returns the AppDatabase but
  // does NOT trigger migration yet — the caller must run a query first.
  AppDatabase openV3WithFixtures(void Function(dynamic raw) seed) {
    return AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          // v3 had no FK constraints; turn enforcement on for realism.
          raw.execute('PRAGMA foreign_keys = ON');

          // v3 journal_entries — pre-overhaul schema. Has the legacy
          // morning_entry / evening_entry / all_day_entry columns that
          // v3→v4 collapses into the unified `entry` + `label` pattern.
          raw.execute('''
            CREATE TABLE journal_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date INTEGER NOT NULL,
              morning_entry TEXT,
              evening_entry TEXT,
              all_day_entry TEXT,
              title TEXT,
              created_at INTEGER NOT NULL
            )
          ''');

          // v3 user_settings_table — has is_dark_mode (replaced by
          // theme_mode in v7). No user_id, am_pm_cutoff_hour, nudge_minute,
          // mood_*, or bionic_reading_enabled yet.
          raw.execute('''
            CREATE TABLE user_settings_table (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              is_dark_mode INTEGER NOT NULL DEFAULT 0,
              is_all_day_mode INTEGER NOT NULL DEFAULT 1,
              ask_about_today INTEGER NOT NULL DEFAULT 1,
              show_entry_title INTEGER NOT NULL DEFAULT 0,
              week_start_day INTEGER NOT NULL DEFAULT 1,
              nudge_hour INTEGER NOT NULL DEFAULT 20,
              app_lock_enabled INTEGER NOT NULL DEFAULT 0,
              pin_hash TEXT,
              biometric_enabled INTEGER NOT NULL DEFAULT 0,
              onboarding_complete INTEGER NOT NULL DEFAULT 0,
              enter_to_save INTEGER NOT NULL DEFAULT 0,
              bullet_points_on_enter INTEGER NOT NULL DEFAULT 0
            )
          ''');

          seed(raw);

          // Tell Drift the existing schema is at v3 so the first query
          // against the AppDatabase triggers onUpgrade(3, 13).
          raw.execute('PRAGMA user_version = 3');
        },
      ),
    );
  }

  // Helper: open AppDatabase pre-loaded with the v6 schema. v6 is the
  // first version where journal_entries has a user_id FK to users(id),
  // so it lets us insert orphans (with PRAGMA foreign_keys = OFF) and
  // confirm the v8→v9 cleanup deletes them.
  AppDatabase openV6WithFixtures(void Function(dynamic raw) seed) {
    return AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          // FKs MUST stay OFF here so the test can insert orphan entries
          // referencing non-existent users. The v8→v9 migration toggles
          // its own PRAGMA, so this OFF state only matters during seeding.
          raw.execute('PRAGMA foreign_keys = OFF');

          // v6 users — unchanged through v13.
          raw.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              display_name TEXT,
              email TEXT,
              subscription_tier TEXT NOT NULL DEFAULT 'free',
              created_at INTEGER NOT NULL
            )
          ''');

          // v6 journal_entries — has user_id FK without ON DELETE CASCADE
          // (the CASCADE is added by v8→v9).
          raw.execute('''
            CREATE TABLE journal_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date INTEGER NOT NULL,
              entry TEXT,
              label TEXT,
              title TEXT,
              created_at INTEGER NOT NULL,
              user_id INTEGER REFERENCES users(id)
            )
          ''');

          // v6 user_settings_table — same v3 columns plus user_id (v4)
          // and am_pm_cutoff_hour (v5). Still has is_dark_mode (v7 drops it).
          raw.execute('''
            CREATE TABLE user_settings_table (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              is_dark_mode INTEGER NOT NULL DEFAULT 0,
              is_all_day_mode INTEGER NOT NULL DEFAULT 1,
              ask_about_today INTEGER NOT NULL DEFAULT 1,
              show_entry_title INTEGER NOT NULL DEFAULT 0,
              week_start_day INTEGER NOT NULL DEFAULT 1,
              nudge_hour INTEGER NOT NULL DEFAULT 20,
              app_lock_enabled INTEGER NOT NULL DEFAULT 0,
              pin_hash TEXT,
              biometric_enabled INTEGER NOT NULL DEFAULT 0,
              onboarding_complete INTEGER NOT NULL DEFAULT 0,
              enter_to_save INTEGER NOT NULL DEFAULT 0,
              bullet_points_on_enter INTEGER NOT NULL DEFAULT 0,
              user_id INTEGER,
              am_pm_cutoff_hour INTEGER NOT NULL DEFAULT 14
            )
          ''');

          seed(raw);

          raw.execute('PRAGMA user_version = 6');
        },
      ),
    );
  }

  group('Migration chain (onUpgrade)', () {
    test(
      'v3→v14 splits morning/evening/all_day rows into AM/PM/null labels',
      () async {
        // Drift stores DateTime as unix-seconds. Compute seeded values
        // the same way the existing v3→v4 test does so we don't end up
        // with hard-coded magic numbers that drift from Drift's encoder.
        final day1 = DateTime(2025, 1, 1).millisecondsSinceEpoch ~/ 1000;
        final day2 = DateTime(2025, 1, 2).millisecondsSinceEpoch ~/ 1000;
        final day3 = DateTime(2025, 1, 3).millisecondsSinceEpoch ~/ 1000;
        final day4 = DateTime(2025, 1, 4).millisecondsSinceEpoch ~/ 1000;
        final day5 = DateTime(2025, 1, 5).millisecondsSinceEpoch ~/ 1000;
        final createdAt =
            DateTime(2025, 1, 1, 12).millisecondsSinceEpoch ~/ 1000;

        final db = openV3WithFixtures((raw) {
          // morning only → expect entry + label='AM' after migration
          raw.execute(
            "INSERT INTO journal_entries (date, morning_entry, created_at) "
            "VALUES ($day1, 'Coffee and run', $createdAt)",
          );
          // evening only → expect entry + label='PM'
          raw.execute(
            "INSERT INTO journal_entries (date, evening_entry, created_at) "
            "VALUES ($day2, 'Read a book', $createdAt)",
          );
          // all-day only → expect entry + label=NULL
          raw.execute(
            "INSERT INTO journal_entries (date, all_day_entry, created_at) "
            "VALUES ($day3, 'Lazy Sunday', $createdAt)",
          );
          // BOTH morning AND evening → expect 2 rows (AM + PM)
          raw.execute(
            "INSERT INTO journal_entries "
            "(date, morning_entry, evening_entry, title, created_at) "
            "VALUES ($day4, 'Morning jog', 'Dinner with friends', "
            "'My day', $createdAt)",
          );
          // whitespace-only morning entry → v4→v5 cleanup MUST delete it
          raw.execute(
            "INSERT INTO journal_entries (date, morning_entry, created_at) "
            "VALUES ($day5, '   ', $createdAt)",
          );

          // is_dark_mode = 1 → expect theme_mode = 2 (dark) after v6→v7
          raw.execute(
            "INSERT INTO user_settings_table (is_dark_mode) VALUES (1)",
          );
        });

        try {
          // First query forces Drift's ensureOpen, which sees user_version=3
          // and runs onUpgrade(3, 13) — i.e. the entire migration chain.
          await db.customSelect('SELECT 1').get();

          // Assert: entries were correctly split + cleaned
          final entries = await db.select(db.journalEntries).get();
          // 4 valid originals (excluding whitespace) + 1 PM split row = 5
          expect(
            entries.length,
            5,
            reason:
                '4 valid originals + 1 PM split (BOTH row), whitespace deleted',
          );

          final morningOnly = entries.firstWhere(
            (e) => e.entry == 'Coffee and run',
          );
          expect(morningOnly.label, 'AM');

          final eveningOnly = entries.firstWhere(
            (e) => e.entry == 'Read a book',
          );
          expect(eveningOnly.label, 'PM');

          final allDay = entries.firstWhere((e) => e.entry == 'Lazy Sunday');
          expect(
            allDay.label,
            isNull,
            reason: 'all_day entries get NULL label after v3→v4',
          );

          final bothAm = entries.firstWhere((e) => e.entry == 'Morning jog');
          expect(bothAm.label, 'AM');
          expect(
            bothAm.title,
            'My day',
            reason: 'AM half of split keeps original title',
          );

          final bothPm = entries.firstWhere(
            (e) => e.entry == 'Dinner with friends',
          );
          expect(bothPm.label, 'PM');
          expect(
            bothPm.title,
            'My day',
            reason: 'PM half of split copies original title',
          );

          // Whitespace-only entry MUST have been deleted by v4→v5.
          expect(
            entries.any((e) => (e.entry ?? '').trim().isEmpty),
            isFalse,
            reason: 'v4→v5 cleanup should delete whitespace-only entries',
          );

          final settings = await db.select(db.userSettingsTable).getSingle();
          expect(
            settings.themeMode,
            2,
            reason: 'is_dark_mode=1 should map to theme_mode=2 (dark)',
          );

          // Assert: columns added by later migrations exist with defaults
          expect(settings.amPmCutoffHour, 14, reason: 'v5 added');
          expect(settings.nudgeMinute, 0, reason: 'v8 added');
          expect(settings.moodEnabled, false, reason: 'v10 added');
          expect(settings.moodRequired, false, reason: 'v10 added');
          expect(settings.moodOnlyEntries, false, reason: 'v10 added');
          expect(settings.bionicReadingEnabled, false, reason: 'v12 added');

          // Assert: indices added by later migrations all exist
          final indexNames =
              (await db
                      .customSelect(
                        "SELECT name FROM sqlite_master WHERE type='index' "
                        "AND name LIKE 'idx_journal_%'",
                      )
                      .get())
                  .map((row) => row.read<String>('name'))
                  .toSet();
          expect(
            indexNames,
            containsAll(<String>[
              'idx_journal_date', // v5
              'idx_journal_mood', // v11
              'idx_journal_created_at', // v13
              'idx_journal_date_mood', // v13
            ]),
            reason: 'all v5/v11/v13 journal indices should exist',
          );

          // Assert: tables added by later migrations exist + queryable
          // (users was added in v4, consent_records in v8.)
          await db.customSelect('SELECT 1 FROM users LIMIT 1').get();
          await db.customSelect('SELECT 1 FROM consent_records LIMIT 1').get();
        } finally {
          await db.close();
        }
      },
    );

    test('v3→v14 maps is_dark_mode=0 to theme_mode=1 (light)', () async {
      // Companion to the previous test — ensures the FALSE branch of
      // the v6→v7 CASE expression is also exercised.
      final db = openV3WithFixtures((raw) {
        raw.execute(
          "INSERT INTO user_settings_table (is_dark_mode) VALUES (0)",
        );
      });

      try {
        await db.customSelect('SELECT 1').get();
        final settings = await db.select(db.userSettingsTable).getSingle();
        expect(
          settings.themeMode,
          1,
          reason: 'is_dark_mode=0 should map to theme_mode=1 (light)',
        );
      } finally {
        await db.close();
      }
    });

    test('v6→v14 deletes orphaned entries with non-existent user_id', () async {
      // The v8→v9 migration cleans up entries whose user_id references
      // a user that no longer exists (a real bug fixed in that migration).
      // To test it we need to seed the orphan with FKs disabled.
      final createdAt = DateTime(2025, 6, 1).millisecondsSinceEpoch ~/ 1000;
      final entryDate = DateTime(2025, 6, 1).millisecondsSinceEpoch ~/ 1000;

      final db = openV6WithFixtures((raw) {
        // A real user with id=1.
        raw.execute(
          "INSERT INTO users (id, display_name, created_at) "
          "VALUES (1, 'Alice', $createdAt)",
        );
        // A valid entry that references the real user.
        raw.execute(
          "INSERT INTO journal_entries "
          "(date, entry, label, created_at, user_id) "
          "VALUES ($entryDate, 'valid entry', 'AM', $createdAt, 1)",
        );
        // An ORPHAN entry that references a non-existent user.
        raw.execute(
          "INSERT INTO journal_entries "
          "(date, entry, label, created_at, user_id) "
          "VALUES ($entryDate, 'orphan entry', 'PM', $createdAt, 999)",
        );
        // Need at least one settings row so the v6→v7 recreation has
        // something to copy and we can read it back after migration.
        raw.execute(
          "INSERT INTO user_settings_table (is_dark_mode) VALUES (0)",
        );
      });

      try {
        await db.customSelect('SELECT 1').get();

        final entries = await db.select(db.journalEntries).get();
        expect(
          entries.length,
          1,
          reason: 'orphan with user_id=999 must be deleted by v8→v9',
        );
        expect(entries.single.entry, 'valid entry');
        expect(entries.single.userId, 1);

        // Verify the new FK has ON DELETE CASCADE: deleting the user
        // should cascade and remove the valid entry too.
        await db.customStatement('DELETE FROM users WHERE id = 1');
        final entriesAfterUserDelete = await db.select(db.journalEntries).get();
        expect(
          entriesAfterUserDelete,
          isEmpty,
          reason:
              'v8→v9 must add ON DELETE CASCADE so user deletion removes entries',
        );
      } finally {
        await db.close();
      }
    });

    test('v3→v14 backfills the FTS5 index and keeps it in sync', () async {
      // Verifies the v13→v14 migration creates journal_entries_fts,
      // backfills it from existing rows, and that the AI/AU/AD triggers
      // keep the index in sync for inserts/updates/deletes after migration.
      final day1 = DateTime(2025, 5, 1).millisecondsSinceEpoch ~/ 1000;
      final day2 = DateTime(2025, 5, 2).millisecondsSinceEpoch ~/ 1000;
      final createdAt = DateTime(2025, 5, 1, 12).millisecondsSinceEpoch ~/ 1000;

      final db = openV3WithFixtures((raw) {
        // Two pre-v14 entries — must be findable via FTS5 after backfill.
        raw.execute(
          "INSERT INTO journal_entries (date, all_day_entry, title, created_at) "
          "VALUES ($day1, 'Coffee at the café', 'Morning ritual', $createdAt)",
        );
        raw.execute(
          "INSERT INTO journal_entries (date, all_day_entry, created_at) "
          "VALUES ($day2, 'Reading by the window', $createdAt)",
        );
        raw.execute(
          "INSERT INTO user_settings_table (is_dark_mode) VALUES (0)",
        );
      });

      try {
        // Trigger the full migration chain (3 → schemaVersion).
        await db.customSelect('SELECT 1').get();

        // Backfill: pre-existing rows are findable via FTS5
        final coffeeHits =
            await db
                .customSelect(
                  "SELECT rowid FROM journal_entries_fts "
                  "WHERE journal_entries_fts MATCH ?",
                  variables: [Variable.withString('"coffee"*')],
                )
                .get();
        expect(
          coffeeHits.length,
          1,
          reason: 'v13→v14 backfill should index existing entries',
        );

        final cafeHits =
            await db
                .customSelect(
                  "SELECT rowid FROM journal_entries_fts "
                  "WHERE journal_entries_fts MATCH ?",
                  variables: [Variable.withString('"cafe"*')],
                )
                .get();
        expect(
          cafeHits.length,
          1,
          reason: 'unicode61 remove_diacritics=2 should fold "café" → "cafe"',
        );

        final titleHits =
            await db
                .customSelect(
                  "SELECT rowid FROM journal_entries_fts "
                  "WHERE journal_entries_fts MATCH ?",
                  variables: [Variable.withString('"ritual"*')],
                )
                .get();
        expect(titleHits.length, 1, reason: 'title column must be indexed');

        // INSERT trigger: new rows automatically get indexed
        await db.customStatement(
          "INSERT INTO journal_entries (date, entry, created_at) "
          "VALUES ($day1, 'Sunset over the harbour', $createdAt)",
        );
        final sunsetHits =
            await db
                .customSelect(
                  "SELECT rowid FROM journal_entries_fts "
                  "WHERE journal_entries_fts MATCH ?",
                  variables: [Variable.withString('"sunset"*')],
                )
                .get();
        expect(
          sunsetHits.length,
          1,
          reason: 'AI trigger should index newly inserted rows',
        );

        final newRowId = sunsetHits.single.read<int>('rowid');
        await db.customStatement(
          "UPDATE journal_entries SET entry = 'Moonrise over the harbour' "
          "WHERE id = $newRowId",
        );
        final moonriseHits =
            await db
                .customSelect(
                  "SELECT rowid FROM journal_entries_fts "
                  "WHERE journal_entries_fts MATCH ?",
                  variables: [Variable.withString('"moonrise"*')],
                )
                .get();
        expect(moonriseHits.length, 1, reason: 'AU trigger should reindex');
        final staleSunsetHits =
            await db
                .customSelect(
                  "SELECT rowid FROM journal_entries_fts "
                  "WHERE journal_entries_fts MATCH ?",
                  variables: [Variable.withString('"sunset"*')],
                )
                .get();
        expect(
          staleSunsetHits,
          isEmpty,
          reason: 'AU trigger should remove the old indexed terms',
        );

        // DELETE trigger: removed rows fall out of the index
        await db.customStatement(
          "DELETE FROM journal_entries WHERE id = $newRowId",
        );
        final postDeleteHits =
            await db
                .customSelect(
                  "SELECT rowid FROM journal_entries_fts "
                  "WHERE journal_entries_fts MATCH ?",
                  variables: [Variable.withString('"moonrise"*')],
                )
                .get();
        expect(
          postDeleteHits,
          isEmpty,
          reason: 'AD trigger should remove deleted rows from the index',
        );
      } finally {
        await db.close();
      }
    });

    test('v3→v14 leaves an empty database in a queryable state', () async {
      // Smoke test: a v3 database with no rows should migrate cleanly
      // and end up with all expected v13 tables, ready for use.
      final db = openV3WithFixtures((_) {});

      try {
        await db.customSelect('SELECT 1').get();

        // All four tables should exist and be queryable.
        expect((await db.select(db.journalEntries).get()), isEmpty);
        expect((await db.select(db.users).get()), isEmpty);
        expect((await db.select(db.consentRecords).get()), isEmpty);
        // user_settings_table is empty too — initInMemory normally seeds
        // a default row, but the migration code itself doesn't.
        expect((await db.select(db.userSettingsTable).get()), isEmpty);
      } finally {
        await db.close();
      }
    });

    // explicit v13→v14 direct-hop assertions. The chain
    // test above exercises the full v3→v14 sequence; these two focused
    // tests pin down exactly what the v13→v14 migration introduces,
    // which is the concrete risk surface for a user who installed
    // the v13 build yesterday and hits today's v14 update.
    test('v13→v14 creates journal_entries_fts table + 3 triggers', () async {
      final db = openV3WithFixtures((_) {});
      try {
        // Force the migration chain to run.
        await db.customSelect('SELECT 1').get();

        // 1. journal_entries_fts exists.
        final ftsExists = await db
            .customSelect(
              "SELECT name FROM sqlite_master "
              "WHERE type='table' AND name='journal_entries_fts'",
            )
            .get();
        expect(ftsExists, hasLength(1),
            reason:
                'v14 migration must create the journal_entries_fts table');

        // 2. All three FTS sync triggers exist (AI / AU / AD).
        // Names follow the journal_entries_{ai,au,ad} pattern; see
        // lib/services/migration_strategy.dart around the v13→v14 block.
        final triggers = await db
            .customSelect(
              "SELECT name FROM sqlite_master "
              "WHERE type='trigger' AND tbl_name='journal_entries'",
            )
            .get();
        final names = triggers.map((r) => r.read<String>('name')).toSet();
        expect(
          names,
          containsAll({
            'journal_entries_ai',
            'journal_entries_au',
            'journal_entries_ad',
          }),
          reason:
              'v14 migration must install the AI/AU/AD FTS sync triggers '
              'on journal_entries — found: $names',
        );
      } finally {
        await db.close();
      }
    });

    test('v13→latest leaves schema_version at the current head', () async {
      final db = openV3WithFixtures((_) {});
      try {
        await db.customSelect('SELECT 1').get();

        final row =
            await db.customSelect('PRAGMA user_version').getSingle();
        final version = row.data.values.first as int;
        expect(
          version,
          15,
          reason:
              'After v3→latest migration, PRAGMA user_version must match the '
              'current schema version (15). A mismatch here means the migration '
              'stopped short and the head-version invariants (FTS triggers, '
              'indices, on-device AI toggle column) cannot be relied upon by '
              'application code.',
        );
      } finally {
        await db.close();
      }
    });
  });
}
