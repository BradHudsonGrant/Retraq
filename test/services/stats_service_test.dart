@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sincethen/models/journal_entry.dart';
import 'package:sincethen/services/database_service.dart';

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

      await db.entries.saveEntry(JournalEntry(
        date: todayNorm,
        entry: 'Entry 1',
        createdAt: today,
      ));
      await db.entries.saveEntry(JournalEntry(
        date: todayNorm,
        entry: 'Entry 2',
        label: 'PM',
        createdAt: today,
      ));

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

  group('deleteAllData cascade', () {
    test('clears all entries, users, settings, and consent records', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Add some data
      await db.entries.saveEntry(JournalEntry(
        date: today,
        entry: 'Test entry',
        createdAt: now,
      ));

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
