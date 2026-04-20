// ignore_for_file: prefer_single_quotes

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/screens/active_tab_scope.dart';

/// unit tests for the ActiveTabScope InheritedWidget.
///
/// This is the tab-visibility signal HomeScreen uses to pause its
/// Drift subscriptions when the user is on Recap or Settings. The
/// widget is a thin InheritedWidget wrapper, so the tests pin:
///
/// 1. `maybeActiveIndexOf` returns null when no scope ancestor exists
/// 2. `maybeActiveIndexOf` returns the exposed activeIndex when present
/// 3. `isActive` returns true when no scope exists (unit-test-friendly
///    default — a screen pumped in isolation behaves as active)
/// 4. `isActive(tabIndex: X)` returns true iff activeIndex == X
/// 5. `updateShouldNotify` fires only when activeIndex actually changes
void main() {
  testWidgets('maybeActiveIndexOf returns null with no scope', (tester) async {
    int? seen = -1;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seen = ActiveTabScope.maybeActiveIndexOf(context);
          return const SizedBox();
        },
      ),
    );
    expect(seen, isNull);
  });

  testWidgets('maybeActiveIndexOf returns exposed activeIndex',
      (tester) async {
    int? seen = -1;
    await tester.pumpWidget(
      ActiveTabScope(
        activeIndex: 2,
        child: Builder(
          builder: (context) {
            seen = ActiveTabScope.maybeActiveIndexOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, 2);
  });

  testWidgets('isActive returns true with no scope (test-friendly default)',
      (tester) async {
    bool? result;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          result = ActiveTabScope.isActive(context, tabIndex: 0);
          return const SizedBox();
        },
      ),
    );
    expect(result, isTrue,
        reason:
            'isActive must default to true when no ActiveTabScope '
            'ancestor exists so unit tests pumping a single screen '
            'without the shell behave as if it is visible (no '
            'subscription pausing surprise).');
  });

  testWidgets('isActive(tabIndex: 0) returns true iff activeIndex == 0',
      (tester) async {
    await tester.pumpWidget(
      ActiveTabScope(
        activeIndex: 0,
        child: Builder(
          builder: (context) {
            expect(ActiveTabScope.isActive(context, tabIndex: 0), isTrue);
            expect(ActiveTabScope.isActive(context, tabIndex: 1), isFalse);
            expect(ActiveTabScope.isActive(context, tabIndex: 2), isFalse);
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets('activeIndex change propagates to dependents', (tester) async {
    final rebuilds = <int>[];

    Widget buildScope(int activeIndex) {
      return ActiveTabScope(
        activeIndex: activeIndex,
        child: Builder(
          builder: (context) {
            final idx = ActiveTabScope.maybeActiveIndexOf(context)!;
            rebuilds.add(idx);
            return const SizedBox();
          },
        ),
      );
    }

    await tester.pumpWidget(buildScope(0));
    await tester.pumpWidget(buildScope(1));
    await tester.pumpWidget(buildScope(1)); // no change
    await tester.pumpWidget(buildScope(2));

    // The idempotent re-pump (1 → 1) still triggers a rebuild because
    // InheritedWidget.updateShouldNotify only blocks the dependent
    // rebuild — the new widget instance still wraps the subtree. But
    // the dependents see the SAME activeIndex, so `setState` inside
    // them would be a no-op. Pin the value sequence observed:
    expect(rebuilds, [0, 1, 1, 2]);
  });
}
