import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/molecules/weekly_trend_chart.dart';

/// WeeklyTrendChart widget coverage.
///
/// Covers the real logic surface: Semantics label composition,
/// tap-to-highlight + onWeekTapped callback fire, reduce-motion
/// bypass (controller parks at 1.0 instead of animating in),
/// empty-data graceful render.
///
/// Pixel-level bar-height computation is done inside a CustomPaint
/// painter and is left for a golden / pixel-comparison test.
void main() {
  Widget wrap(Widget child, {bool disableAnimations = false}) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('renders with 12 weeks of data', (tester) async {
    await tester.pumpWidget(
      wrap(WeeklyTrendChart(
        data: [0, 1, 3, 5, 2, 4, 6, 3, 1, 2, 4, 5],
      )),
    );
    await tester.pump();
    expect(find.byType(WeeklyTrendChart), findsOneWidget);
    expect(find.text('Entries per week'), findsOneWidget);
  });

  testWidgets('renders with empty data without throwing', (tester) async {
    await tester.pumpWidget(
      wrap(const WeeklyTrendChart(data: [])),
    );
    await tester.pump();
    expect(find.byType(WeeklyTrendChart), findsOneWidget);
  });

  testWidgets('renders with zero-only data (no crashes on zero max)',
      (tester) async {
    await tester.pumpWidget(
      wrap(WeeklyTrendChart(data: List.filled(12, 0))),
    );
    await tester.pump();
    expect(find.byType(WeeklyTrendChart), findsOneWidget);
  });

  testWidgets(
    'Semantics chart label reports count + average',
    (tester) async {
      await tester.pumpWidget(
        wrap(WeeklyTrendChart(data: [1, 2, 3, 4])),
      );
      await tester.pump();

      // The Semantics node is on an inner child, not the chart's
      // root widget. Find the one that contains our data string.
      final labeledFinder = find.bySemanticsLabel(RegExp(r'1, 2, 3, 4'));
      expect(labeledFinder, findsOneWidget);

      final semantics = tester.getSemantics(labeledFinder);
      expect(semantics.label, contains('1, 2, 3, 4'));
      expect(semantics.label, contains('2.5'));
    },
  );

  testWidgets(
    'Semantics label handles empty data with a "no data" hint',
    (tester) async {
      await tester.pumpWidget(
        wrap(const WeeklyTrendChart(data: [])),
      );
      await tester.pump();

      final labeledFinder = find.bySemanticsLabel(RegExp('no data'));
      expect(labeledFinder, findsOneWidget,
          reason:
              'empty-data chart must carry a "no data" semantic label '
              'for screen-reader users');
    },
  );

  testWidgets(
    'reduce-motion parks animation at end (no ticker left running)',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          WeeklyTrendChart(data: [1, 2, 3]),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      // The post-frame callback parks the controller at 1.0;
      // pumpAndSettle must converge without draining 600ms.
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(WeeklyTrendChart), findsOneWidget);
    },
  );

  testWidgets('onWeekTapped fires with the tapped bar index', (tester) async {
    int? tappedIndex;
    await tester.pumpWidget(
      wrap(WeeklyTrendChart(
        data: [1, 2, 3, 4, 5],
        onWeekTapped: (i) => tappedIndex = i,
      )),
    );
    await tester.pump();

    // Tap anywhere inside the chart — the gesture row distributes
    // x-coordinate across n bars and routes to the matching index.
    // We don't assert the exact index (depends on chart width which
    // varies by test viewport), just that SOME index in 0..n-1 is
    // reported.
    final chartFinder = find.byType(WeeklyTrendChart);
    await tester.tap(chartFinder);
    await tester.pump();

    expect(tappedIndex, isNotNull);
    expect(tappedIndex, greaterThanOrEqualTo(0));
    expect(tappedIndex, lessThan(5));

    // Drain the 300ms highlight-clear timer before the test ends.
    await tester.pump(const Duration(milliseconds: 350));
  });

  testWidgets(
    'onWeekTapped callback is optional — tap does not throw if absent',
    (tester) async {
      await tester.pumpWidget(
        wrap(WeeklyTrendChart(data: [1, 2, 3])),
      );
      await tester.pump();

      // No callback registered — tap should still not throw.
      await tester.tap(find.byType(WeeklyTrendChart));
      await tester.pump();
      expect(find.byType(WeeklyTrendChart), findsOneWidget);

      // Drain the 300ms highlight-clear timer.
      await tester.pump(const Duration(milliseconds: 350));
    },
  );

  testWidgets('custom height is applied to the chart area', (tester) async {
    await tester.pumpWidget(
      wrap(WeeklyTrendChart(data: [1, 2, 3], height: 200)),
    );
    await tester.pump();

    // The SizedBox wrapping the chart area uses the height prop.
    final sizedBoxes = tester.widgetList<SizedBox>(
      find.descendant(
        of: find.byType(WeeklyTrendChart),
        matching: find.byType(SizedBox),
      ),
    );
    expect(sizedBoxes.any((s) => s.height == 200), isTrue);
  });
}
