@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/l10n/app_localizations.dart';
import 'package:retraq/screens/app_shell.dart';

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
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    home: AppShell(
      onThemeModeChanged: (_) async {},
      themeMode: ThemeMode.system,
    ),
  );

  testWidgets('AppShell renders four navigation tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapShell());
    await tester.pump(const Duration(milliseconds: 100));

    // Shell intentionally has NO top AppBar — each screen owns its own
    // header for max real-estate. Just verify the nav bar and the four
    // tab labels are present.
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify all 4 navigation destinations exist
    expect(find.text('Jot'), findsOneWidget);
    expect(find.text('Recap'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Dispose widget and flush Drift's pending zero-duration timers
    await flushDriftTimers(tester);
  }, tags: ['integration']);
}
