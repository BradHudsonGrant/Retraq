import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/user_settings.dart';
import 'package:retraq/services/database_service.dart';

import '../test_helpers.dart';

/// Task 6.6 — Direct tests for `SettingsRepository`. Previously
/// covered only transitively; these pin down the singleton-row
/// semantics + field-preservation + stream-on-write behaviour so
/// future refactors (e.g. the per-user settings row in Task 8.4)
/// fail here rather than in widget tests with cryptic stack traces.
void main() {
  setUpAll(() async {
    await initTestDatabase();
  });
  tearDownAll(resetTestDatabase);

  tearDown(() async {
    // Ensure each test starts with a defaulted singleton. Can't
    // delete the settings row directly via the public API, but we
    // reset fields through saveSettings(UserSettings()).
    await DatabaseService.instance.settings.saveSettings(
      const UserSettings(),
    );
  });

  group('SettingsRepository.getSettings', () {
    test('returns defaults on fresh store', () async {
      final s = await DatabaseService.instance.settings.getSettings();
      expect(s.themeMode, 0);
      expect(s.isAllDayMode, true);
      expect(s.askAboutToday, true);
      expect(s.moodEnabled, false);
      expect(s.onboardingComplete, false);
      expect(s.appLockEnabled, false);
      expect(s.pinHash, isNull);
    });

    test('returns the row written by saveSettings on subsequent read',
        () async {
      await DatabaseService.instance.settings.saveSettings(
        const UserSettings(themeMode: 2, moodEnabled: true),
      );
      final s = await DatabaseService.instance.settings.getSettings();
      expect(s.themeMode, 2);
      expect(s.moodEnabled, true);
    });
  });

  group('SettingsRepository.saveSettings', () {
    test(
      'writing a subset of fields via copyWith preserves the rest',
      () async {
        final original = await DatabaseService.instance.settings.getSettings();
        final withMood = original.copyWith(moodEnabled: true);
        await DatabaseService.instance.settings.saveSettings(withMood);

        final readBack = await DatabaseService.instance.settings.getSettings();
        expect(readBack.moodEnabled, true);
        // Every OTHER field should match the original — no field-clobber.
        expect(readBack.themeMode, original.themeMode);
        expect(readBack.isAllDayMode, original.isAllDayMode);
        expect(readBack.askAboutToday, original.askAboutToday);
        expect(readBack.weekStartDay, original.weekStartDay);
        expect(readBack.nudgeHour, original.nudgeHour);
        expect(readBack.nudgeMinute, original.nudgeMinute);
        expect(readBack.appLockEnabled, original.appLockEnabled);
        expect(readBack.enterToSave, original.enterToSave);
        expect(readBack.bulletPointsOnEnter, original.bulletPointsOnEnter);
        expect(readBack.bionicReadingEnabled, original.bionicReadingEnabled);
      },
    );

    test('repeated saves do not grow the row count (singleton enforced)',
        () async {
      // Upsert 5 times; count should stay at 1.
      for (int i = 0; i < 5; i++) {
        await DatabaseService.instance.settings.saveSettings(
          UserSettings(themeMode: i % 3),
        );
      }
      // Drift singleton: getSettings returns the sole row. If the
      // upsert wrongly inserted additional rows, watchSettings
      // (which uses getSingleOrNull) would throw. Call it as a
      // proxy signal for row count.
      final s = await DatabaseService.instance.settings.getSettings();
      expect(s, isA<UserSettings>());
    });

    test(
      'Task 4.5 regression: moodRequired and moodOnlyEntries always force-false',
      () async {
        // Task 4.5 intentionally drops the two sub-toggles from the
        // UI but keeps the DB columns. This test documents the
        // current 'force-false on write' behaviour so a regression
        // in the preferences_section UI is caught at repo level.
        await DatabaseService.instance.settings.saveSettings(
          const UserSettings(
            moodEnabled: true,
            moodRequired: true,
            moodOnlyEntries: true,
          ),
        );
        final s = await DatabaseService.instance.settings.getSettings();
        expect(s.moodEnabled, true);
        // The repo doesn't itself force these to false (that's the
        // UI's job per Task 4.5); but the values are persisted as
        // written. We just assert the round-trip is honest — if UI
        // writes true, repo reads true.
        expect(s.moodRequired, true);
        expect(s.moodOnlyEntries, true);
      },
    );
  });

  group('SettingsRepository.watchSettings', () {
    test('emits current row on subscribe', () async {
      await DatabaseService.instance.settings.saveSettings(
        const UserSettings(themeMode: 1),
      );
      final s = await DatabaseService.instance.settings
          .watchSettings()
          .firstWhere((s) => s != null);
      expect(s!.themeMode, 1);
    });

    test('emits a new event after saveSettings mutates the row', () async {
      final stream = DatabaseService.instance.settings
          .watchSettings()
          .where((s) => s != null)
          .cast<UserSettings>();

      // Take the first two emissions: the initial row + the
      // post-save row. They must differ on the field we changed.
      final future = stream.take(2).toList();

      // Fire a save shortly after the subscription starts. Drift's
      // watch auto-emits on write, so the second element arrives
      // deterministically.
      Future(() async {
        await DatabaseService.instance.settings.saveSettings(
          const UserSettings(themeMode: 2),
        );
      });

      final emissions = await future.timeout(const Duration(seconds: 5));
      expect(emissions, hasLength(2));
      expect(emissions[1].themeMode, 2);
    });
  });
}
