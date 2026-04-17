// ignore_for_file: prefer_single_quotes

import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/screens/home/home_form_controller.dart';

/// Task 1.2 — direct tests for HomeFormController.
///
/// These cover behaviours previously untestable because the data
/// lived as scattered bare fields inside home_screen.dart State. Now
/// each property update (mood, date override, last-saved id) has
/// predictable notify semantics and can be asserted without booting
/// a widget tree.
void main() {
  group('HomeFormController — defaults', () {
    test('fresh instance has empty text + null mood + null date', () {
      final form = HomeFormController();
      addTearDown(form.dispose);

      expect(form.titleCtrl.text, '');
      expect(form.entryCtrl.text, '');
      expect(form.mood, isNull);
      expect(form.dateOverride, isNull);
      expect(form.lastSavedEntryId, isNull);
    });

    test('entryDate defaults to today when no override', () {
      final form = HomeFormController();
      addTearDown(form.dispose);

      final now = DateTime.now();
      final expected = DateTime(now.year, now.month, now.day);
      expect(form.entryDate, expected);
    });

    test('entryDate returns the override when set', () {
      final form = HomeFormController();
      addTearDown(form.dispose);

      final pick = DateTime(2025, 1, 15);
      form.setDateOverride(pick);
      expect(form.entryDate, pick);
    });
  });

  group('HomeFormController — setMood', () {
    test('notifies on value change', () {
      final form = HomeFormController();
      addTearDown(form.dispose);
      var notifyCount = 0;
      form.addListener(() => notifyCount += 1);

      form.setMood(3);
      expect(form.mood, 3);
      expect(notifyCount, 1);
    });

    test('does NOT notify when value unchanged', () {
      final form = HomeFormController();
      addTearDown(form.dispose);
      form.setMood(2);
      var notifyCount = 0;
      form.addListener(() => notifyCount += 1);

      form.setMood(2);
      expect(notifyCount, 0,
          reason:
              'setMood with the same value must not fire notifyListeners — '
              'would cause a redundant screen rebuild on every mood blob '
              'repaint that re-invokes the callback.');
    });

    test('null is a valid mood (deselects)', () {
      final form = HomeFormController();
      addTearDown(form.dispose);
      form.setMood(4);
      expect(form.mood, 4);

      form.setMood(null);
      expect(form.mood, isNull);
    });
  });

  group('HomeFormController — setDateOverride', () {
    test('notifies on change + preserves value', () {
      final form = HomeFormController();
      addTearDown(form.dispose);
      var notifyCount = 0;
      form.addListener(() => notifyCount += 1);

      final pick = DateTime(2025, 6, 1);
      form.setDateOverride(pick);
      expect(form.dateOverride, pick);
      expect(notifyCount, 1);

      // Setting to null returns to "today" path.
      form.setDateOverride(null);
      expect(form.dateOverride, isNull);
      expect(notifyCount, 2);
    });
  });

  group('HomeFormController — setLastSavedEntryId', () {
    test('tracks id for the save-success overlay', () {
      final form = HomeFormController();
      addTearDown(form.dispose);
      form.setLastSavedEntryId(42);
      expect(form.lastSavedEntryId, 42);
      form.setLastSavedEntryId(null);
      expect(form.lastSavedEntryId, isNull);
    });
  });

  group('HomeFormController — clearDraft', () {
    test('resets text, mood, date but NOT lastSavedEntryId', () {
      final form = HomeFormController();
      addTearDown(form.dispose);

      form.titleCtrl.text = 'Morning';
      form.entryCtrl.text = 'Some entry text';
      form.setMood(5);
      form.setDateOverride(DateTime(2025, 3, 15));
      form.setLastSavedEntryId(99);

      form.clearDraft();

      expect(form.titleCtrl.text, '');
      expect(form.entryCtrl.text, '');
      expect(form.mood, isNull);
      expect(form.dateOverride, isNull);
      expect(form.lastSavedEntryId, 99,
          reason:
              'clearDraft must NOT null lastSavedEntryId — the save-'
              'success overlay is still mid-animation when the draft '
              'is cleared; it needs the id to deep-link on tap.');
    });

    test('notifies once on non-empty clear', () {
      final form = HomeFormController();
      addTearDown(form.dispose);
      form.setMood(3);
      var notifyCount = 0;
      form.addListener(() => notifyCount += 1);

      form.clearDraft();
      expect(notifyCount, 1);
    });

    test('does NOT notify when called on an already-empty draft', () {
      final form = HomeFormController();
      addTearDown(form.dispose);
      var notifyCount = 0;
      form.addListener(() => notifyCount += 1);

      form.clearDraft();
      expect(notifyCount, 0);
    });
  });

  group('HomeFormController — validate', () {
    String trimClean(String raw) => raw.trim();

    test('empty text + no mood → missingText', () {
      final form = HomeFormController();
      addTearDown(form.dispose);

      final result = form.validate(
        textCleaner: trimClean,
        moodEnabled: false,
        moodRequired: false,
        moodOnlyEntries: false,
      );
      expect(result, HomeFormValidation.missingText);
    });

    test('empty text + mood selected + moodOnlyEntries=false → missingText',
        () {
      final form = HomeFormController();
      addTearDown(form.dispose);
      form.setMood(4);

      final result = form.validate(
        textCleaner: trimClean,
        moodEnabled: true,
        moodRequired: false,
        moodOnlyEntries: false,
      );
      // Without moodOnlyEntries, text is still required.
      expect(result, HomeFormValidation.missingText);
    });

    test('empty text + mood selected + moodOnlyEntries=true → ok', () {
      final form = HomeFormController();
      addTearDown(form.dispose);
      form.setMood(4);

      final result = form.validate(
        textCleaner: trimClean,
        moodEnabled: true,
        moodRequired: false,
        moodOnlyEntries: true,
      );
      expect(result, HomeFormValidation.ok);
    });

    test('text present + no mood + moodRequired=true → missingMood', () {
      final form = HomeFormController();
      addTearDown(form.dispose);
      form.entryCtrl.text = 'A quick traq.';

      final result = form.validate(
        textCleaner: trimClean,
        moodEnabled: true,
        moodRequired: true,
        moodOnlyEntries: false,
      );
      expect(result, HomeFormValidation.missingMood);
    });

    test('text present + no mood + moodRequired=false → ok', () {
      final form = HomeFormController();
      addTearDown(form.dispose);
      form.entryCtrl.text = 'A quick traq.';

      final result = form.validate(
        textCleaner: trimClean,
        moodEnabled: true,
        moodRequired: false,
        moodOnlyEntries: false,
      );
      expect(result, HomeFormValidation.ok);
    });

    test('text present + mood selected + everything enabled → ok', () {
      final form = HomeFormController();
      addTearDown(form.dispose);
      form.entryCtrl.text = 'A quick traq.';
      form.setMood(3);

      final result = form.validate(
        textCleaner: trimClean,
        moodEnabled: true,
        moodRequired: true,
        moodOnlyEntries: true,
      );
      expect(result, HomeFormValidation.ok);
    });

    test('textCleaner is honoured (whitespace-only fails as missingText)',
        () {
      // Pin that a text-only "   \n\n" draft does NOT count as text.
      // Whole point of the injected cleaner is the screen's
      // _cleanText which strips trailing blank lines; the controller
      // must respect whatever cleaner the screen passes in.
      final form = HomeFormController();
      addTearDown(form.dispose);
      form.entryCtrl.text = '   \n\n';

      final result = form.validate(
        textCleaner: trimClean,
        moodEnabled: false,
        moodRequired: false,
        moodOnlyEntries: false,
      );
      expect(result, HomeFormValidation.missingText,
          reason:
              'A draft that becomes empty after cleaning must fail '
              'validation — otherwise users hit Save on a whitespace-'
              'only entry and get a silent DB insert of nothing.');
    });
  });

  group('HomeFormController — dispose', () {
    test('dispose disposes both text controllers', () {
      final form = HomeFormController();
      form.dispose();

      // TextEditingController.text throws after dispose.
      expect(
        () => form.titleCtrl.text = 'x',
        throwsFlutterError,
        reason: 'titleCtrl must be disposed by HomeFormController.dispose',
      );
    });
  });
}
