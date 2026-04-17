@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/screens/recap_screen.dart';
import 'package:retraq/widgets/molecules/segmented_pill.dart';
import 'package:retraq/widgets/organisms/calendar_grid.dart';
import 'package:retraq/widgets/organisms/week_day_list.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  group('RecapScreen', () {
    testWidgets('renders Recap header', (tester) async {
      await tester.pumpWidget(wrapWidget(const RecapScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Recap'), findsOneWidget);
      await flushDriftTimers(tester);
    });

    testWidgets(
      'shows both Entries/Insights pill and Week/Month toggle in browse mode',
      (tester) async {
        // Task 2.5 — RecapScreen now has TWO SegmentedPills in browse
        // mode: the top-level Entries/Insights toggle and the
        // existing Week/Month toggle inside the Entries pane.
        await tester.pumpWidget(wrapWidget(const RecapScreen()));
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(SegmentedPill), findsNWidgets(2));
        expect(find.text('Entries'), findsOneWidget);
        expect(find.text('Insights'), findsOneWidget);
        expect(find.text('Week'), findsOneWidget);
        expect(find.text('Month'), findsOneWidget);
        await flushDriftTimers(tester);
      },
    );

    testWidgets(
      'tapping Insights hides Week/Month pill and shows Stats content',
      (tester) async {
        // Task 2.5 — the Entries pane's Week/Month pill is scoped
        // INSIDE the Entries branch; switching to Insights collapses
        // that whole branch.
        await tester.pumpWidget(wrapWidget(const RecapScreen()));
        await tester.pump(const Duration(milliseconds: 200));

        // Sanity: both pills present in default Entries mode.
        expect(find.text('Week'), findsOneWidget);

        // Tap Insights.
        await tester.tap(find.text('Insights'));
        await tester.pump(const Duration(milliseconds: 300));

        // Week/Month pill gone; Entries pill still visible.
        expect(find.text('Week'), findsNothing,
            reason:
                'Insights pane must hide the Week/Month toggle so the '
                'top-level pill is the only visible nav surface.');
        expect(find.text('Entries'), findsOneWidget);
        expect(find.text('Insights'), findsOneWidget);
        await flushDriftTimers(tester);
      },
    );

    testWidgets(
      'tapping Entries restores the Week/Month pill from Insights',
      (tester) async {
        await tester.pumpWidget(wrapWidget(const RecapScreen()));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.text('Insights'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Week'), findsNothing);

        await tester.tap(find.text('Entries'));
        await tester.pump(const Duration(milliseconds: 300));

        // Week/Month pill is back.
        expect(find.text('Week'), findsOneWidget);
        expect(find.text('Month'), findsOneWidget);
        await flushDriftTimers(tester);
      },
    );

    testWidgets('defaults to week view with empty state (no entries)', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWidget(const RecapScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // With empty database, shows empty state instead of WeekDayList
      expect(find.text('No traqs yet'), findsOneWidget);
      // CalendarGrid should NOT be shown in default week view
      expect(find.byType(CalendarGrid), findsNothing);
      await flushDriftTimers(tester);
    });

    testWidgets('switching to Month shows CalendarGrid', (tester) async {
      await tester.pumpWidget(wrapWidget(const RecapScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap "Month" in the toggle
      await tester.tap(find.text('Month'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CalendarGrid), findsOneWidget);
      expect(find.byType(WeekDayList), findsNothing);
      await flushDriftTimers(tester);
    });

    testWidgets(
      'shows "No entry for this day" when selecting empty day in month view',
      (tester) async {
        await tester.pumpWidget(wrapWidget(const RecapScreen()));
        await tester.pump(const Duration(milliseconds: 200));

        // Switch to month view
        await tester.tap(find.text('Month'));
        await tester.pump(const Duration(milliseconds: 300));

        // Tap day 1
        final dayOne = find.text('1');
        if (dayOne.evaluate().isNotEmpty) {
          await tester.tap(dayOne.first);
          await tester.pump(const Duration(milliseconds: 200));

          expect(find.text('No entry for this day'), findsOneWidget);
        }
        await flushDriftTimers(tester);
      },
    );

    testWidgets('shows search icon button', (tester) async {
      await tester.pumpWidget(wrapWidget(const RecapScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.search), findsOneWidget);
      await flushDriftTimers(tester);
    });

    testWidgets('tapping search icon shows search field', (tester) async {
      await tester.pumpWidget(wrapWidget(const RecapScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search entries...'), findsOneWidget);
      await flushDriftTimers(tester);
    });
  });
}
