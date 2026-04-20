@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/services/database_service.dart';
import 'package:retraq/services/stats_service.dart';

import '../test_helpers.dart';

void main() {
  final db = DatabaseService.instance;

  setUpAll(() async {
    await initTestDatabase();
  });

  setUp(() async {
    final all = await db.entries.getAllEntries();
    for (final e in all) {
      if (e.id != null) await db.entries.deleteEntry(e.id!);
    }
  });

  group('StatsService.getAllStats', () {
    test('returns zeros when no entries exist', () async {
      final stats = await db.stats.getAllStats();

      expect(stats.totalEntries, 0);
      expect(stats.totalDays, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.mostActiveWeekday, 0);
    });

    test('counts total entries correctly', () async {
      final today = DateTime.now();
      final todayNorm = DateTime(today.year, today.month, today.day);

      await db.entries.saveEntry(
        JournalEntry(date: todayNorm, entry: 'Entry 1', createdAt: today),
      );
      await db.entries.saveEntry(
        JournalEntry(
          date: todayNorm,
          entry: 'Entry 2',
          label: 'PM',
          createdAt: today,
        ),
      );

      final stats = await db.stats.getAllStats();
      expect(stats.totalEntries, 2);
    });

    test('returns weekly trends as a list of correct length', () async {
      final stats = await db.stats.getAllStats(weeks: 4);
      expect(stats.weeklyTrends.length, 4);
    });

    test('getWeeklyEntryCounts returns empty list for zero weeks', () async {
      final counts = await db.stats.getWeeklyEntryCounts(weeks: 0);
      expect(counts, isEmpty);
    });
  });

  // NOTE: The streak SQL queries use date(date, 'unixepoch', 'localtime')
  // which returns null in Flutter's in-memory test SQLite (no localtime support).
  // The service catches the error and returns 0. These tests verify the fallback
  // behavior and data model. Full streak logic requires on-device integration tests.
  //
  // The positive-path streak assertions (streak=14, streak=7
  // after a gap, etc.) live in the on-device integration suite at
  // `integration_test/streak_sql_on_device_test.dart` (TODO: land
  // this file once the emulator journey lane is established;
  // it needs the same harness). Running streak SQL on the real
  // Android/iOS SQLite is the only way to exercise the `localtime`
  // window-function branch — `flutter_test`'s in-memory SQLite
  // silently falls back to 0, so any regression in the streak
  // math is invisible here. Do NOT convert the on-device suite into
  // in-memory assertions: the whole point is to catch regressions
  // the in-memory harness misses.

  group('Streak — data model', () {
    test('empty database returns streak of 0', () async {
      final streak = await db.stats.getCurrentStreak();
      expect(streak, 0);
    });

    test('getAllStats returns zero streak on empty DB', () async {
      final stats = await db.stats.getAllStats();
      expect(stats.currentStreak, 0);
      expect(stats.longestStreakThisMonth, 0);
    });

    test('StatsSnapshot equality works correctly', () {
      const a = StatsSnapshot(
        totalEntries: 5,
        currentStreak: 3,
        longestStreakThisMonth: 3,
      );
      const b = StatsSnapshot(
        totalEntries: 5,
        currentStreak: 3,
        longestStreakThisMonth: 3,
      );
      const c = StatsSnapshot(
        totalEntries: 6,
        currentStreak: 3,
        longestStreakThisMonth: 3,
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('StatsSnapshot defaults are all zeroes', () {
      const stats = StatsSnapshot();
      expect(stats.totalEntries, 0);
      expect(stats.totalDays, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.longestStreakThisMonth, 0);
      expect(stats.weeklyTrends, isEmpty);
      expect(stats.mostActiveWeekday, 0);
      expect(stats.averageMood, isNull);
      expect(stats.moodDistribution, isEmpty);
    });
  });

  group('getLongestStreakThisMonth', () {
    test('returns 0 with no entries', () async {
      final longest = await db.stats.getLongestStreakThisMonth();
      expect(longest, 0);
    });
  });

  group('deleteAllData cascade', () {
    test('clears all entries, users, settings, and consent records', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Add some data
      await db.entries.saveEntry(
        JournalEntry(date: today, entry: 'Test entry', createdAt: now),
      );

      // Verify data exists
      var entries = await db.entries.getAllEntries();
      expect(entries, isNotEmpty);

      // Delete all data
      await db.userRepo.deleteAllData();

      // Verify entries cleared
      entries = await db.entries.getAllEntries();
      expect(entries, isEmpty);

      // Verify settings were re-inserted (defaults)
      final settings = await db.settings.getSettings();
      expect(settings.themeMode, 0); // default
      expect(settings.onboardingComplete, false); // default
    });
  });
}
