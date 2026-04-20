import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_log.dart';

const _shownKey = 'review_prompt_shown';
const _triggerCount = 5;

/// Trigger the in-app review prompt once, at the user's 5th entry.
///
/// Call after every successful save with the running total entry count.
/// The prompt fires at exactly [_triggerCount] and is remembered via
/// SharedPreferences so it never repeats. Safe to call with any count —
/// it's a no-op except at the trigger.
Future<void> maybePromptForReview(int totalEntryCount) async {
  if (totalEntryCount != _triggerCount) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_shownKey) == true) return;

    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
    await prefs.setBool(_shownKey, true);
  } catch (e) {
    AppLog.error('maybePromptForReview', e);
  }
}
