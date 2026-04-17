import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/atoms/glass_card.dart';

/// Task 6.11 (partial) — GlassCard widget coverage.
///
/// The widget has one real branch: reduce-motion vs normal. Under
/// reduce-motion, GlassCard falls back to a DecoratedBox with no
/// BackdropFilter — a performance + a11y decision. These tests pin
/// that contract down.
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

  testWidgets('renders with default props without throwing', (tester) async {
    await tester.pumpWidget(
      wrap(const GlassCard(child: Text('hello'))),
    );
    await tester.pump();
    expect(find.byType(GlassCard), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets(
    'default path uses BackdropFilter (frosted-glass composite)',
    (tester) async {
      await tester.pumpWidget(
        wrap(const GlassCard(child: Text('frosted'))),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
        reason: 'non-reduce-motion GlassCard must keep the blur layer',
      );
    },
  );

  testWidgets(
    'reduce-motion path falls back to DecoratedBox without BackdropFilter',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const GlassCard(child: Text('static')),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      // DecoratedBox present, BackdropFilter absent.
      expect(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byType(DecoratedBox),
        ),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
        reason:
            'reduce-motion GlassCard must skip BackdropFilter to avoid '
            'the offscreen composite cost that reduce-motion users have '
            'opted out of',
      );
    },
  );

  testWidgets(
    'reduce-motion path uses ClipRRect-free tree (no offscreen clip either)',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const GlassCard(child: Text('static')),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      // The non-reduce path wraps BackdropFilter in ClipRRect. The
      // reduce path does NOT — saves the clip layer cost.
      expect(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byType(ClipRRect),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'non-reduce path wraps BackdropFilter in ClipRRect',
    (tester) async {
      await tester.pumpWidget(
        wrap(const GlassCard(child: Text('blur'))),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byType(ClipRRect),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('child is rendered identically in both paths', (tester) async {
    // Normal path
    await tester.pumpWidget(
      wrap(const GlassCard(child: Text('same-kid'))),
    );
    await tester.pump();
    expect(find.text('same-kid'), findsOneWidget);

    // Reduce-motion path
    await tester.pumpWidget(
      wrap(
        const GlassCard(child: Text('same-kid')),
        disableAnimations: true,
      ),
    );
    await tester.pump();
    expect(find.text('same-kid'), findsOneWidget);
  });

  testWidgets('respects custom padding', (tester) async {
    await tester.pumpWidget(
      wrap(const GlassCard(
        padding: EdgeInsets.all(32),
        child: Text('padded'),
      )),
    );
    await tester.pump();

    final paddings = tester.widgetList<Padding>(
      find.descendant(
        of: find.byType(GlassCard),
        matching: find.byType(Padding),
      ),
    );
    // At least one Padding in the tree should have the custom
    // EdgeInsets we passed.
    expect(
      paddings.any((p) => p.padding == const EdgeInsets.all(32)),
      isTrue,
    );
  });
}
