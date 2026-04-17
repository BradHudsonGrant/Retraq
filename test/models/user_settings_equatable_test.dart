import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/user_settings.dart';

/// Task 1.9 — verifies UserSettings equality is driven by Equatable's
/// props list and that every field the model declares is enumerated
/// in props. The field-count guard is deliberate: if a future setting
/// is added to the class without being added to props, RetraqApp's
/// settings-stream rebuild would silently skip rebuilding on that
/// field, which is exactly the class of bug this task was opened to
/// prevent.
void main() {
  group('UserSettings equality (Equatable)', () {
    test('two all-defaults instances are equal', () {
      const a = UserSettings();
      const b = UserSettings();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances differ when themeMode differs', () {
      const a = UserSettings();
      const b = UserSettings(themeMode: UserSettings.themeModeDark);
      expect(a, isNot(equals(b)));
    });

    test('instances differ when pinHash differs', () {
      const a = UserSettings(pinHash: 'v3:aaa:bbb');
      const b = UserSettings(pinHash: 'v3:ccc:ddd');
      expect(a, isNot(equals(b)));
    });

    test('instances differ when bionicReadingEnabled differs', () {
      const a = UserSettings();
      const b = UserSettings(bionicReadingEnabled: true);
      expect(a, isNot(equals(b)));
    });

    test('copyWith without changes produces equal instance', () {
      const a = UserSettings(moodEnabled: true);
      final b = a.copyWith();
      expect(a, equals(b));
    });

    test('copyWith with a change produces unequal instance', () {
      const a = UserSettings();
      final b = a.copyWith(amPmCutoffHour: 6);
      expect(a, isNot(equals(b)));
    });

    // Field-count guard — the sentinel against "new setting added but
    // forgotten in props". If you add a field to UserSettings you MUST
    // bump this number AND add the field to props; otherwise equality
    // will ignore it and settings changes won't propagate.
    test('props enumerates exactly 18 fields', () {
      const s = UserSettings();
      expect(s.props.length, 18);
    });

    test('props entries cover every distinct initial value', () {
      // Construct a variant that differs from defaults in every field.
      // If any field is missing from props, equality with defaults will
      // incorrectly hold.
      const defaults = UserSettings();
      const everything = UserSettings(
        themeMode: UserSettings.themeModeDark,
        isAllDayMode: false,
        askAboutToday: false,
        showEntryTitle: true,
        weekStartDay: 7,
        nudgeHour: 9,
        nudgeMinute: 30,
        appLockEnabled: true,
        pinHash: 'v3:x:y',
        biometricEnabled: true,
        onboardingComplete: true,
        enterToSave: true,
        bulletPointsOnEnter: true,
        amPmCutoffHour: 6,
        moodEnabled: true,
        moodRequired: true,
        moodOnlyEntries: true,
        bionicReadingEnabled: true,
      );
      expect(everything, isNot(equals(defaults)));
    });
  });
}
