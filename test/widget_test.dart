@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sincethen/screens/app_shell.dart';

import 'test_helpers.dart';

/// Smoke tests for AppShell navigation.
/// These are integration-level tests that require a real (in-memory) database.
/// Drift's stream query cleanup creates zero-duration timers that FakeAsync
/// reports as "pending" on teardown, so we run these with real async.
void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  Widget wrapShell() => MaterialApp(
        home: AppShell(
          onThemeModeChanged: (_) async {},
          themeMode: ThemeMode.system,
        ),
      );

  testWidgets('AppShell renders Top Bar and four tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrapShell());
    await tester.pump(const Duration(milliseconds: 100));

    // Header uses RichText with separate "Since" + "Then" spans
    expect(find.byWidgetPredicate((w) =>
        w is RichText &&
        w.text is TextSpan &&
        (w.text as TextSpan).children != null &&
        (w.text as TextSpan).children!.any(
            (s) => s is TextSpan && s.text == 'Since') &&
        (w.text as TextSpan).children!.any(
            (s) => s is TextSpan && s.text == 'Then')), findsOneWidget);
    expect(find.byType(SvgPicture), findsWidgets);
    expect(find.byType(AppBar), findsOneWidget);

    // Verify all 4 navigation destinations exist
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Recap'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Dispose widget and flush Drift's pending zero-duration timers
    await flushDriftTimers(tester);
  }, tags: ['integration']);
}
