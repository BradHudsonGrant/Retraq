import '../l10n/app_localizations.dart';

/// Milestone thresholds — entry counts at which Retraq celebrates
/// with a messaged overlay instead of the routine save toast.
///
/// Task 1.2 — lifted from `home_screen.dart::_milestoneForCount` so
/// the rule is independently testable + reusable. A future
/// HomeSaveController will call this when deciding how long to hold
/// the save-success overlay (1000ms for milestones + first ten
/// saves, 400ms for routine thereafter — see Task 2.15).
///
/// Thresholds kept in sync with the ARB `milestone*` keys — adding a
/// new milestone means:
///   1. Pick a count (e.g. 2000).
///   2. Add `milestone2000` to `lib/l10n/app_en.arb`.
///   3. Regenerate localisations.
///   4. Add the `(count, getter)` pair in the map below.
///   5. Update the test in
///      `test/utils/milestones_test.dart` to pin the new threshold.
const List<int> milestoneThresholds = [
  1,
  5,
  10,
  25,
  50,
  100,
  250,
  500,
  1000,
];

/// Returns the celebration copy for [count] or `null` when the count
/// is not on a milestone threshold. Callers should treat `null` as
/// "routine save — use standard overlay hold".
String? milestoneMessageFor(int count, L10n l10n) {
  final milestones = <int, String>{
    1: l10n.milestone1,
    5: l10n.milestone5,
    10: l10n.milestone10,
    25: l10n.milestone25,
    50: l10n.milestone50,
    100: l10n.milestone100,
    250: l10n.milestone250,
    500: l10n.milestone500,
    1000: l10n.milestone1000,
  };
  return milestones[count];
}

/// Convenience predicate. Equivalent to
/// `milestoneMessageFor(count, l10n) != null` but without the ARB
/// lookup when the caller only needs the boolean.
bool isMilestoneCount(int count) => milestoneThresholds.contains(count);
