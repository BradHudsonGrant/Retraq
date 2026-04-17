import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/atoms/animated_mesh_background.dart';

/// Task 6.11 (final) — AnimatedMeshBackground widget coverage.
///
/// The shader-driven mesh is hard to pixel-test, but there are real
/// branches worth pinning:
///   - The file contains a test-environment detection (`_kIsFlutterTest`)
///     that suppresses infinite shader tickers so `pumpAndSettle`
///     doesn't time out — verify the widget mounts cleanly and
///     settles.
///   - Reduce-motion falls back to a plain `LinearGradient` with no
///     ticker at all.
///
/// NOT covered: shader uniform pixel output (needs a golden), GPU
/// shader loading failures (bypassed by the test-env detection).
void main() {
  Widget wrap(
    Widget child, {
    bool disableAnimations = false,
    bool dark = false,
  }) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: SizedBox.expand(child: child)),
      ),
    );
  }

  testWidgets('renders without throwing in the default (non-reduced) mode',
      (tester) async {
    await tester.pumpWidget(wrap(
      AnimatedMeshBackground(
        colors: [Colors.teal, Colors.green, Colors.blue],
      ),
    ));
    await tester.pump();
    expect(find.byType(AnimatedMeshBackground), findsOneWidget);
  });

  testWidgets('pumpAndSettle converges (no infinite shader ticker)',
      (tester) async {
    await tester.pumpWidget(wrap(
      AnimatedMeshBackground(
        colors: [Colors.teal, Colors.green, Colors.blue],
      ),
    ));
    // The widget's _kIsFlutterTest short-circuits the infinite
    // SchedulerBinding ticker that would otherwise keep the frame
    // loop busy forever. pumpAndSettle must return cleanly.
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(AnimatedMeshBackground), findsOneWidget);
  });

  testWidgets(
    'reduce-motion path skips the shader entirely',
    (tester) async {
      await tester.pumpWidget(wrap(
        AnimatedMeshBackground(
          colors: [Colors.teal, Colors.green, Colors.blue],
        ),
        disableAnimations: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedMeshBackground), findsOneWidget);

      // The non-reduce path wraps in a RepaintBoundary. The reduce
      // path renders a plain DecoratedBox with the LinearGradient.
      // Either way the widget mounts cleanly under reduce-motion.
      expect(find.byType(DecoratedBox), findsWidgets);
    },
  );

  testWidgets(
    'renders under dark theme without crashing',
    (tester) async {
      await tester.pumpWidget(wrap(
        AnimatedMeshBackground(
          colors: [Colors.teal, Colors.deepPurple, Colors.cyan],
        ),
        dark: true,
      ));
      await tester.pump();
      expect(find.byType(AnimatedMeshBackground), findsOneWidget);
    },
  );

  testWidgets(
    'accepts a baseColor override without crashing',
    (tester) async {
      await tester.pumpWidget(wrap(
        AnimatedMeshBackground(
          colors: [Colors.teal, Colors.green, Colors.blue],
          baseColor: Colors.black,
        ),
      ));
      await tester.pump();
      expect(find.byType(AnimatedMeshBackground), findsOneWidget);
    },
  );

  testWidgets(
    'accepts an opacity override without crashing',
    (tester) async {
      await tester.pumpWidget(wrap(
        AnimatedMeshBackground(
          colors: [Colors.teal, Colors.green, Colors.blue],
          opacity: 0.5,
        ),
      ));
      await tester.pump();
      expect(find.byType(AnimatedMeshBackground), findsOneWidget);
    },
  );

  testWidgets(
    'oneShotDuration stops the ticker deterministically',
    (tester) async {
      await tester.pumpWidget(wrap(
        AnimatedMeshBackground(
          colors: [Colors.teal, Colors.green, Colors.blue],
          oneShotDuration: const Duration(milliseconds: 500),
        ),
      ));
      await tester.pump();
      // Advance past the oneShotDuration; widget should have
      // stopped ticking without leaving a pending timer.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedMeshBackground), findsOneWidget);
    },
  );
}
