import 'dart:math';

/// XP amounts awarded for various actions.
abstract final class XpConfig {
  // ── Per-action XP values ──
  static const int flashcardReview = 5;
  static const int quizComplete = 10;
  static const int streakDay = 15;
  static const int shareDeck = 20;
  static const int materialUpload = 10;
  static const int perfectQuiz = 50;

  /// Bonus XP based on quiz score percentage: `(score% × 0.2)` rounded.
  static int quizScoreBonus(double scorePercent) =>
      (scorePercent * 0.2).round();

  /// Calculate level from total XP: `floor(sqrt(xp / 100)) + 1`.
  static int levelFromXp(int xp) => (sqrt(xp / 100)).floor() + 1;

  /// XP required to reach a specific level: `(level - 1)^2 * 100`.
  static int xpForLevel(int level) => (level - 1) * (level - 1) * 100;

  /// Progress (0.0–1.0) towards the next level.
  static double progressToNextLevel(int xp) {
    final currentLevel = levelFromXp(xp);
    final currentLevelXp = xpForLevel(currentLevel);
    final nextLevelXp = xpForLevel(currentLevel + 1);
    final range = nextLevelXp - currentLevelXp;
    if (range <= 0) return 1.0;
    return ((xp - currentLevelXp) / range).clamp(0.0, 1.0);
  }

  /// Human-readable action labels.
  static String actionLabel(String action) {
    return switch (action) {
      'flashcard_review' => 'Card Review',
      'quiz_complete' => 'Quiz Complete',
      'streak_day' => 'Daily Streak',
      'share_deck' => 'Shared Deck',
      'material_upload' => 'Material Upload',
      'perfect_quiz' => 'Perfect Score',
      _ => action,
    };
  }
}
