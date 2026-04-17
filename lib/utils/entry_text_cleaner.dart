/// Canonicalise free-text traq input before save.
///
/// Task 1.2 — extracted from `home_screen.dart::_cleanText` so the
/// rule is directly unit-testable and reusable from the
/// HomeFormController's `validate()` helper.
///
/// Rules:
///   1. Split on newlines.
///   2. Trim each line's leading/trailing whitespace.
///   3. Drop lines that are empty OR contain only a lone bullet
///      character (•). The bullet-only filter prevents
///      `bulletPointsOnEnter` (a preference that auto-prepends • on
///      newline) from silently inserting rows of empty bullets when
///      a user hits Enter several times.
///   4. Join with single newlines.
///   5. Trim the final result.
///
/// Rationale: the save flow should handle a "      \n• \n\n" draft
/// as empty, not as a savable entry with five whitespace lines.
/// This keeps the DB clean and matches what the user visually
/// typed (nothing).
String cleanEntryText(String raw) {
  final lines = raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l != '•' && l != '')
      .toList();
  return lines.join('\n').trim();
}
