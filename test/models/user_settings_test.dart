import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/user_settings.dart';

void main() {
  group('UserSettings.copyWith', () {
    test('every field is settable', () {
      // Guards against adding a field to the class but forgetting to
      // thread it through copyWith. A field that copyWith silently drops
      // would cause hard-to-debug "my new setting resets on save" bugs.
      const s = UserSettings();
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

    test('pinHash can be set, preserved when omitted, and cleared with null', () {
      // pinHash has surprising semantics: omitting it should preserve
      // the original; passing null should clear it. This is the common
      // copyWith pitfall (sentinel vs. null) and the reason a PIN reset
      // flow can silently leave the old hash behind.
      const original = UserSettings(pinHash: 'v2:salt:hash');
      expect(original.pinHash, 'v2:salt:hash');

      final themeChanged = original.copyWith(themeMode: 2);
      expect(themeChanged.pinHash, 'v2:salt:hash',
          reason: 'omitting pinHash must preserve the original value');

      final cleared = original.copyWith(pinHash: null);
      expect(cleared.pinHash, isNull,
          reason: 'explicit null must clear the hash');
    });
  });
}
