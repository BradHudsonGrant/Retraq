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

  testWidgets('AppShell renders three navigation tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapShell());
    await tester.pump(const Duration(milliseconds: 100));

    // Shell intentionally has NO top AppBar — each screen owns its own
    // header for max real-estate. Just verify the nav bar and the three
    // tab labels are present. Stats was collapsed into the Recap tab as
    // an embedded Insights pane and the Jot label was renamed
    // to Traq to match the rest of the product copy.
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify the 3 navigation destinations exist. "Traq" now also
    // appears inside the Home screen body (hero copy uses the brand
    // term), so scope the tab-label lookup to the NavigationBar itself
    // via a descendant finder — otherwise findsOneWidget trips on the
    // body text that lives outside the nav.
    Finder inNav(String label) => find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        );
    expect(inNav('Traq'), findsOneWidget);
    // navRecap l10n string is 'Retraq' (brand term), not 'Recap'.
    expect(inNav('Retraq'), findsOneWidget);
    expect(inNav('Settings'), findsOneWidget);

    // Dispose widget and flush Drift's pending zero-duration timers
    await flushDriftTimers(tester);
  }, tags: ['integration']);
}
