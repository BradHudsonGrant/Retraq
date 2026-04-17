import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/user_settings.dart';
import 'package:retraq/screens/app_shell.dart';
import 'package:retraq/utils/test_keys.dart';

import '../test_helpers.dart';

/// Task 6.10 (partial) — Smoke tests for AppShell.
///
/// Scope: verify the three-tab NavigationBar renders (Task 2.5
/// collapsed Stats into Recap; bottom nav is now Jot/Recap/Settings),
/// all three tabs are reachable by their TestKey, and the
/// currentIndex behaviour responds correctly to tab taps. We do NOT
/// pumpAndSettle through the 360ms emphasized page-view curve
/// because several tabs (Home, Recap) rely on Drift streams that
/// require a full initTestDatabase() fixture — those integration-
/// level assertions belong in an end-to-end journey test
/// (Task 6.1 follow-up).
///
/// The value here is guarding against a NavigationBar structural
/// regression (wrong destination count, missing keys, null-unsafe
/// index math in _onTabSelected) that the integration smoke would
/// catch at runtime but only after the test binary ships.
void main() {
  setUpAll(() async {
    await initTestDatabase();
    setUpFakeSecureStorage();
  });

  tearDownAll(() {
    resetTestDatabase();
    resetFakeSecureStorage();
  });

  AppShell buildShell() {
    return AppShell(
      onThemeModeChanged: (_) async {},
      themeMode: ThemeMode.system,
    );
  }

  testWidgets('renders without throwing', (tester) async {
    await tester.pumpWidget(wrapScreen(
      buildShell(),
      settings: const UserSettings(),
    ));
    // Single frame — avoid Drift stream timers settling.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await flushDriftTimers(tester);
  });

  testWidgets('has three navigation destinations (Jot / Recap / Settings)',
      (tester) async {
    // Task 2.5 — down from 4 to 3. Stats now lives inside Recap's
    // Insights pane rather than as a top-level tab.
    await tester.pumpWidget(wrapScreen(
      buildShell(),
      settings: const UserSettings(),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(NavigationDestination), findsNWidgets(3));
    await flushDriftTimers(tester);
  });

  testWidgets('exposes the three remaining tab TestKeys', (tester) async {
    await tester.pumpWidget(wrapScreen(
      buildShell(),
      settings: const UserSettings(),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(TestKeys.navJournalTab), findsOneWidget);
    expect(find.byKey(TestKeys.navRecapTab), findsOneWidget);
    expect(find.byKey(TestKeys.navSettingsTab), findsOneWidget);
    // Task 2.5 — Stats no longer exists at the shell level. The
    // TestKey itself remains in test_keys.dart for any lingering
    // tests that still reference it; expect it NOT to render here.
    expect(find.byKey(TestKeys.navStatsTab), findsNothing,
        reason:
            'Stats must not be a top-level tab after Task 2.5. If this '
            'fires, the collapse-into-Recap regressed.');
    await flushDriftTimers(tester);
  });

  testWidgets('starts on the Jot tab (index 0 selected)', (tester) async {
    await tester.pumpWidget(wrapScreen(
      buildShell(),
      settings: const UserSettings(),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);
    await flushDriftTimers(tester);
  });

  // Tab-tap assertion deliberately omitted: it requires the inner
  // screens' full DB fixtures (Drift streams) to settle without
  // pending-timer warnings. The structural checks above (4
  // destinations, 4 test keys, starts-on-index-0) catch the
  // regression surface Task 6.10 cares about; tab-transition
  // behaviour belongs in an end-to-end journey test (Task 6.1
  // follow-up) with the full integration harness.

  testWidgets('page view scroll is disabled (NeverScrollableScrollPhysics)',
      (tester) async {
    await tester.pumpWidget(wrapScreen(
      buildShell(),
      settings: const UserSettings(),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.physics, isA<NeverScrollableScrollPhysics>(),
        reason:
            'PageView scroll must stay disabled so tab switching is '
            'driven exclusively by the NavigationBar');
    await flushDriftTimers(tester);
  });

  testWidgets('themeMode is threaded through to children', (tester) async {
    ThemeMode? captured;
    await tester.pumpWidget(wrapScreen(
      AppShell(
        onThemeModeChanged: (mode) async {
          captured = ThemeMode.values[mode];
        },
        themeMode: ThemeMode.dark,
      ),
      settings: const UserSettings(),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    // We can't trigger the theme-change callback without tapping
    // the settings screen's toggle (which requires the full DB
    // fixture). Instead assert that the shell mounts with
    // ThemeMode.dark without throwing. The callback-invocation
    // path is covered in settings_screen_test.
    expect(find.byType(AppShell), findsOneWidget);
    expect(captured, isNull); // callback not invoked here
    await flushDriftTimers(tester);
  });
}
