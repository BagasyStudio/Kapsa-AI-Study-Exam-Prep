import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles strategic in-app review prompts.
///
/// Uses Apple's SKStoreReviewController which respects rate limits
/// (max 3 prompts per 365 days) automatically.
///
/// Triggers after positive moments:
/// - Completing a flashcard session
/// - Getting a good quiz score (≥80%)
/// - Every 5th completed session
class ReviewService {
  static const _keySessionCount = 'review_session_count';
  static const _keyLastPrompt = 'review_last_prompt';
  static const _triggerEveryN = 3;
  static const _minDaysBetween = 7; // Don't prompt more than every week

  /// Call after a positive user experience (quiz done, flashcard session done).
  ///
  /// Internally tracks session count and only shows the prompt every [_triggerEveryN]
  /// sessions, with a minimum gap of [_minDaysBetween] days.
  static Future<void> recordPositiveEvent() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Increment session counter
      final count = (prefs.getInt(_keySessionCount) ?? 0) + 1;
      await prefs.setInt(_keySessionCount, count);

      // Check if it's time to show prompt
      if (count % _triggerEveryN != 0) return;

      // Check minimum days between prompts
      final lastPrompt = prefs.getInt(_keyLastPrompt) ?? 0;
      final daysSince = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastPrompt))
          .inDays;
      if (lastPrompt > 0 && daysSince < _minDaysBetween) return;

      // Show the review prompt
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await prefs.setInt(
          _keyLastPrompt,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (_) {
      // Best-effort — never interrupt the user
    }
  }
}
