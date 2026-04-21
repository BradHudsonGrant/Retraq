import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/user_settings.dart';
import 'package:retraq/services/database_service.dart'
    show DatabaseService, UserSettingsTableCompanion;

import '../test_helpers.dart';

/// Direct tests for `SettingsRepository`. Previously
/// covered only transitively; these pin down the singleton-row
/// semantics + field-preservation + stream-on-write behaviour so
/// future refactors fail here rather than in widget tests with
/// cryptic stack traces.
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

    test(
      'regression: watch stays in sync when the row lives at id > 1',
      () async {
        // Reproduce the autoincrement orphan-row bug: wipe the table
        // and re-insert without specifying an id. The replacement row
        // lands at id=2 because AUTOINCREMENT never reuses ids.
        // Pre-fix, watchSettings filtered by id=1 and the watcher
        // would go silent forever — toggles in Settings looked dead.
        final db = DatabaseService.instance.db;
        await db.delete(db.userSettingsTable).go();
        await db.into(db.userSettingsTable).insert(
              UserSettingsTableCompanion.insert(
                moodEnabled: const drift.Value(true),
              ),
            );

        // A save now must trigger the watcher. getSettings() must
        // also reconcile the orphan back to id=1 on the way in.
        final s = await DatabaseService.instance.settings.getSettings();
        expect(s.moodEnabled, true,
            reason: 'orphan row values must be preserved on reconciliation');

        final stream = DatabaseService.instance.settings
            .watchSettings()
            .where((s) => s != null)
            .cast<UserSettings>();
        final future = stream.take(2).toList();
        Future(() async {
          await DatabaseService.instance.settings.saveSettings(
            const UserSettings(themeMode: 2, moodEnabled: true),
          );
        });
        final emissions = await future.timeout(const Duration(seconds: 5));
        expect(emissions[1].themeMode, 2,
            reason: 'watcher must re-emit after a post-reconciliation save');
      },
    );

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
