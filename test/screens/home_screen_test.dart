@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
        'TL;DR of', 'How was', 'What happened',
        'Sum up', 'What stood', 'Brain dump', 'One thing',
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

      expect(find.text('Entry title (optional)'), findsNothing);

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

      expect(find.text('Save Entry'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('shows weekly progress indicator', (tester) async {
      await tester.pumpWidget(wrapWidget(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Compact progress bar shows week count message
      expect(find.textContaining('first entry'), findsOneWidget);

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
      await tester.tap(find.text('Save Entry'));
      await tester.pump();

      // Still shows Save Entry (not Saving...)
      expect(find.text('Save Entry'), findsOneWidget);

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
}
