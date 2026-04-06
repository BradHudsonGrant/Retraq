import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/organisms/calendar_grid.dart';

import '../../test_helpers.dart';

void main() {
  group('CalendarGrid', () {
    testWidgets('renders day-of-week labels', (tester) async {
      await tester.pumpWidget(wrapWidget(
        CalendarGrid(
          month: DateTime(2026, 3),
          entryDays: const {},
          onDaySelected: (_) {},
          onPreviousMonth: () {},
          onNextMonth: () {},
        ),
      ));

      // Day labels row
      for (final day in ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']) {
        expect(find.text(day), findsOneWidget);
      }
    });

    testWidgets('renders correct number of days for March 2026 (31 days)', (tester) async {
      await tester.pumpWidget(wrapWidget(
        CalendarGrid(
          month: DateTime(2026, 3),
          entryDays: const {},
          onDaySelected: (_) {},
          onPreviousMonth: () {},
          onNextMonth: () {},
        ),
      ));

      // March 2026 has 31 days — verify day 1 and day 31 exist
      expect(find.text('1'), findsWidgets); // may include padding days
      expect(find.text('31'), findsWidgets);
    });

    testWidgets('displays month/year header', (tester) async {
      await tester.pumpWidget(wrapWidget(
        CalendarGrid(
          month: DateTime(2026, 3),
          entryDays: const {},
          onDaySelected: (_) {},
          onPreviousMonth: () {},
          onNextMonth: () {},
        ),
      ));

      expect(find.text('March 2026'), findsOneWidget);
    });

    testWidgets('calls onDaySelected when tapping a day', (tester) async {
      int? selectedDay;
      await tester.pumpWidget(wrapWidget(
        CalendarGrid(
          month: DateTime(2026, 3),
          entryDays: const {},
          onDaySelected: (day) => selectedDay = day,
          onPreviousMonth: () {},
          onNextMonth: () {},
        ),
      ));

      // Tap day 15
      await tester.tap(find.text('15').first);
      expect(selectedDay, 15);
    });

    testWidgets('previous month button calls callback', (tester) async {
      var called = false;
      await tester.pumpWidget(wrapWidget(
        CalendarGrid(
          month: DateTime(2026, 3),
          entryDays: const {},
          onDaySelected: (_) {},
          onPreviousMonth: () => called = true,
          onNextMonth: () {},
        ),
      ));

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(called, true);
    });

    testWidgets('next month button calls callback', (tester) async {
      var called = false;
      await tester.pumpWidget(wrapWidget(
        CalendarGrid(
          month: DateTime(2026, 3),
          entryDays: const {},
          onDaySelected: (_) {},
          onPreviousMonth: () {},
          onNextMonth: () => called = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(called, true);
    });

    testWidgets('shows "Month at a glance" header by default', (tester) async {
      await tester.pumpWidget(wrapWidget(
        CalendarGrid(
          month: DateTime(2026, 3),
          entryDays: const {},
          onDaySelected: (_) {},
          onPreviousMonth: () {},
          onNextMonth: () {},
        ),
      ));

      expect(find.text('Month at a glance'), findsOneWidget);
    });

    testWidgets('February 2026 has 28 days', (tester) async {
      await tester.pumpWidget(wrapWidget(
        CalendarGrid(
          month: DateTime(2026, 2),
          entryDays: const {},
          onDaySelected: (_) {},
          onPreviousMonth: () {},
          onNextMonth: () {},
        ),
      ));

      expect(find.text('28'), findsWidgets);
      expect(find.text('February 2026'), findsOneWidget);
    });
  });
}
