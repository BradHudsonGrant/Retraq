import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_log.dart';

/// Handles in-app review prompts.
/// Triggers once at the 5th journal entry, then never again.
class ReviewService {
  ReviewService._();
  static final instance = ReviewService._();

  static const _shownKey = 'review_prompt_shown';
  static const _triggerCount = 5;

  /// Call after each successful entry save with the current total count.
  /// Shows the in-app review dialog at exactly the 5th entry.
  Future<void> checkAndPrompt(int totalEntryCount) async {
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
      AppLog.error('ReviewService.checkAndPrompt', e);
    }
  }
}
