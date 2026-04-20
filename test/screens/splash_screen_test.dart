import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/screens/splash_screen.dart';
import 'package:retraq/widgets/atoms/loader_dots.dart';
import 'package:retraq/widgets/atoms/retraq_logo.dart';

import '../test_helpers.dart';

/// Smoke tests for SplashScreen.
///
/// Scope: verify the screen renders without throwing, surfaces the
/// Retraq logo + loader affordance, and respects the brand surface
/// colour. The splash is the very first frame the user sees; a
/// render regression would be immediately user-visible but not
/// caught by the existing widget tests because SplashScreen isn't
/// mounted in any fixture.
///
/// Animation timing (mesh shader oneShot + logo fade + loader dots)
/// is left to manual / golden testing — widget tests can't reliably
/// capture the AnimatedMeshBackground shader output.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: child,
    );
  }

  setUp(() => setUpFakeSecureStorage());
  tearDown(() => resetFakeSecureStorage());

  testWidgets('renders without throwing', (tester) async {
    await tester.pumpWidget(wrap(const SplashScreen()));
    // Pump a single frame; do NOT pumpAndSettle (mesh background
    // has a 6-second oneShot that would otherwise block).
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('surfaces Retraq logo', (tester) async {
    await tester.pumpWidget(wrap(const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(RetraqLogo), findsOneWidget);
  });

  testWidgets('shows loader dots affordance', (tester) async {
    await tester.pumpWidget(wrap(const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LoaderDots), findsOneWidget);
  });

  testWidgets('uses surface colour as Scaffold background', (tester) async {
    await tester.pumpWidget(wrap(const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final cs = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
    expect(scaffold.backgroundColor, cs.surface);
  });

  testWidgets('renders in dark mode without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const SplashScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(RetraqLogo), findsOneWidget);
  });
}
