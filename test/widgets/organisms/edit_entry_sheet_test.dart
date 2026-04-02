@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sincethen/models/journal_entry.dart';
import 'package:sincethen/services/database_service.dart';
import 'package:sincethen/widgets/organisms/edit_entry_sheet.dart';

import '../../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  final testEntry = JournalEntry(
    id: 1,
    date: DateTime(2026, 3, 15),
    entry: 'Test entry text',
    title: 'Test Title',
    label: 'AM',
    createdAt: DateTime(2026, 3, 15, 9, 0),
  );

  Widget buildOpener(JournalEntry entry) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => EditEntrySheet.show(context, entry),
            child: const Text('Open'),
          );
        }),
      ),
    );
  }

  group('EditEntrySheet', () {
    testWidgets('shows edit entry title', (tester) async {
      await DatabaseService.instance.entries.saveEntry(testEntry);

      await tester.pumpWidget(buildOpener(testEntry));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Entry'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('shows pre-filled entry text', (tester) async {
      await DatabaseService.instance.entries.saveEntry(testEntry);

      await tester.pumpWidget(buildOpener(testEntry));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Test entry text'), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('shows delete icon button', (tester) async {
      await DatabaseService.instance.entries.saveEntry(testEntry);

      await tester.pumpWidget(buildOpener(testEntry));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('shows Save Changes button text', (tester) async {
      await DatabaseService.instance.entries.saveEntry(testEntry);

      await tester.pumpWidget(buildOpener(testEntry));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Save Changes'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('shows AM label chip when entry has AM label', (tester) async {
      await DatabaseService.instance.entries.saveEntry(testEntry);

      await tester.pumpWidget(buildOpener(testEntry));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('AM'), findsOneWidget);

      await flushDriftTimers(tester);
    });
  });
}
