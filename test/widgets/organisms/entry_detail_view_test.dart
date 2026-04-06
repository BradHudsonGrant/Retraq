import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/widgets/organisms/entry_detail_view.dart';

import '../../test_helpers.dart';

void main() {
  final testDate = DateTime(2026, 3, 15);

  group('EntryDetailView', () {
    testWidgets('renders formatted date label once for multiple entries', (tester) async {
      final entries = [
        JournalEntry(date: testDate, entry: 'Entry one', createdAt: testDate),
        JournalEntry(date: testDate, entry: 'Entry two', createdAt: testDate),
      ];
      await tester.pumpWidget(wrapScrollable(
        EntryDetailView(entries: entries, date: testDate),
      ));

      // Date divider shown once
      expect(find.textContaining('MARCH 15'), findsOneWidget);
      // Both entries rendered
      expect(find.text('Entry one'), findsOneWidget);
      expect(find.text('Entry two'), findsOneWidget);
    });

    testWidgets('renders entry text', (tester) async {
      final entry = JournalEntry(
        date: testDate,
        entry: 'Had a productive day',
        createdAt: testDate,
      );
      await tester.pumpWidget(wrapScrollable(
        EntryDetailView(entries: [entry], date: testDate),
      ));

      expect(find.text('Had a productive day'), findsOneWidget);
    });

    testWidgets('renders AM label chip', (tester) async {
      final entry = JournalEntry(
        date: testDate,
        entry: 'Good morning workout',
        label: 'AM',
        createdAt: testDate,
      );
      await tester.pumpWidget(wrapScrollable(
        EntryDetailView(entries: [entry], date: testDate),
      ));

      expect(find.text('AM'), findsOneWidget);
      expect(find.text('Good morning workout'), findsOneWidget);
    });

    testWidgets('renders PM label chip', (tester) async {
      final entry = JournalEntry(
        date: testDate,
        entry: 'Relaxed in the evening',
        label: 'PM',
        createdAt: testDate,
      );
      await tester.pumpWidget(wrapScrollable(
        EntryDetailView(entries: [entry], date: testDate),
      ));

      expect(find.text('PM'), findsOneWidget);
      expect(find.text('Relaxed in the evening'), findsOneWidget);
    });

    testWidgets('shows share icon button', (tester) async {
      final entry = JournalEntry(
        date: testDate,
        entry: 'Shareable content',
        createdAt: testDate,
      );
      await tester.pumpWidget(wrapScrollable(
        EntryDetailView(entries: [entry], date: testDate),
      ));

      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });

    testWidgets('renders separate AM and PM entries', (tester) async {
      final entries = [
        JournalEntry(
          date: testDate,
          entry: 'Morning text',
          label: 'AM',
          createdAt: DateTime(2026, 3, 15, 9, 0),
        ),
        JournalEntry(
          date: testDate,
          entry: 'Evening text',
          label: 'PM',
          createdAt: DateTime(2026, 3, 15, 20, 0),
        ),
      ];
      await tester.pumpWidget(wrapScrollable(
        EntryDetailView(entries: entries, date: testDate),
      ));

      expect(find.text('AM'), findsOneWidget);
      expect(find.text('Morning text'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
      expect(find.text('Evening text'), findsOneWidget);
    });

    testWidgets('shows timestamp for each entry', (tester) async {
      final entry = JournalEntry(
        date: testDate,
        entry: 'Test',
        createdAt: DateTime(2026, 3, 15, 14, 30),
      );
      await tester.pumpWidget(wrapScrollable(
        EntryDetailView(entries: [entry], date: testDate),
      ));

      expect(find.text('2:30 PM'), findsOneWidget);
    });
  });
}
