// SQL strings use double quotes for readability (they contain SQLite single quotes).
// ignore_for_file: prefer_single_quotes

import 'package:drift/drift.dart';
import 'database_service.dart';

/// All database migration logic, extracted from AppDatabase for readability.
/// Each `if (from < N)` block handles upgrading from version N-1 to N.
MigrationStrategy buildMigrationStrategy(AppDatabase db) {
  return MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      // FTS5 schema is not declared in Drift tables — create it manually
      // so fresh installs get the same search index that v14 migrations add.
      await _createFts5Schema(db);
      // Fresh installs previously started without the performance indexes
      // that existing users accumulated through migrations v5–v13. That meant
      // every date-range query (Home recents, Recap week/month, Stats streak)
      // did a full table scan on day one. Mirror the upgrade-path indexes
      // here so a brand-new DB is as fast as an upgraded one.
      await _createPerformanceIndexes(db);
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // v1→v2: added title column (old schema had morningEntry etc.)
        await db.customStatement(
          'ALTER TABLE journal_entries ADD COLUMN title TEXT',
        );
      }
      if (from < 3) {
        await migrator.addColumn(
          db.userSettingsTable,
          db.userSettingsTable.enterToSave,
        );
        await migrator.addColumn(
          db.userSettingsTable,
          db.userSettingsTable.bulletPointsOnEnter,
        );
      }
      if (from < 4) {
        // v3→v4: Schema overhaul
        // 1. Create Users table
        await migrator.createTable(db.users);

        // 2. Add new columns to journal_entries
        await db.customStatement(
          'ALTER TABLE journal_entries ADD COLUMN entry TEXT',
        );
        await db.customStatement(
          'ALTER TABLE journal_entries ADD COLUMN label TEXT',
        );
        await db.customStatement(
          'ALTER TABLE journal_entries ADD COLUMN user_id INTEGER',
        );

        // 3. Migrate existing data — allDayEntry rows
        await db.customStatement('''
          UPDATE journal_entries
          SET entry = all_day_entry, label = NULL
          WHERE all_day_entry IS NOT NULL AND all_day_entry != ''
        ''');

        // morningEntry only (no evening, no allDay already migrated)
        await db.customStatement('''
          UPDATE journal_entries
          SET entry = morning_entry, label = 'AM'
          WHERE entry IS NULL
            AND morning_entry IS NOT NULL AND morning_entry != ''
            AND (evening_entry IS NULL OR evening_entry = '')
        ''');

        // eveningEntry only (no morning, no allDay already migrated)
        await db.customStatement('''
          UPDATE journal_entries
          SET entry = evening_entry, label = 'PM'
          WHERE entry IS NULL
            AND evening_entry IS NOT NULL AND evening_entry != ''
            AND (morning_entry IS NULL OR morning_entry = '')
        ''');

        // BOTH morning + evening: keep original as AM
        await db.customStatement('''
          UPDATE journal_entries
          SET entry = morning_entry, label = 'AM'
          WHERE entry IS NULL
            AND morning_entry IS NOT NULL AND morning_entry != ''
            AND evening_entry IS NOT NULL AND evening_entry != ''
        ''');

        // BOTH morning + evening: insert new row for PM
        await db.customStatement('''
          INSERT INTO journal_entries (date, entry, label, title, created_at, user_id)
          SELECT date, evening_entry, 'PM', title, created_at, user_id
          FROM journal_entries
          WHERE label = 'AM'
            AND evening_entry IS NOT NULL AND evening_entry != ''
        ''');

        // 4. Drop old columns via table recreation
        // SQLite on older Android may not support DROP COLUMN,
        // so we recreate the table.
        await db.customStatement('''
          CREATE TABLE journal_entries_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date INTEGER NOT NULL,
            entry TEXT,
            label TEXT,
            title TEXT,
            created_at INTEGER NOT NULL,
            user_id INTEGER
          )
        ''');
        await db.customStatement('''
          INSERT INTO journal_entries_new (id, date, entry, label, title, created_at, user_id)
          SELECT id, date, entry, label, title, created_at, user_id
          FROM journal_entries
        ''');
        await db.customStatement('DROP TABLE journal_entries');
        await db.customStatement(
          'ALTER TABLE journal_entries_new RENAME TO journal_entries',
        );

        // 5. Add userId to settings
        await db.customStatement(
          'ALTER TABLE user_settings_table ADD COLUMN user_id INTEGER',
        );
      }
      if (from < 5) {
        // v4→v5: Add date index, cleanup whitespace entries, add amPmCutoffHour
        await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_journal_date ON journal_entries(date)',
        );
        await db.customStatement(
          "DELETE FROM journal_entries WHERE entry IS NOT NULL AND TRIM(entry) = ''",
        );
        await db.customStatement(
          'ALTER TABLE user_settings_table ADD COLUMN am_pm_cutoff_hour INTEGER NOT NULL DEFAULT 14',
        );
      }
      if (from < 6) {
        // v5→v6: Add FK constraint from journal_entries.user_id → users.id.
        // SQLite cannot add constraints to existing columns, so recreate.
        await db.customStatement('PRAGMA foreign_keys = OFF');
        await db.customStatement('''
          CREATE TABLE journal_entries_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date INTEGER NOT NULL,
            entry TEXT,
            label TEXT,
            title TEXT,
            created_at INTEGER NOT NULL,
            user_id INTEGER REFERENCES users(id)
          )
        ''');
        await db.customStatement('''
          INSERT INTO journal_entries_new (id, date, entry, label, title, created_at, user_id)
          SELECT id, date, entry, label, title, created_at, user_id
          FROM journal_entries
        ''');
        await db.customStatement('DROP TABLE journal_entries');
        await db.customStatement(
          'ALTER TABLE journal_entries_new RENAME TO journal_entries',
        );
        await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_journal_date ON journal_entries(date)',
        );
        await db.customStatement('PRAGMA foreign_keys = ON');
      }
      if (from < 7) {
        // v6→v7: Replace is_dark_mode (bool) with theme_mode (int).
        // 0 = system, 1 = light, 2 = dark.
        // Existing users keep their explicit choice.
        await db.customStatement(
          'ALTER TABLE user_settings_table ADD COLUMN theme_mode INTEGER NOT NULL DEFAULT 0',
        );
        // Map old values: false(0) → light(1), true(1) → dark(2)
        await db.customStatement('''
          UPDATE user_settings_table SET theme_mode = CASE
            WHEN is_dark_mode = 1 THEN 2
            ELSE 1
          END
        ''');
        // Recreate table without is_dark_mode
        await db.customStatement('''
          CREATE TABLE user_settings_table_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            theme_mode INTEGER NOT NULL DEFAULT 0,
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
            am_pm_cutoff_hour INTEGER NOT NULL DEFAULT 14,
            user_id INTEGER
          )
        ''');
        await db.customStatement('''
          INSERT INTO user_settings_table_new (
            id, theme_mode, is_all_day_mode, ask_about_today,
            show_entry_title, week_start_day, nudge_hour,
            app_lock_enabled, pin_hash, biometric_enabled,
            onboarding_complete, enter_to_save, bullet_points_on_enter,
            am_pm_cutoff_hour, user_id
          )
          SELECT
            id, theme_mode, is_all_day_mode, ask_about_today,
            show_entry_title, week_start_day, nudge_hour,
            app_lock_enabled, pin_hash, biometric_enabled,
            onboarding_complete, enter_to_save, bullet_points_on_enter,
            am_pm_cutoff_hour, user_id
          FROM user_settings_table
        ''');
        await db.customStatement('DROP TABLE user_settings_table');
        await db.customStatement(
          'ALTER TABLE user_settings_table_new RENAME TO user_settings_table',
        );
      }
      if (from < 8) {
        // v7→v8: Add nudge_minute column and consent_records table.
        await db.customStatement(
          'ALTER TABLE user_settings_table ADD COLUMN nudge_minute INTEGER NOT NULL DEFAULT 0',
        );
        await db.customStatement('''
          CREATE TABLE consent_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            consent_type TEXT NOT NULL,
            document_version TEXT NOT NULL,
            accepted_at INTEGER NOT NULL,
            app_version TEXT
          )
        ''');
      }
      if (from < 9) {
        // v8→v9: Fix journal_entries FK to add ON DELETE CASCADE.
        // The v6 migration added REFERENCES users(id) but omitted CASCADE.
        // Also clean up orphaned entries referencing non-existent users.
        await db.customStatement('PRAGMA foreign_keys = OFF');

        // Delete orphaned entries that reference non-existent users.
        await db.customStatement('''
          DELETE FROM journal_entries
          WHERE user_id IS NOT NULL
            AND user_id NOT IN (SELECT id FROM users)
        ''');

        // Recreate table with ON DELETE CASCADE.
        await db.customStatement('''
          CREATE TABLE journal_entries_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date INTEGER NOT NULL,
            entry TEXT,
            label TEXT,
            title TEXT,
            created_at INTEGER NOT NULL,
            user_id INTEGER REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
        await db.customStatement('''
          INSERT INTO journal_entries_new (id, date, entry, label, title, created_at, user_id)
          SELECT id, date, entry, label, title, created_at, user_id
          FROM journal_entries
        ''');
        await db.customStatement('DROP TABLE journal_entries');
        await db.customStatement(
          'ALTER TABLE journal_entries_new RENAME TO journal_entries',
        );
        await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_journal_date ON journal_entries(date)',
        );
        await db.customStatement('PRAGMA foreign_keys = ON');
      }
      if (from < 10) {
        // v9→v10: Add mood column to journal_entries and mood settings.
        await db.customStatement(
          'ALTER TABLE journal_entries ADD COLUMN mood INTEGER',
        );
        await db.customStatement(
          'ALTER TABLE user_settings_table ADD COLUMN mood_enabled INTEGER NOT NULL DEFAULT 0',
        );
        await db.customStatement(
          'ALTER TABLE user_settings_table ADD COLUMN mood_required INTEGER NOT NULL DEFAULT 0',
        );
        await db.customStatement(
          'ALTER TABLE user_settings_table ADD COLUMN mood_only_entries INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 11) {
        // v10→v11: Add index on mood column for getMoodDistribution / getAverageMood.
        // The date index (idx_journal_date) already exists from v5/v6/v9.
        await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_journal_mood ON journal_entries(mood)',
        );
      }
      if (from < 12) {
        // v11→v12: Add bionic_reading_enabled column to user_settings_table.
        await db.customStatement(
          'ALTER TABLE user_settings_table ADD COLUMN bionic_reading_enabled INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 13) {
        // v12→v13: Add index on created_at for time-ordered queries,
        // and composite index on (date, mood) for filtered queries.
        await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_journal_created_at ON journal_entries(created_at)',
        );
        await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_journal_date_mood ON journal_entries(date, mood)',
        );
      }
      if (from < 14) {
        // v13→v14: Add FTS5 virtual table backing journal entry search.
        // External-content mode reads row data straight from journal_entries
        // (via content_rowid='id') so we don't duplicate user content on disk.
        await _createFts5Schema(db);
        // Backfill the index from existing rows. After this point, the AI/AD/AU
        // triggers keep journal_entries_fts in sync automatically.
        await db.customStatement('''
          INSERT INTO journal_entries_fts(rowid, entry, title)
          SELECT id, COALESCE(entry, ''), COALESCE(title, '')
          FROM journal_entries
        ''');
      }
    },
  );
}

/// Create the FTS5 virtual table + sync triggers for journal_entries.
/// Called from both onCreate (fresh installs) and the v13→v14 onUpgrade path.
Future<void> _createFts5Schema(AppDatabase db) async {
  // unicode61 with remove_diacritics=2 makes search match across accents
  // (e.g. "cafe" finds "café") and case-folds Unicode letters.
  await db.customStatement('''
    CREATE VIRTUAL TABLE journal_entries_fts USING fts5(
      entry,
      title,
      content='journal_entries',
      content_rowid='id',
      tokenize='unicode61 remove_diacritics 2'
    )
  ''');
  // Insert trigger: mirror new rows into the FTS index.
  await db.customStatement('''
    CREATE TRIGGER journal_entries_ai AFTER INSERT ON journal_entries BEGIN
      INSERT INTO journal_entries_fts(rowid, entry, title)
      VALUES (new.id, COALESCE(new.entry, ''), COALESCE(new.title, ''));
    END
  ''');
  // Delete trigger: external-content tables require the special 'delete'
  // command with the OLD values so FTS5 can locate the indexed row.
  await db.customStatement('''
    CREATE TRIGGER journal_entries_ad AFTER DELETE ON journal_entries BEGIN
      INSERT INTO journal_entries_fts(journal_entries_fts, rowid, entry, title)
      VALUES ('delete', old.id, COALESCE(old.entry, ''), COALESCE(old.title, ''));
    END
  ''');
  // Update trigger: delete the OLD index entry, then insert the NEW one.
  await db.customStatement('''
    CREATE TRIGGER journal_entries_au AFTER UPDATE ON journal_entries BEGIN
      INSERT INTO journal_entries_fts(journal_entries_fts, rowid, entry, title)
      VALUES ('delete', old.id, COALESCE(old.entry, ''), COALESCE(old.title, ''));
      INSERT INTO journal_entries_fts(rowid, entry, title)
      VALUES (new.id, COALESCE(new.entry, ''), COALESCE(new.title, ''));
    END
  ''');
}

/// All performance indexes on journal_entries. Called from onCreate for fresh
/// installs so new users don't scan full tables on day-one queries. Upgrade
/// paths (v5–v13) continue to create these one at a time; IF NOT EXISTS makes
/// re-running a no-op for anyone who already has them.
Future<void> _createPerformanceIndexes(AppDatabase db) async {
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_journal_date ON journal_entries(date)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_journal_mood ON journal_entries(mood)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_journal_created_at ON journal_entries(created_at)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_journal_date_mood ON journal_entries(date, mood)',
  );
}
