@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sincethen/screens/recap_screen.dart';
import 'package:sincethen/widgets/molecules/segmented_pill.dart';
import 'package:sincethen/widgets/organisms/calendar_grid.dart';
import 'package:sincethen/widgets/organisms/week_day_list.dart';

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

    testWidgets('shows Week/Month toggle', (tester) async {
      await tester.pumpWidget(wrapWidget(const RecapScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SegmentedPill), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      await flushDriftTimers(tester);
    });

    testWidgets('defaults to week view with empty state (no entries)', (tester) async {
      await tester.pumpWidget(wrapWidget(const RecapScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // With empty database, shows empty state instead of WeekDayList
      expect(find.text('No entries yet'), findsOneWidget);
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

    testWidgets('shows "No entry for this day" when selecting empty day in month view',
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
    });

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
