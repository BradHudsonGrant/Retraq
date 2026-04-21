@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/user_settings.dart';
import 'package:retraq/screens/settings_screen.dart';
import 'package:retraq/widgets/molecules/settings_row.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  group('SettingsScreen', () {
    testWidgets('renders Appearance section', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SettingsScreen(
            onThemeModeChanged: (_) async {},
            themeMode: ThemeMode.system,
          ),
          settings: UserSettings(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Choose how Retraq feels to you.'), findsOneWidget);
      await flushDriftTimers(tester);
    });

    testWidgets('renders System, Day and Night theme cards', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SettingsScreen(
            onThemeModeChanged: (_) async {},
            themeMode: ThemeMode.system,
          ),
          settings: UserSettings(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('System'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Night'), findsOneWidget);
      await flushDriftTimers(tester);
    });

    testWidgets('renders Preferences section', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SettingsScreen(
            onThemeModeChanged: (_) async {},
            themeMode: ThemeMode.system,
          ),
          settings: UserSettings(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('All Day Notes'), findsOneWidget);
      expect(find.text('Opening Prompt'), findsOneWidget);
      expect(find.text('Traq Title'), findsOneWidget);
      // Advanced settings are collapsed by default
      expect(find.text('Advanced'), findsOneWidget);
      await flushDriftTimers(tester);
    });

    testWidgets('renders Security section', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SettingsScreen(
            onThemeModeChanged: (_) async {},
            themeMode: ThemeMode.system,
          ),
          settings: UserSettings(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Security'), findsOneWidget);
      expect(find.text('App Lock'), findsOneWidget);
      await flushDriftTimers(tester);
    });

    testWidgets('renders Nudge card', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SettingsScreen(
            onThemeModeChanged: (_) async {},
            themeMode: ThemeMode.system,
          ),
          settings: UserSettings(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('nudge'), findsOneWidget);
      expect(find.text('Change Time'), findsOneWidget);
      await flushDriftTimers(tester);
    });

    testWidgets('renders Your Data section', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SettingsScreen(
            onThemeModeChanged: (_) async {},
            themeMode: ThemeMode.system,
          ),
          settings: UserSettings(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Your Data is a collapsed ExpansionTile — scroll to it first
      await tester.scrollUntilVisible(
        find.text('Your Data'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Your Data'), findsOneWidget);
      // Export buttons hidden until expanded
      expect(find.text('Export JSON'), findsNothing);

      // Expand the section
      await tester.tap(find.text('Your Data'));
      await tester.pumpAndSettle();

      expect(find.text('Export JSON'), findsOneWidget);
      expect(find.text('Export Text'), findsOneWidget);
      await flushDriftTimers(tester);
    });

    testWidgets('renders version and privacy link', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SettingsScreen(
            onThemeModeChanged: (_) async {},
            themeMode: ThemeMode.system,
          ),
          settings: UserSettings(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Retraq v0.9.0'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      await flushDriftTimers(tester);
    });

    testWidgets('has correct number of visible SettingsRow widgets', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(
          SettingsScreen(
            onThemeModeChanged: (_) async {},
            themeMode: ThemeMode.system,
          ),
          settings: UserSettings(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Visible: All Day Notes, Opening Prompt, Journal Entry Title, Mood Tracking, App Lock = 5
      // Hidden in collapsed Advanced: Bionic Reading, Enter to Save, Bullet Points, Week Starts On
      expect(find.byType(SettingsRow), findsNWidgets(5));
      await flushDriftTimers(tester);
    });

    testWidgets('theme toggle callback fires', (tester) async {
      int? selectedMode;
      await tester.pumpWidget(
        wrapWidget(
          SettingsScreen(
            onThemeModeChanged: (v) async => selectedMode = v,
            themeMode: ThemeMode.system,
          ),
          settings: UserSettings(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap "Night" theme card
      await tester.tap(find.text('Night'));
      await tester.pump();

      expect(selectedMode, 2);
      await flushDriftTimers(tester);
    });

    testWidgets('shows check on selected theme card', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SettingsScreen(
            onThemeModeChanged: (_) async {},
            themeMode: ThemeMode.system,
          ),
          settings: UserSettings(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // System is selected, should show check_circle
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await flushDriftTimers(tester);
    });
  });
}
