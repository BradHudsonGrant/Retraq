@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/services/database_service.dart';
import 'package:retraq/services/recap_service.dart';

import '../test_helpers.dart';

void main() {
  final db = DatabaseService.instance;
  late RecapService recapService;

  setUpAll(() async {
    await initTestDatabase();
    recapService = RecapService(db.entries);
  });

  setUp(() async {
    // Clear all entries before each test.
    final all = await db.entries.getAllEntries();
    for (final e in all) {
      if (e.id != null) await db.entries.deleteEntry(e.id!);
    }
  });

  group('RecapService.getWeeklySummary', () {
    test('returns empty summary when no entries exist', () async {
      final monday = DateTime(2026, 3, 30); // Monday
      final summary = await recapService.getWeeklySummary(monday, DateTime.monday);

      expect(summary.totalEntries, 0);
      expect(summary.activeDays, 0);
      expect(summary.streak, 0);
      expect(summary.busiestDay, '');
      expect(summary.observation, contains('No entries this week'));
    });

    test('returns correct summary for one entry', () async {
      final monday = DateTime(2026, 3, 30);
      await db.entries.saveEntry(JournalEntry(
        date: monday,
        entry: 'Test entry',
        createdAt: DateTime.now(),
      ));

      final summary = await recapService.getWeeklySummary(monday, DateTime.monday);

      expect(summary.totalEntries, 1);
      expect(summary.activeDays, 1);
      expect(summary.busiestDay, 'Monday');
      expect(summary.observation, contains('one moment'));
    });

    test('detects busiest day correctly', () async {
      final monday = DateTime(2026, 3, 30);
      final tuesday = DateTime(2026, 3, 31);

      // One entry Monday, two entries Tuesday
      await db.entries.saveEntry(JournalEntry(
        date: monday,
        entry: 'Monday entry',
        createdAt: DateTime.now(),
      ));
      await db.entries.saveEntry(JournalEntry(
        date: tuesday,
        entry: 'Tuesday AM',
        label: 'AM',
        createdAt: DateTime.now(),
      ));
      await db.entries.saveEntry(JournalEntry(
        date: tuesday,
        entry: 'Tuesday PM',
        label: 'PM',
        createdAt: DateTime.now(),
      ));

      final summary = await recapService.getWeeklySummary(monday, DateTime.monday);

      expect(summary.totalEntries, 3);
      expect(summary.activeDays, 2);
      expect(summary.busiestDay, 'Tuesday');
    });

    test('detects preferred time as morning when all AM', () async {
      final monday = DateTime(2026, 3, 30);
      await db.entries.saveEntry(JournalEntry(
        date: monday,
        entry: 'Morning entry',
        label: 'AM',
        createdAt: DateTime.now(),
      ));

      final summary = await recapService.getWeeklySummary(monday, DateTime.monday);
      expect(summary.preferredTime, 'morning');
    });

    test('detects preferred time as evening when all PM', () async {
      final monday = DateTime(2026, 3, 30);
      await db.entries.saveEntry(JournalEntry(
        date: monday,
        entry: 'Evening entry',
        label: 'PM',
        createdAt: DateTime.now(),
      ));

      final summary = await recapService.getWeeklySummary(monday, DateTime.monday);
      expect(summary.preferredTime, 'evening');
    });

    test('detects every-day journaling', () async {
      final monday = DateTime(2026, 3, 30);
      for (int i = 0; i < 7; i++) {
        await db.entries.saveEntry(JournalEntry(
          date: monday.add(Duration(days: i)),
          entry: 'Day $i',
          createdAt: DateTime.now(),
        ));
      }

      final summary = await recapService.getWeeklySummary(monday, DateTime.monday);

      expect(summary.totalEntries, 7);
      expect(summary.activeDays, 7);
      expect(summary.observation, contains('every day'));
    });

    test('detects streak of 3+ days', () async {
      final monday = DateTime(2026, 3, 30);
      for (int i = 0; i < 3; i++) {
        await db.entries.saveEntry(JournalEntry(
          date: monday.add(Duration(days: i)),
          entry: 'Day $i',
          createdAt: DateTime.now(),
        ));
      }

      final summary = await recapService.getWeeklySummary(monday, DateTime.monday);
      expect(summary.streak, 3);
      expect(summary.observation, contains('3-day streak'));
    });
  });
}
