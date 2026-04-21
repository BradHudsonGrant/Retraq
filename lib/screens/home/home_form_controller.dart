import 'package:flutter/widgets.dart';

import '../../utils/date_helpers.dart';

/// Result of validating a draft. Used by [HomeFormController.validate]
/// so the screen knows whether to proceed with save, or which SnackBar
/// copy to surface.
enum HomeFormValidation {
  /// Draft is savable — has non-empty text.
  ok,

  /// Draft is empty. Surface `writeSomethingFirst`.
  missingText,
}

/// Form-state holder for the Home (Jot) screen's entry draft.
///
/// Owns the TextEditingControllers plus the mood + date-override +
/// last-saved-id values that the screen previously held in a
/// scattered set of bare fields. Save orchestration itself stays on
/// the screen for now (it's coupled to too many side-effect
/// services — notifications, widget, review prompt — to lift in one
/// step without breaking the UX timing).
///
/// Rationale for pulling these five things together:
/// - They all represent the "current draft" the user is composing
/// - They all need to be clear()ed together after a save completes
///   or a date override is reset
/// - They need to be dispose()d together on screen teardown
///
/// The ChangeNotifier surface is minimal — callers update via the
/// public setters, which handle `notifyListeners` internally. The
/// screen attaches a listener in `initState` and calls `setState`
/// inside it so the existing widget-rebuild loop is preserved.
class HomeFormController extends ChangeNotifier {
  HomeFormController()
      : titleCtrl = TextEditingController(),
        entryCtrl = TextEditingController();

  /// Title input controller. The text itself is not part of the
  /// ChangeNotifier's notification surface — widgets that rebuild on
  /// text changes should listen to the controller directly.
  final TextEditingController titleCtrl;

  /// Main body-text input controller. Same listen-directly pattern
  /// as `titleCtrl`.
  final TextEditingController entryCtrl;

  int? _mood;
  DateTime? _dateOverride;
  int? _lastSavedEntryId;

  /// Selected mood value (1..5) or null when unset.
  int? get mood => _mood;

  /// User-picked date-override, or null when saving for today.
  DateTime? get dateOverride => _dateOverride;

  /// Row ID of the most recently saved entry; used by the screen to
  /// surface the save-success overlay (tap → opens the new entry).
  int? get lastSavedEntryId => _lastSavedEntryId;

  /// Effective save date — the override if set, else today at
  /// midnight local.
  DateTime get entryDate {
    if (_dateOverride != null) return _dateOverride!;
    return dateOnly(DateTime.now());
  }

  /// Update the mood. Tapping the same mood twice deselects (null)
  /// — that's the screen's existing behaviour, preserved here by
  /// accepting `null` as a valid value.
  void setMood(int? value) {
    if (_mood == value) return;
    _mood = value;
    notifyListeners();
  }

  /// Set or clear the date override. Pass null to return to "today".
  void setDateOverride(DateTime? value) {
    if (_dateOverride == value) return;
    _dateOverride = value;
    notifyListeners();
  }

  /// Record the id of the most recently saved entry. Called after
  /// `saveEntry()` succeeds so the save-success overlay can deep-
  /// link to it.
  void setLastSavedEntryId(int? id) {
    if (_lastSavedEntryId == id) return;
    _lastSavedEntryId = id;
    notifyListeners();
  }

  /// Reset the entire draft to empty: clear text, mood, date
  /// override. Does NOT clear `lastSavedEntryId` — that's still
  /// needed by the overlay which is mid-animation when this is
  /// typically called. Callers (e.g. the overlay-dismiss callback)
  /// explicitly null that separately if they want.
  void clearDraft() {
    final changed = titleCtrl.text.isNotEmpty ||
        entryCtrl.text.isNotEmpty ||
        _mood != null ||
        _dateOverride != null;
    titleCtrl.clear();
    entryCtrl.clear();
    _mood = null;
    _dateOverride = null;
    if (changed) notifyListeners();
  }

  /// Validate the current draft.
  ///
  /// [textCleaner] is injected because the canonical "cleaned" entry
  /// text (trimmed + stripped of trailing whitespace lines) is a
  /// screen-level concern — see `_cleanText` in home_screen.dart.
  /// Passing it in keeps the controller independent of that helper
  /// while still honouring the same empty-text rule.
  HomeFormValidation validate({
    required String Function(String) textCleaner,
  }) {
    final hasText = textCleaner(entryCtrl.text).isNotEmpty;
    if (!hasText) return HomeFormValidation.missingText;
    return HomeFormValidation.ok;
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    entryCtrl.dispose();
    super.dispose();
  }
}
