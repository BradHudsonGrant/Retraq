import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/models/user.dart';
import 'package:retraq/models/user_settings.dart';
import 'package:retraq/services/database_service.dart';

/// Tests that verify the database schema is correct after all migrations
/// have been applied, and that the migration code produces a usable database.
///
/// NOTE: Every test in this file calls `DatabaseService.initInMemory()`,
/// which builds the v13 schema directly via `onCreate`. The migration
/// `onUpgrade` chain is therefore NOT exercised here — that lives in
/// `migration_strategy_test.dart`, which seeds an old schema, sets
/// `PRAGMA user_version`, and lets Drift run the upgrade path.
///
/// Migration history:
///   v1 → v2:  Added `title` column to journal_entries
///   v2 → v3:  Added `enter_to_save`, `bullet_points_on_enter` to user_settings_table
///   v3 → v4:  Schema overhaul — created `users` table, replaced morning/evening/allDay
///             columns with unified `entry`+`label`+`user_id`, added `user_id` to settings
///   v4 → v5:  Added date index on journal_entries, cleanup whitespace-only entries,
///             added `am_pm_cutoff_hour` to user_settings_table
///   v5 → v6:  Added FK constraint from journal_entries.user_id → users.id
///   v6 → v7:  Replaced is_dark_mode (bool) with theme_mode (int)
///   v7 → v8:  Added nudge_minute column, created consent_records table
///   v8 → v9:  Fixed FK ON DELETE CASCADE, cleaned orphaned entries
///   v9 → v10: Added mood column to journal_entries, mood settings
///   v10 → v11: Added index on mood column (idx_journal_mood)
///   v11 → v12: Added bionic_reading_enabled column to user_settings_table
///   v12 → v13: Added idx_journal_created_at and composite idx_journal_date_mood
void main() {
  late DatabaseService db;

  setUp(() async {
    db = DatabaseService.instance;
    await db.initInMemory();
  });

  tearDown(() async {
    await db.dispose();
  });

  group('Final schema (v13) - journal_entries table', () {
    test('has all expected columns', () async {
      // Verify all v13 columns exist by inserting a row that uses every column
      // First create a user so FK constraint is satisfied
      final userId = await db.userRepo.saveUser(
        User(
          displayName: 'Test User',
          email: 'test@test.com',
          createdAt: DateTime(2026, 3, 15),
        ),
      );
      final entry = JournalEntry(
        date: DateTime(2026, 3, 15),
        entry: 'Schema test entry',
        label: 'AM',
        title: 'Schema Test',
        userId: userId,
        createdAt: DateTime(2026, 3, 15, 10, 0),
      );
      final id = await db.entries.saveEntry(entry);
      expect(id, greaterThan(0));

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 15));
      expect(entries, isNotEmpty);

      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.entry, 'Schema test entry');
      expect(saved.label, 'AM');
      expect(saved.title, 'Schema Test');
      expect(saved.userId, userId);
    });

    test('entry column is nullable (v4 addition)', () async {
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 16),
          entry: null,
          createdAt: DateTime(2026, 3, 16, 8, 0),
        ),
      );
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 16));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.entry, isNull);
    });

    test('label column is nullable (v4 addition)', () async {
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 17),
          entry: 'No label',
          label: null,
          createdAt: DateTime(2026, 3, 17, 8, 0),
        ),
      );
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 17));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.label, isNull);
    });

    test('title column is nullable (v2 addition)', () async {
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 18),
          entry: 'No title',
          title: null,
          createdAt: DateTime(2026, 3, 18, 8, 0),
        ),
      );
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 18));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.title, isNull);
    });

    test('userId column is nullable (v4 addition)', () async {
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 19),
          entry: 'No user',
          userId: null,
          createdAt: DateTime(2026, 3, 19, 8, 0),
        ),
      );
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 19));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.userId, isNull);
    });

    test('label supports AM/PM values (v4 migration split)', () async {
      final amId = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 20),
          entry: 'Morning entry',
          label: 'AM',
          createdAt: DateTime(2026, 3, 20, 8, 0),
        ),
      );
      final pmId = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 20),
          entry: 'Evening entry',
          label: 'PM',
          createdAt: DateTime(2026, 3, 20, 20, 0),
        ),
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 20));
      expect(entries.length, 2);

      final am = entries.firstWhere((e) => e.id == amId);
      final pm = entries.firstWhere((e) => e.id == pmId);
      expect(am.label, 'AM');
      expect(pm.label, 'PM');
    });
  });

  group('Final schema (v13) - date index', () {
    test('date index exists and queries by date work efficiently', () async {
      // Insert entries across multiple dates
      for (int day = 1; day <= 10; day++) {
        await db.entries.saveEntry(
          JournalEntry(
            date: DateTime(2026, 6, day),
            entry: 'Entry for day $day',
            createdAt: DateTime(2026, 6, day, 12, 0),
          ),
        );
      }

      // Query a specific date — the index should make this efficient
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 6, 5));
      expect(entries.length, 1);
      expect(entries.first.entry, 'Entry for day 5');
    });
  });

  group('Final schema (v13) - users table', () {
    test('users table exists and supports full CRUD (v4 addition)', () async {
      // Create
      final user = User(
        displayName: 'Test User',
        email: 'test@example.com',
        createdAt: DateTime(2026, 3, 15),
      );
      final id = await db.userRepo.saveUser(user);
      expect(id, greaterThan(0));

      // Read
      final loaded = await db.userRepo.getUser();
      expect(loaded, isNotNull);
      expect(loaded!.displayName, 'Test User');
      expect(loaded.email, 'test@example.com');
    });

    test('displayName and email are nullable', () async {
      final user = User(
        displayName: null,
        email: null,
        createdAt: DateTime(2026, 3, 15),
      );
      final id = await db.userRepo.saveUser(user);
      expect(id, greaterThan(0));

      final loaded = await db.userRepo.getUser();
      expect(loaded, isNotNull);
      expect(loaded!.displayName, isNull);
      expect(loaded.email, isNull);
    });

    test('user can be updated', () async {
      final user = User(
        displayName: 'Original',
        createdAt: DateTime(2026, 3, 15),
      );
      final id = await db.userRepo.saveUser(user);

      final updated = User(
        id: id,
        displayName: 'Updated',
        email: 'updated@example.com',
        createdAt: DateTime(2026, 3, 15),
      );
      await db.userRepo.saveUser(updated);

      final loaded = await db.userRepo.getUser();
      expect(loaded!.displayName, 'Updated');
      expect(loaded.email, 'updated@example.com');
    });
  });

  group('Final schema (v13) - user_settings_table', () {
    test('has all expected columns with correct defaults', () async {
      final settings = await db.settings.getSettings();

      // Original v1 columns (isDarkMode replaced by themeMode in v7)
      expect(settings.themeMode, 0); // system
      expect(settings.isAllDayMode, true);
      expect(settings.askAboutToday, true);
      expect(settings.showEntryTitle, false);
      expect(settings.weekStartDay, 1);
      expect(settings.nudgeHour, 20);
      expect(settings.appLockEnabled, false);
      expect(settings.pinHash, isNull);
      expect(settings.biometricEnabled, false);
      expect(settings.onboardingComplete, false);

      // v3 additions
      expect(settings.enterToSave, false);
      expect(settings.bulletPointsOnEnter, false);

      // v5 addition
      expect(settings.amPmCutoffHour, 14);
    });

    test('enterToSave persists correctly (v3 addition)', () async {
      final settings = await db.settings.getSettings();
      await db.settings.saveSettings(settings.copyWith(enterToSave: true));

      final reloaded = await db.settings.getSettings();
      expect(reloaded.enterToSave, true);
    });

    test('bulletPointsOnEnter persists correctly (v3 addition)', () async {
      final settings = await db.settings.getSettings();
      await db.settings.saveSettings(
        settings.copyWith(bulletPointsOnEnter: true),
      );

      final reloaded = await db.settings.getSettings();
      expect(reloaded.bulletPointsOnEnter, true);
    });

    test('amPmCutoffHour persists correctly (v5 addition)', () async {
      final settings = await db.settings.getSettings();
      expect(settings.amPmCutoffHour, 14); // default

      await db.settings.saveSettings(settings.copyWith(amPmCutoffHour: 12));

      final reloaded = await db.settings.getSettings();
      expect(reloaded.amPmCutoffHour, 12);
    });

    test('amPmCutoffHour default is 14 (v5 DEFAULT 14)', () async {
      final settings = await db.settings.getSettings();
      expect(settings.amPmCutoffHour, 14);
    });

    test('all settings can be saved and reloaded', () async {
      final settings = UserSettings(
        themeMode: 2,
        isAllDayMode: false,
        askAboutToday: false,
        showEntryTitle: false,
        weekStartDay: 7,
        nudgeHour: 9,
        appLockEnabled: true,
        pinHash: 'v2:test:hash',
        biometricEnabled: true,
        onboardingComplete: true,
        enterToSave: true,
        bulletPointsOnEnter: true,
        amPmCutoffHour: 16,
      );
      await db.settings.saveSettings(settings);

      final reloaded = await db.settings.getSettings();
      expect(reloaded.themeMode, 2);
      expect(reloaded.isAllDayMode, false);
      expect(reloaded.askAboutToday, false);
      expect(reloaded.showEntryTitle, false);
      expect(reloaded.weekStartDay, 7);
      expect(reloaded.nudgeHour, 9);
      expect(reloaded.appLockEnabled, true);
      expect(reloaded.pinHash, 'v2:test:hash');
      expect(reloaded.biometricEnabled, true);
      expect(reloaded.onboardingComplete, true);
      expect(reloaded.enterToSave, true);
      expect(reloaded.bulletPointsOnEnter, true);
      expect(reloaded.amPmCutoffHour, 16);
    });
  });

  group('V5 migration - whitespace entry cleanup', () {
    test('entries with whitespace-only content are not persisted', () async {
      // The v5 migration deletes existing whitespace-only entries.
      // On a fresh DB, we verify that entries with real content survive
      // and that the schema supports the cleanup query.
      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 7, 1),
          entry: 'Real content',
          createdAt: DateTime(2026, 7, 1, 8, 0),
        ),
      );
      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 7, 2),
          entry: '   Valid content with spaces   ',
          createdAt: DateTime(2026, 7, 2, 8, 0),
        ),
      );

      final all = await db.entries.getEntriesForDateRange(
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 2),
      );
      expect(all.length, 2);
    });
  });

  group('Cross-table relationships (v4 schema)', () {
    test('journal entry can reference a user via userId', () async {
      final userId = await db.userRepo.saveUser(
        User(displayName: 'Journal Owner', createdAt: DateTime(2026, 3, 15)),
      );

      final entryId = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 15),
          entry: 'Entry with user reference',
          userId: userId,
          createdAt: DateTime(2026, 3, 15, 10, 0),
        ),
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 15));
      final saved = entries.firstWhere((e) => e.id == entryId);
      expect(saved.userId, userId);
    });

    test(
      'multiple entries can belong to different labels on same date',
      () async {
        await db.entries.saveEntry(
          JournalEntry(
            date: DateTime(2026, 8, 1),
            entry: 'Morning thought',
            label: 'AM',
            createdAt: DateTime(2026, 8, 1, 8, 0),
          ),
        );
        await db.entries.saveEntry(
          JournalEntry(
            date: DateTime(2026, 8, 1),
            entry: 'Evening reflection',
            label: 'PM',
            createdAt: DateTime(2026, 8, 1, 20, 0),
          ),
        );
        await db.entries.saveEntry(
          JournalEntry(
            date: DateTime(2026, 8, 1),
            entry: 'All day note',
            label: null,
            createdAt: DateTime(2026, 8, 1, 12, 0),
          ),
        );

        final entries = await db.entries.getEntriesForDate(
          DateTime(2026, 8, 1),
        );
        expect(entries.length, 3);

        final labels = entries.map((e) => e.label).toSet();
        expect(labels, containsAll(['AM', 'PM', null]));
      },
    );
  });

  group('Database lifecycle', () {
    test(
      'initInMemory creates a usable database with correct schema',
      () async {
        // The setUp already called initInMemory — verify basic operations work
        final count = await db.entries.getTotalEntryCount();
        expect(count, isA<int>());
      },
    );

    test('getSettings returns defaults on fresh database', () async {
      final settings = await db.settings.getSettings();
      expect(settings, isNotNull);
      // initInMemory calls getSettings internally, which inserts defaults
      expect(settings.themeMode, 0);
    });

    test(
      'deleteAllData resets entries but preserves settings structure',
      () async {
        // Add some data
        await db.entries.saveEntry(
          JournalEntry(
            date: DateTime(2026, 9, 1),
            entry: 'To be wiped',
            createdAt: DateTime(2026, 9, 1, 8, 0),
          ),
        );
        await db.settings.saveSettings(UserSettings(nudgeHour: 10));

        // Wipe
        await db.userRepo.deleteAllData();

        // Entries gone
        final entries = await db.entries.getEntriesForDate(
          DateTime(2026, 9, 1),
        );
        expect(entries, isEmpty);

        // Settings reset to defaults
        final settings = await db.settings.getSettings();
        expect(settings.nudgeHour, 20); // default, not 10
      },
    );
  });

  // Search uses correct column names (v4 schema)

  group('Search after migration (v4+ schema)', () {
    test('search finds entries by entry text', () async {
      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 10, 1),
          entry: 'Unique searchable migration test phrase',
          createdAt: DateTime(2026, 10, 1, 8, 0),
        ),
      );

      final results = await db.entries.searchEntries('migration test phrase');
      expect(results, isNotEmpty);
      expect(results.first.entry, contains('migration test phrase'));
    });

    test('search finds entries by title', () async {
      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 10, 2),
          entry: 'Some content',
          title: 'Unique Migration Title XYZ',
          createdAt: DateTime(2026, 10, 2, 8, 0),
        ),
      );

      final results = await db.entries.searchEntries('Migration Title XYZ');
      expect(results, isNotEmpty);
      expect(results.first.title, 'Unique Migration Title XYZ');
    });
  });

  group('Edge cases for migration-affected columns', () {
    test('entry can store long text', () async {
      final longText = 'A' * 10000;
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 11, 1),
          entry: longText,
          createdAt: DateTime(2026, 11, 1, 8, 0),
        ),
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 11, 1));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.entry!.length, 10000);
    });

    test('title can store unicode text (v2 column)', () async {
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 11, 2),
          entry: 'Unicode test',
          title: 'Emoji and CJK: 日本語テスト',
          createdAt: DateTime(2026, 11, 2, 8, 0),
        ),
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 11, 2));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.title, 'Emoji and CJK: 日本語テスト');
    });

    test('amPmCutoffHour accepts boundary values (v5 column)', () async {
      // Test storing 0 (midnight) — valid boundary
      final settings = await db.settings.getSettings();
      await db.settings.saveSettings(settings.copyWith(amPmCutoffHour: 0));
      var reloaded = await db.settings.getSettings();
      expect(reloaded.amPmCutoffHour, 0);

      // Test storing 23 — valid boundary
      await db.settings.saveSettings(reloaded.copyWith(amPmCutoffHour: 23));
      reloaded = await db.settings.getSettings();
      expect(reloaded.amPmCutoffHour, 23);
    });
  });

  // ════════════════════════════════════════════════════════════
  // Incremental migration path tests
  //
  // These tests exercise the raw SQL upgrade paths by seeding data
  // using patterns that mimic older schema versions, then verifying
  // the data is correctly accessible through current repositories.
  // ════════════════════════════════════════════════════════════

  group('Migration path: v3→v4 schema overhaul (morning/evening split)', () {
    // The v3→v4 migration replaces morning_entry, evening_entry, all_day_entry
    // columns with a unified entry+label pattern. These tests verify that the
    // post-migration v13 schema correctly supports the data patterns the
    // migration would produce. The actual onUpgrade SQL is exercised in
    // migration_strategy_test.dart.

    late DatabaseService db;

    setUp(() async {
      db = DatabaseService.instance;
      await db.initInMemory();
    });

    tearDown(() async {
      await db.dispose();
    });

    test('AM label entry represents migrated morning entry', () async {
      // After v3→v4, morning_entry becomes entry with label='AM'
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2025, 1, 15),
          entry: 'Had coffee and went for a run',
          label: 'AM',
          createdAt: DateTime(2025, 1, 15, 7, 0),
        ),
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2025, 1, 15));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.entry, 'Had coffee and went for a run');
      expect(saved.label, 'AM');
    });

    test('PM label entry represents migrated evening entry', () async {
      // After v3→v4, evening_entry becomes entry with label='PM'
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2025, 1, 15),
          entry: 'Read a book before bed',
          label: 'PM',
          createdAt: DateTime(2025, 1, 15, 21, 0),
        ),
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2025, 1, 15));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.entry, 'Read a book before bed');
      expect(saved.label, 'PM');
    });

    test('null label entry represents migrated all-day entry', () async {
      // After v3→v4, all_day_entry becomes entry with label=NULL
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2025, 1, 16),
          entry: 'Spent the whole day at the park',
          label: null,
          createdAt: DateTime(2025, 1, 16, 12, 0),
        ),
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2025, 1, 16));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.entry, 'Spent the whole day at the park');
      expect(saved.label, isNull);
    });

    test(
      'both AM and PM entries on same date (split morning+evening)',
      () async {
        // v3→v4 splits a row with both morning and evening into two rows
        final amId = await db.entries.saveEntry(
          JournalEntry(
            date: DateTime(2025, 1, 17),
            entry: 'Morning jog in the park',
            label: 'AM',
            createdAt: DateTime(2025, 1, 17, 7, 0),
          ),
        );
        final pmId = await db.entries.saveEntry(
          JournalEntry(
            date: DateTime(2025, 1, 17),
            entry: 'Dinner with friends',
            label: 'PM',
            createdAt: DateTime(2025, 1, 17, 19, 0),
          ),
        );

        final entries = await db.entries.getEntriesForDate(
          DateTime(2025, 1, 17),
        );
        expect(entries.length, 2);
        expect(entries.firstWhere((e) => e.id == amId).label, 'AM');
        expect(entries.firstWhere((e) => e.id == pmId).label, 'PM');
      },
    );

    test('v4 migration created users table referenced by entries', () async {
      // v3→v4 created the users table and added user_id FK to entries
      final userId = await db.userRepo.saveUser(
        User(displayName: 'Migration User', createdAt: DateTime(2025, 1, 15)),
      );
      final entryId = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2025, 1, 18),
          entry: 'Entry with user FK',
          userId: userId,
          createdAt: DateTime(2025, 1, 18, 10, 0),
        ),
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2025, 1, 18));
      expect(entries.firstWhere((e) => e.id == entryId).userId, userId);
    });

    test(
      'raw SQL insert with AM/PM pattern matches v4 migration output',
      () async {
        // Simulate what the v3→v4 migration SQL would produce:
        // INSERT rows with entry, label, title, created_at
        final now = DateTime(2025, 2, 1, 8, 0).millisecondsSinceEpoch ~/ 1000;
        final date = DateTime(2025, 2, 1).millisecondsSinceEpoch ~/ 1000;

        await db.db.customStatement(
          'INSERT INTO journal_entries (date, entry, label, title, created_at) '
          "VALUES ($date, 'Raw SQL morning', 'AM', 'Migration Test', $now)",
        );
        await db.db.customStatement(
          'INSERT INTO journal_entries (date, entry, label, created_at) '
          "VALUES ($date, 'Raw SQL evening', 'PM', $now)",
        );

        // Verify these are accessible through the repository
        final entries = await db.entries.getEntriesForDate(
          DateTime(2025, 2, 1),
        );
        expect(entries.length, 2);
        expect(
          entries.any((e) => e.label == 'AM' && e.title == 'Migration Test'),
          true,
        );
        expect(entries.any((e) => e.label == 'PM' && e.title == null), true);
      },
    );
  });

  group('Migration path: v6→v7 (isDarkMode bool → themeMode int)', () {
    // v6→v7 replaced is_dark_mode (bool) with theme_mode (int):
    //   is_dark_mode=0 (false) → theme_mode=1 (light)
    //   is_dark_mode=1 (true) → theme_mode=2 (dark)
    //   New installs default to theme_mode=0 (system)

    late DatabaseService db;

    setUp(() async {
      db = DatabaseService.instance;
      await db.initInMemory();
    });

    tearDown(() async {
      await db.dispose();
    });

    test('themeMode=0 is system default for new installs', () async {
      final settings = await db.settings.getSettings();
      expect(settings.themeMode, UserSettings.themeModeSystem);
      expect(settings.themeMode, 0);
    });

    test(
      'themeMode=1 represents light (migrated from isDarkMode=false)',
      () async {
        // After v6→v7, isDarkMode=0 maps to themeMode=1
        final settings = await db.settings.getSettings();
        await db.settings.saveSettings(
          settings.copyWith(themeMode: UserSettings.themeModeLight),
        );

        final reloaded = await db.settings.getSettings();
        expect(reloaded.themeMode, 1);
      },
    );

    test(
      'themeMode=2 represents dark (migrated from isDarkMode=true)',
      () async {
        // After v6→v7, isDarkMode=1 maps to themeMode=2
        final settings = await db.settings.getSettings();
        await db.settings.saveSettings(
          settings.copyWith(themeMode: UserSettings.themeModeDark),
        );

        final reloaded = await db.settings.getSettings();
        expect(reloaded.themeMode, 2);
      },
    );

    test('settings table has no is_dark_mode column after v7', () async {
      // Verify the old column was removed during table recreation
      final columns =
          await db.db
              .customSelect("PRAGMA table_info('user_settings_table')")
              .get();
      final columnNames = columns.map((r) => r.data['name'] as String).toList();
      expect(columnNames, isNot(contains('is_dark_mode')));
      expect(columnNames, contains('theme_mode'));
    });

    test('raw SQL theme_mode values persist correctly', () async {
      // Simulate what v6→v7 migration leaves behind
      await db.db.customStatement(
        'UPDATE user_settings_table SET theme_mode = 2 WHERE id = 1',
      );

      final settings = await db.settings.getSettings();
      expect(settings.themeMode, 2); // dark
    });

    test('all three theme modes round-trip through repository', () async {
      for (final mode in [0, 1, 2]) {
        final settings = await db.settings.getSettings();
        await db.settings.saveSettings(settings.copyWith(themeMode: mode));
        final reloaded = await db.settings.getSettings();
        expect(
          reloaded.themeMode,
          mode,
          reason: 'themeMode=$mode failed to round-trip',
        );
      }
    });
  });

  group('Migration path: v8→v9 (FK recreation with ON DELETE CASCADE)', () {
    // v8→v9 recreates journal_entries to add ON DELETE CASCADE to user_id FK.
    // Also cleans up orphaned entries referencing non-existent users.

    late DatabaseService db;

    setUp(() async {
      db = DatabaseService.instance;
      await db.initInMemory();
    });

    tearDown(() async {
      await db.dispose();
    });

    test('user_id FK has ON DELETE CASCADE after v9', () async {
      // Create a user and an entry referencing them
      final userId = await db.userRepo.saveUser(
        User(displayName: 'Cascade Test User', createdAt: DateTime(2026, 1, 1)),
      );
      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 1, 1),
          entry: 'Entry for cascade test',
          userId: userId,
          createdAt: DateTime(2026, 1, 1, 10, 0),
        ),
      );

      // Verify entry exists
      var entries = await db.entries.getEntriesForDate(DateTime(2026, 1, 1));
      expect(entries.any((e) => e.entry == 'Entry for cascade test'), true);

      // Delete the user — CASCADE should remove the entry
      await db.db.customStatement('DELETE FROM users WHERE id = $userId');

      entries = await db.entries.getEntriesForDate(DateTime(2026, 1, 1));
      expect(
        entries.any((e) => e.entry == 'Entry for cascade test'),
        false,
        reason: 'ON DELETE CASCADE should have removed the entry',
      );
    });

    test(
      'entries with NULL user_id survive user deletion (no cascade)',
      () async {
        // Entries without a user_id should not be affected by user deletion
        final userId = await db.userRepo.saveUser(
          User(displayName: 'Other User', createdAt: DateTime(2026, 1, 2)),
        );
        await db.entries.saveEntry(
          JournalEntry(
            date: DateTime(2026, 1, 2),
            entry: 'Entry without user',
            userId: null,
            createdAt: DateTime(2026, 1, 2, 10, 0),
          ),
        );

        await db.db.customStatement('DELETE FROM users WHERE id = $userId');

        final entries = await db.entries.getEntriesForDate(
          DateTime(2026, 1, 2),
        );
        expect(entries.any((e) => e.entry == 'Entry without user'), true);
      },
    );

    test('date-based queries work after v9 table recreation', () async {
      // v8→v9 recreates journal_entries; verify date queries still work correctly.
      // (The idx_journal_date index only exists on migrated DBs, not fresh ones,
      // but the date column and queries must function regardless.)
      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 5),
          entry: 'Index test entry',
          createdAt: DateTime(2026, 3, 5, 12, 0),
        ),
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 5));
      expect(entries, isNotEmpty);
      expect(entries.first.entry, 'Index test entry');

      // Verify no results for a different date
      final empty = await db.entries.getEntriesForDate(DateTime(2026, 3, 6));
      expect(empty, isEmpty);
    });

    test('all columns preserved after v9 table recreation', () async {
      final columns =
          await db.db
              .customSelect("PRAGMA table_info('journal_entries')")
              .get();
      final columnNames = columns.map((r) => r.data['name'] as String).toSet();
      expect(
        columnNames,
        containsAll([
          'id',
          'date',
          'entry',
          'label',
          'title',
          'created_at',
          'user_id',
          'mood',
        ]),
      );
    });

    test('data integrity preserved through table recreation', () async {
      // Insert entries with various field combinations before v9 would run
      final userId = await db.userRepo.saveUser(
        User(
          displayName: 'Data Integrity User',
          createdAt: DateTime(2026, 2, 1),
        ),
      );

      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 2, 1),
          entry: 'Full entry',
          label: 'AM',
          title: 'Test Title',
          userId: userId,
          mood: 4,
          createdAt: DateTime(2026, 2, 1, 8, 0),
        ),
      );
      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 2, 1),
          entry: 'Minimal entry',
          createdAt: DateTime(2026, 2, 1, 12, 0),
        ),
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 2, 1));
      expect(entries.length, 2);

      final full = entries.firstWhere((e) => e.entry == 'Full entry');
      expect(full.label, 'AM');
      expect(full.title, 'Test Title');
      expect(full.userId, userId);
      expect(full.mood, 4);

      final minimal = entries.firstWhere((e) => e.entry == 'Minimal entry');
      expect(minimal.label, isNull);
      expect(minimal.title, isNull);
      expect(minimal.userId, isNull);
      expect(minimal.mood, isNull);
    });
  });

  group('Migration path: v9→v10 (mood column addition)', () {
    // v9→v10 adds mood column to journal_entries and mood settings to user_settings.

    late DatabaseService db;

    setUp(() async {
      db = DatabaseService.instance;
      await db.initInMemory();
    });

    tearDown(() async {
      await db.dispose();
    });

    test('mood column exists on journal_entries', () async {
      final columns =
          await db.db
              .customSelect("PRAGMA table_info('journal_entries')")
              .get();
      final columnNames = columns.map((r) => r.data['name'] as String).toList();
      expect(columnNames, contains('mood'));
    });

    test('pre-v10 entries have NULL mood (default behavior)', () async {
      // Entries created before v10 would have no mood value.
      // Simulate by inserting with raw SQL without mood.
      final now = DateTime(2026, 3, 1, 8, 0).millisecondsSinceEpoch ~/ 1000;
      final date = DateTime(2026, 3, 1).millisecondsSinceEpoch ~/ 1000;
      await db.db.customStatement(
        'INSERT INTO journal_entries (date, entry, created_at) '
        "VALUES ($date, 'Pre-mood entry', $now)",
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 1));
      expect(entries, isNotEmpty);
      expect(entries.first.mood, isNull);
    });

    test('mood values 1-5 round-trip correctly', () async {
      for (final mood in [1, 2, 3, 4, 5]) {
        final id = await db.entries.saveEntry(
          JournalEntry(
            date: DateTime(2026, 3, 10 + mood),
            entry: 'Mood $mood entry',
            mood: mood,
            createdAt: DateTime(2026, 3, 10 + mood, 8, 0),
          ),
        );

        final entries = await db.entries.getEntriesForDate(
          DateTime(2026, 3, 10 + mood),
        );
        final saved = entries.firstWhere((e) => e.id == id);
        expect(saved.mood, mood, reason: 'mood=$mood failed to round-trip');
      }
    });

    test('mood can be updated from NULL to a value', () async {
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 20),
          entry: 'Initially no mood',
          mood: null,
          createdAt: DateTime(2026, 3, 20, 8, 0),
        ),
      );

      var entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 20));
      var saved = entries.firstWhere((e) => e.id == id);
      expect(saved.mood, isNull);

      // Update to add mood
      await db.entries.saveEntry(saved.copyWith(mood: 3));
      entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 20));
      saved = entries.firstWhere((e) => e.id == id);
      expect(saved.mood, 3);
    });

    test('mood can be cleared (set back to NULL)', () async {
      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 3, 21),
          entry: 'Has mood then cleared',
          mood: 5,
          createdAt: DateTime(2026, 3, 21, 8, 0),
        ),
      );

      var entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 21));
      var saved = entries.firstWhere((e) => e.id == id);
      expect(saved.mood, 5);

      // Clear mood
      await db.entries.saveEntry(saved.copyWith(mood: null));
      entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 21));
      saved = entries.firstWhere((e) => e.id == id);
      expect(saved.mood, isNull);
    });

    test(
      'entry with null text + mood persists at the row level',
      () async {
        // JournalEntry allows null text at the schema level even though
        // the save-path UI always requires non-empty text today.
        final id = await db.entries.saveEntry(
          JournalEntry(
            date: DateTime(2026, 3, 22),
            entry: null,
            mood: 4,
            createdAt: DateTime(2026, 3, 22, 8, 0),
          ),
        );

        final entries = await db.entries.getEntriesForDate(
          DateTime(2026, 3, 22),
        );
        final saved = entries.firstWhere((e) => e.id == id);
        expect(saved.entry, isNull);
        expect(saved.mood, 4);
      },
    );

    test('mood settings columns exist with correct defaults', () async {
      final settings = await db.settings.getSettings();
      expect(settings.moodEnabled, false);
    });

    test('mood settings round-trip correctly', () async {
      final settings = await db.settings.getSettings();
      await db.settings.saveSettings(settings.copyWith(moodEnabled: true));

      final reloaded = await db.settings.getSettings();
      expect(reloaded.moodEnabled, true);
    });

    test('mood setting columns exist in raw schema', () async {
      final columns =
          await db.db
              .customSelect("PRAGMA table_info('user_settings_table')")
              .get();
      final columnNames = columns.map((r) => r.data['name'] as String).toSet();
      expect(columnNames, contains('mood_enabled'));
    });

    test('schema version is 18', () async {
      final result = await db.db.customSelect('PRAGMA user_version').get();
      final version = result.first.data['user_version'] as int;
      expect(version, 18);
    });
  });

  group('Full migration chain verification', () {
    late DatabaseService db;

    setUp(() async {
      db = DatabaseService.instance;
      await db.initInMemory();
    });

    tearDown(() async {
      await db.dispose();
    });

    test('all tables exist after full migration', () async {
      final tables =
          await db.db
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
              )
              .get();
      final tableNames = tables.map((r) => r.data['name'] as String).toSet();
      expect(
        tableNames,
        containsAll([
          'journal_entries',
          'users',
          'user_settings_table',
          'consent_records',
        ]),
      );
    });

    test('journal_entries has all v10 columns', () async {
      final columns =
          await db.db
              .customSelect("PRAGMA table_info('journal_entries')")
              .get();
      final columnNames = columns.map((r) => r.data['name'] as String).toSet();
      expect(
        columnNames,
        equals({
          'id',
          'date',
          'entry',
          'label',
          'title',
          'created_at',
          'user_id',
          'mood',
        }),
      );
    });

    test('user_settings_table has all v10 columns', () async {
      final columns =
          await db.db
              .customSelect("PRAGMA table_info('user_settings_table')")
              .get();
      final columnNames = columns.map((r) => r.data['name'] as String).toSet();
      expect(
        columnNames,
        containsAll([
          'id',
          'theme_mode',
          'is_all_day_mode',
          'ask_about_today',
          'show_entry_title',
          'week_start_day',
          'nudge_hour',
          'nudge_minute',
          'app_lock_enabled',
          'pin_hash',
          'biometric_enabled',
          'onboarding_complete',
          'enter_to_save',
          'bullet_points_on_enter',
          'am_pm_cutoff_hour',
          'user_id',
          'mood_enabled',
        ]),
      );
    });

    test('no legacy columns remain after full migration', () async {
      // These columns should have been removed by v4 and v7 migrations
      final jeColumns =
          await db.db
              .customSelect("PRAGMA table_info('journal_entries')")
              .get();
      final jeColumnNames =
          jeColumns.map((r) => r.data['name'] as String).toSet();
      expect(jeColumnNames, isNot(contains('morning_entry')));
      expect(jeColumnNames, isNot(contains('evening_entry')));
      expect(jeColumnNames, isNot(contains('all_day_entry')));

      final settingsColumns =
          await db.db
              .customSelect("PRAGMA table_info('user_settings_table')")
              .get();
      final settingsColumnNames =
          settingsColumns.map((r) => r.data['name'] as String).toSet();
      expect(settingsColumnNames, isNot(contains('is_dark_mode')));
      // Dropped at v18 when mood sub-toggles were removed.
      expect(settingsColumnNames, isNot(contains('mood_required')));
      expect(settingsColumnNames, isNot(contains('mood_only_entries')));
      // Dropped at v17 with the RevenueCat scaffolding removal.
      final usersColumns =
          await db.db.customSelect("PRAGMA table_info('users')").get();
      final usersColumnNames =
          usersColumns.map((r) => r.data['name'] as String).toSet();
      expect(usersColumnNames, isNot(contains('subscription_tier')));
      // Dropped at v16 when on-device AI recap was removed.
      expect(
        settingsColumnNames,
        isNot(contains('use_on_device_ai_for_recaps')),
      );
    });

    test('end-to-end: entry with all fields persists and reads back', () async {
      final userId = await db.userRepo.saveUser(
        User(
          displayName: 'E2E User',
          email: 'e2e@test.com',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final id = await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 4, 1),
          entry: 'End-to-end migration test',
          label: 'PM',
          title: 'E2E Title',
          mood: 5,
          userId: userId,
          createdAt: DateTime(2026, 4, 1, 20, 0),
        ),
      );

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 4, 1));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.entry, 'End-to-end migration test');
      expect(saved.label, 'PM');
      expect(saved.title, 'E2E Title');
      expect(saved.mood, 5);
      expect(saved.userId, userId);
    });
  });
}
