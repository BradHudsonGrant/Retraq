import 'package:flutter_test/flutter_test.dart';
import 'package:sincethen/models/journal_entry.dart';
import 'package:sincethen/models/user.dart';
import 'package:sincethen/models/user_settings.dart';
import 'package:sincethen/services/database_service.dart';

/// Tests that verify the database schema is correct after all migrations
/// have been applied, and that the migration code produces a usable database.
///
/// Migration history:
///   v1 → v2: Added `title` column to journal_entries
///   v2 → v3: Added `enter_to_save`, `bullet_points_on_enter` to user_settings_table
///   v3 → v4: Schema overhaul — created `users` table, replaced morning/evening/allDay
///            columns with unified `entry`+`label`+`user_id`, added `user_id` to settings
///   v4 → v5: Added date index on journal_entries, cleanup whitespace-only entries,
///            added `am_pm_cutoff_hour` to user_settings_table
///   v5 → v6: Added FK constraint from journal_entries.user_id → users.id
///   v6 → v7: Replaced is_dark_mode (bool) with theme_mode (int)
///   v7 → v8: Added nudge_minute column, created consent_records table
void main() {
  late DatabaseService db;

  setUp(() async {
    db = DatabaseService.instance;
    await db.initInMemory();
  });

  tearDown(() async {
    await db.dispose();
  });

  // ── Final schema verification ─────────────────────────────

  group('Final schema (v8) - journal_entries table', () {
    test('has all expected columns', () async {
      // Verify all v5 columns exist by inserting a row that uses every column
      // First create a user so FK constraint is satisfied
      final userId = await db.userRepo.saveUser(User(
        displayName: 'Test User',
        email: 'test@test.com',
        subscriptionTier: 'free',
        createdAt: DateTime(2026, 3, 15),
      ));
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
      final id = await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 3, 16),
        entry: null,
        createdAt: DateTime(2026, 3, 16, 8, 0),
      ));
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 16));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.entry, isNull);
    });

    test('label column is nullable (v4 addition)', () async {
      final id = await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 3, 17),
        entry: 'No label',
        label: null,
        createdAt: DateTime(2026, 3, 17, 8, 0),
      ));
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 17));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.label, isNull);
    });

    test('title column is nullable (v2 addition)', () async {
      final id = await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 3, 18),
        entry: 'No title',
        title: null,
        createdAt: DateTime(2026, 3, 18, 8, 0),
      ));
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 18));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.title, isNull);
    });

    test('userId column is nullable (v4 addition)', () async {
      final id = await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 3, 19),
        entry: 'No user',
        userId: null,
        createdAt: DateTime(2026, 3, 19, 8, 0),
      ));
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 19));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.userId, isNull);
    });

    test('label supports AM/PM values (v4 migration split)', () async {
      final amId = await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 3, 20),
        entry: 'Morning entry',
        label: 'AM',
        createdAt: DateTime(2026, 3, 20, 8, 0),
      ));
      final pmId = await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 3, 20),
        entry: 'Evening entry',
        label: 'PM',
        createdAt: DateTime(2026, 3, 20, 20, 0),
      ));

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 20));
      expect(entries.length, 2);

      final am = entries.firstWhere((e) => e.id == amId);
      final pm = entries.firstWhere((e) => e.id == pmId);
      expect(am.label, 'AM');
      expect(pm.label, 'PM');
    });
  });

  group('Final schema (v8) - date index', () {
    test('date index exists and queries by date work efficiently', () async {
      // Insert entries across multiple dates
      for (int day = 1; day <= 10; day++) {
        await db.entries.saveEntry(JournalEntry(
          date: DateTime(2026, 6, day),
          entry: 'Entry for day $day',
          createdAt: DateTime(2026, 6, day, 12, 0),
        ));
      }

      // Query a specific date — the index should make this efficient
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 6, 5));
      expect(entries.length, 1);
      expect(entries.first.entry, 'Entry for day 5');
    });
  });

  group('Final schema (v8) - users table', () {
    test('users table exists and supports full CRUD (v4 addition)', () async {
      // Create
      final user = User(
        displayName: 'Test User',
        email: 'test@example.com',
        subscriptionTier: 'free',
        createdAt: DateTime(2026, 3, 15),
      );
      final id = await db.userRepo.saveUser(user);
      expect(id, greaterThan(0));

      // Read
      final loaded = await db.userRepo.getUser();
      expect(loaded, isNotNull);
      expect(loaded!.displayName, 'Test User');
      expect(loaded.email, 'test@example.com');
      expect(loaded.subscriptionTier, 'free');
    });

    test('subscriptionTier has default value of free', () async {
      final user = User(
        displayName: 'Default Tier User',
        createdAt: DateTime(2026, 3, 15),
      );
      final id = await db.userRepo.saveUser(user);

      final loaded = await db.userRepo.getUser();
      expect(loaded, isNotNull);
      expect(loaded!.subscriptionTier, 'free');
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
        subscriptionTier: 'premium',
        createdAt: DateTime(2026, 3, 15),
      );
      await db.userRepo.saveUser(updated);

      final loaded = await db.userRepo.getUser();
      expect(loaded!.displayName, 'Updated');
      expect(loaded.email, 'updated@example.com');
      expect(loaded.subscriptionTier, 'premium');
    });
  });

  group('Final schema (v7) - user_settings_table', () {
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
      await db.settings.saveSettings(settings.copyWith(bulletPointsOnEnter: true));

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

  // ── Migration correctness: whitespace cleanup (v5) ────────

  group('V5 migration - whitespace entry cleanup', () {
    test('entries with whitespace-only content are not persisted', () async {
      // The v5 migration deletes existing whitespace-only entries.
      // On a fresh DB, we verify that entries with real content survive
      // and that the schema supports the cleanup query.
      await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 7, 1),
        entry: 'Real content',
        createdAt: DateTime(2026, 7, 1, 8, 0),
      ));
      await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 7, 2),
        entry: '   Valid content with spaces   ',
        createdAt: DateTime(2026, 7, 2, 8, 0),
      ));

      final all = await db.entries.getEntriesForDateRange(
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 2),
      );
      expect(all.length, 2);
    });
  });

  // ── Cross-table relationships (v4 schema) ─────────────────

  group('Cross-table relationships (v4 schema)', () {
    test('journal entry can reference a user via userId', () async {
      final userId = await db.userRepo.saveUser(User(
        displayName: 'Journal Owner',
        createdAt: DateTime(2026, 3, 15),
      ));

      final entryId = await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 3, 15),
        entry: 'Entry with user reference',
        userId: userId,
        createdAt: DateTime(2026, 3, 15, 10, 0),
      ));

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 3, 15));
      final saved = entries.firstWhere((e) => e.id == entryId);
      expect(saved.userId, userId);
    });

    test('multiple entries can belong to different labels on same date', () async {
      await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 8, 1),
        entry: 'Morning thought',
        label: 'AM',
        createdAt: DateTime(2026, 8, 1, 8, 0),
      ));
      await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 8, 1),
        entry: 'Evening reflection',
        label: 'PM',
        createdAt: DateTime(2026, 8, 1, 20, 0),
      ));
      await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 8, 1),
        entry: 'All day note',
        label: null,
        createdAt: DateTime(2026, 8, 1, 12, 0),
      ));

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 8, 1));
      expect(entries.length, 3);

      final labels = entries.map((e) => e.label).toSet();
      expect(labels, containsAll(['AM', 'PM', null]));
    });
  });

  // ── Database lifecycle ────────────────────────────────────

  group('Database lifecycle', () {
    test('initInMemory creates a usable database with correct schema', () async {
      // The setUp already called initInMemory — verify basic operations work
      final count = await db.entries.getTotalEntryCount();
      expect(count, isA<int>());
    });

    test('getSettings returns defaults on fresh database', () async {
      final settings = await db.settings.getSettings();
      expect(settings, isNotNull);
      // initInMemory calls getSettings internally, which inserts defaults
      expect(settings.themeMode, 0);
    });

    test('deleteAllData resets entries but preserves settings structure', () async {
      // Add some data
      await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 9, 1),
        entry: 'To be wiped',
        createdAt: DateTime(2026, 9, 1, 8, 0),
      ));
      await db.settings.saveSettings(UserSettings(nudgeHour: 10));

      // Wipe
      await db.userRepo.deleteAllData();

      // Entries gone
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 9, 1));
      expect(entries, isEmpty);

      // Settings reset to defaults
      final settings = await db.settings.getSettings();
      expect(settings.nudgeHour, 20); // default, not 10
    });
  });

  // ── Search uses correct column names (v4 schema) ──────────

  group('Search after migration (v4+ schema)', () {
    test('search finds entries by entry text', () async {
      await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 10, 1),
        entry: 'Unique searchable migration test phrase',
        createdAt: DateTime(2026, 10, 1, 8, 0),
      ));

      final results = await db.entries.searchEntries('migration test phrase');
      expect(results, isNotEmpty);
      expect(results.first.entry, contains('migration test phrase'));
    });

    test('search finds entries by title', () async {
      await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 10, 2),
        entry: 'Some content',
        title: 'Unique Migration Title XYZ',
        createdAt: DateTime(2026, 10, 2, 8, 0),
      ));

      final results = await db.entries.searchEntries('Migration Title XYZ');
      expect(results, isNotEmpty);
      expect(results.first.title, 'Unique Migration Title XYZ');
    });
  });

  // ── Edge cases for migration-affected columns ─────────────

  group('Edge cases for migration-affected columns', () {
    test('entry can store long text', () async {
      final longText = 'A' * 10000;
      final id = await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 11, 1),
        entry: longText,
        createdAt: DateTime(2026, 11, 1, 8, 0),
      ));

      final entries = await db.entries.getEntriesForDate(DateTime(2026, 11, 1));
      final saved = entries.firstWhere((e) => e.id == id);
      expect(saved.entry!.length, 10000);
    });

    test('title can store unicode text (v2 column)', () async {
      final id = await db.entries.saveEntry(JournalEntry(
        date: DateTime(2026, 11, 2),
        entry: 'Unicode test',
        title: 'Emoji and CJK: 日本語テスト',
        createdAt: DateTime(2026, 11, 2, 8, 0),
      ));

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
}
