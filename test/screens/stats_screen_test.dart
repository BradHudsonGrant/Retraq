@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/screens/stats_screen.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  // StatsScreen subscribes to a combined Drift stream and StatCards use
  // staggered entrance animations with up to 300ms delays. Pump past all timers.

  group('StatsScreen', () {
    testWidgets('renders "Stats" header', (tester) async {
      await tester.pumpWidget(wrapWidget(const StatsScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Stats'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('renders subtitle "Your journey so far."', (tester) async {
      await tester.pumpWidget(wrapWidget(const StatsScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Your journey so far.'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('shows empty state when no entries exist', (tester) async {
      await tester.pumpWidget(wrapWidget(const StatsScreen()));
      // watchAllStats debounces 600ms before first emission; pump past it
      // so the empty-state UI has rendered before assertions run.
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('No stats yet'), findsOneWidget);
      expect(
        find.text('Start journaling to see your patterns and streaks.'),
        findsOneWidget,
      );

      await flushDriftTimers(tester);
    });

    testWidgets('disposes cleanly', (tester) async {
      await tester.pumpWidget(wrapWidget(const StatsScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(StatsScreen), findsOneWidget);

      await flushDriftTimers(tester);
    });
  });
}
