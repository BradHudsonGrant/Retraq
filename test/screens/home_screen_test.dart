@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/l10n/app_localizations.dart';
import 'package:retraq/services/database_service.dart';
import 'package:retraq/screens/home_screen.dart';
import 'package:retraq/utils/journal_prompts.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  // HomeScreen subscribes to Drift streams. Drift's StreamQueryStore creates
  // zero-duration timers on stream cancellation that FakeAsync reports as
  // "pending" on teardown. We work around this by pumping zero-duration
  // at the end of each test to flush those timers before widget disposal.

  group('HomeScreen', () {
    testWidgets('renders hero prompt with accent word', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // The hero prompt is a Text.rich with the prompt + accent word (date label).
      // Verify one of the known hero prompt fragments is present.
      final heroPrompts = [
        'TL;DR of',
        'How was',
        'What happened',
        'Sum up',
        'What stood',
        'Brain dump',
        'One thing',
      ];
      final found = heroPrompts.any(
        (p) => find.textContaining(p).evaluate().isNotEmpty,
      );
      expect(found, isTrue, reason: 'Expected one of the hero prompt texts');

      // Dispose widget and flush Drift timers
      await flushDriftTimers(tester);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Brain dump here. Full sentences optional.'),
        findsOneWidget,
      );

      await flushDriftTimers(tester);
    });

    testWidgets('hides entry title field by default', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Traq title (optional)'), findsNothing);

      await flushDriftTimers(tester);
    });

    testWidgets('shows all-day text area by default', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(dailyJournalPrompt()), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('shows Save Entry button', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Save Traq'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('shows weekly progress indicator', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Compact progress bar shows week count message
      expect(find.textContaining('first traq'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('can type in text area', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Find the main text field (the one with the rotating prompt)
      final textField = find.byType(TextField).last;
      await tester.enterText(textField, 'Had a great morning');
      await tester.pump();

      expect(find.text('Had a great morning'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('empty entry does not save', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap save with empty field — should not crash or show saving state
      await tester.tap(find.text('Save Traq'));
      await tester.pump();

      // Still shows Save Entry (not Saving...)
      expect(find.text('Save Traq'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('shows date chip with Today label', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Date chip should show "Today" by default
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(HomeScreen), findsOneWidget);

      await flushDriftTimers(tester);
    });
  });

  // End-to-end coverage of the primary user action: "write a traq and save it".
  // The broader group above uses setUpAll (shared DB) and deliberately never
  // writes rows, so we isolate the save flow in its own group with a per-test
  // fresh DB to avoid leaking state into the read-only tests.
  //
  // We pump the screen inside a MediaQuery with `disableAnimations: true` so
  // the save-success overlay's staggered animation controllers jump straight
  // to the end state — otherwise their pending timers trip the framework's
  // !timersPending assertion at tearDown.
  group('HomeScreen save flow', () {
    setUp(() async {
      await DatabaseService.instance.initInMemory();
    });

    Widget wrapHome() {
      return MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: HomeScreen()),
        ),
      );
    }

    testWidgets('typing text then tapping Save persists a journal entry', (
      tester,
    ) async {
      final db = DatabaseService.instance;
      final today = DateTime.now();
      final dayKey = DateTime(today.year, today.month, today.day);

      // Precondition: DB is empty for today.
      expect(await db.entries.getEntriesForDate(dayKey), isEmpty);

      await tester.pumpWidget(wrapHome());
      await tester.pump(const Duration(milliseconds: 200));

      // Enter text in the main entry field.
      final textField = find.byType(TextField).last;
      await tester.enterText(textField, 'Wave 8 shipped');
      await tester.pump();

      // Tap Save Traq. With animations disabled, the save-success overlay
      // jumps straight to its dismissed state.
      await tester.tap(find.text('Save Traq'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Postcondition: exactly one entry for today with the typed text.
      final entries = await db.entries.getEntriesForDate(dayKey);
      expect(entries, hasLength(1));
      expect(entries.single.entry, 'Wave 8 shipped');

      await flushDriftTimers(tester);
    });

    testWidgets('empty text with save tap writes nothing to the DB', (
      tester,
    ) async {
      final db = DatabaseService.instance;
      final today = DateTime.now();
      final dayKey = DateTime(today.year, today.month, today.day);

      await tester.pumpWidget(wrapHome());
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Save Traq'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(await db.entries.getEntriesForDate(dayKey), isEmpty);

      await flushDriftTimers(tester);
    });
  });
}
