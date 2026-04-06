import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/user_settings.dart';

void main() {
  group('UserSettings', () {
    test('default values are correct', () {
      final s = UserSettings();

      expect(s.themeMode, 0); // system
      expect(s.isAllDayMode, true);
      expect(s.askAboutToday, true);
      expect(s.showEntryTitle, false);
      expect(s.weekStartDay, 1);
      expect(s.nudgeHour, 20);
      expect(s.appLockEnabled, false);
      expect(s.pinHash, isNull);
      expect(s.biometricEnabled, false);
      expect(s.onboardingComplete, false);
    });

    test('constructor accepts custom values', () {
      final s = UserSettings(
        themeMode: 2,
        isAllDayMode: false,
        askAboutToday: false,
        showEntryTitle: true,
        weekStartDay: 7,
        nudgeHour: 9,
        appLockEnabled: true,
        pinHash: 'salt:hash',
        biometricEnabled: true,
        onboardingComplete: true,
      );

      expect(s.themeMode, 2);
      expect(s.isAllDayMode, false);
      expect(s.askAboutToday, false);
      expect(s.showEntryTitle, true);
      expect(s.weekStartDay, 7);
      expect(s.nudgeHour, 9);
      expect(s.appLockEnabled, true);
      expect(s.pinHash, 'salt:hash');
      expect(s.biometricEnabled, true);
      expect(s.onboardingComplete, true);
    });

    test('all fields are settable via copyWith', () {
      final s = UserSettings();

      final updated = s.copyWith(
        themeMode: 2,
        isAllDayMode: false,
        askAboutToday: false,
        showEntryTitle: true,
        weekStartDay: 7,
        nudgeHour: 6,
        appLockEnabled: true,
        pinHash: 'test:hash',
        biometricEnabled: true,
        onboardingComplete: true,
      );

      expect(updated.themeMode, 2);
      expect(updated.isAllDayMode, false);
      expect(updated.askAboutToday, false);
      expect(updated.showEntryTitle, true);
      expect(updated.weekStartDay, 7);
      expect(updated.nudgeHour, 6);
      expect(updated.appLockEnabled, true);
      expect(updated.pinHash, 'test:hash');
      expect(updated.biometricEnabled, true);
      expect(updated.onboardingComplete, true);
    });

    test('themeMode constants are correct', () {
      expect(UserSettings.themeModeSystem, 0);
      expect(UserSettings.themeModeLight, 1);
      expect(UserSettings.themeModeDark, 2);
    });

    test('weekStartDay accepts Monday (1) and Sunday (7)', () {
      final monday = UserSettings(weekStartDay: 1);
      final sunday = UserSettings(weekStartDay: 7);

      expect(monday.weekStartDay, 1);
      expect(sunday.weekStartDay, 7);
    });

    test('pinHash can be set and cleared via copyWith', () {
      final s = UserSettings();
      expect(s.pinHash, isNull);

      final withHash = s.copyWith(pinHash: 'abc123:deadbeef');
      expect(withHash.pinHash, 'abc123:deadbeef');

      final cleared = withHash.copyWith(pinHash: null);
      expect(cleared.pinHash, isNull);
    });
  });

  group('UserSettings.copyWith', () {
    test('returns a new instance with same values when no args', () {
      final original = UserSettings(
        themeMode: 2,
        isAllDayMode: false,
        weekStartDay: 7,
        nudgeHour: 9,
        pinHash: 'v2:salt:hash',
        amPmCutoffHour: 16,
      );
      final copy = original.copyWith();

      expect(copy.themeMode, 2);
      expect(copy.isAllDayMode, false);
      expect(copy.weekStartDay, 7);
      expect(copy.nudgeHour, 9);
      expect(copy.pinHash, 'v2:salt:hash');
      expect(copy.amPmCutoffHour, 16);
    });

    test('overrides only specified fields', () {
      final original = UserSettings(themeMode: 0, weekStartDay: 1);
      final copy = original.copyWith(themeMode: 2, weekStartDay: 7);

      expect(copy.themeMode, 2);
      expect(copy.weekStartDay, 7);
      // Unmodified fields retain defaults
      expect(copy.isAllDayMode, true);
      expect(copy.nudgeHour, 20);
    });

    test('can set pinHash to null explicitly', () {
      final original = UserSettings(pinHash: 'v2:salt:hash');
      expect(original.pinHash, isNotNull);

      final copy = original.copyWith(pinHash: null);
      expect(copy.pinHash, isNull);
    });

    test('omitting pinHash preserves original value', () {
      final original = UserSettings(pinHash: 'v2:salt:hash');
      final copy = original.copyWith(themeMode: 2);
      expect(copy.pinHash, 'v2:salt:hash');
    });

    test('copy is independent from original', () {
      final original = UserSettings(themeMode: 0);
      final copy = original.copyWith(themeMode: 2);

      expect(copy.themeMode, 2);
      expect(original.themeMode, 0);
    });

    test('copies all boolean fields correctly', () {
      final original = UserSettings(
        askAboutToday: false,
        showEntryTitle: true,
        appLockEnabled: true,
        biometricEnabled: true,
        onboardingComplete: true,
        enterToSave: true,
        bulletPointsOnEnter: true,
      );
      final copy = original.copyWith();

      expect(copy.askAboutToday, false);
      expect(copy.showEntryTitle, true);
      expect(copy.appLockEnabled, true);
      expect(copy.biometricEnabled, true);
      expect(copy.onboardingComplete, true);
      expect(copy.enterToSave, true);
      expect(copy.bulletPointsOnEnter, true);
    });
  });
}
