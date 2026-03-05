import 'package:flutter/material.dart';

/// A user's unlocked achievement from the database.
class UnlockedAchievement {
  final String id;
  final String badgeKey;
  final DateTime unlockedAt;

  const UnlockedAchievement({
    required this.id,
    required this.badgeKey,
    required this.unlockedAt,
  });

  factory UnlockedAchievement.fromJson(Map<String, dynamic> json) {
    return UnlockedAchievement(
      id: json['id'] as String,
      badgeKey: json['badge_key'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
  }
}

/// Static definition of an achievement badge.
class BadgeDefinition {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final BadgeCategory category;

  const BadgeDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.category,
  });
}

enum BadgeCategory { study, streak, review, mastery }

/// All available badges in the app.
///
/// Badge keys are stable identifiers stored in the DB — never rename them.
abstract final class Badges {
  // ── Study ──────────────────────────────────────────────────────────
  static const firstQuiz = BadgeDefinition(
    key: 'first_quiz',
    title: 'First Steps',
    description: 'Complete your first quiz',
    icon: Icons.school_rounded,
    gradient: [Color(0xFF3B82F6), Color(0xFF6366F1)],
    category: BadgeCategory.study,
  );

  static const quiz10 = BadgeDefinition(
    key: 'quiz_10',
    title: 'Quiz Enthusiast',
    description: 'Complete 10 quizzes',
    icon: Icons.quiz_rounded,
    gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    category: BadgeCategory.study,
  );

  static const quiz50 = BadgeDefinition(
    key: 'quiz_50',
    title: 'Quiz Master',
    description: 'Complete 50 quizzes',
    icon: Icons.emoji_events_rounded,
    gradient: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
    category: BadgeCategory.study,
  );

  static const perfectScore = BadgeDefinition(
    key: 'perfect_score',
    title: 'Perfectionist',
    description: 'Score 100% on a quiz',
    icon: Icons.star_rounded,
    gradient: [Color(0xFFF59E0B), Color(0xFFF97316)],
    category: BadgeCategory.study,
  );

  static const perfect3 = BadgeDefinition(
    key: 'perfect_3',
    title: 'Golden Streak',
    description: 'Score 100% on 3 different quizzes',
    icon: Icons.auto_awesome_rounded,
    gradient: [Color(0xFFF97316), Color(0xFFEF4444)],
    category: BadgeCategory.study,
  );

  // ── Streak ─────────────────────────────────────────────────────────
  static const streak7 = BadgeDefinition(
    key: 'streak_7',
    title: 'Week Warrior',
    description: 'Maintain a 7-day study streak',
    icon: Icons.local_fire_department_rounded,
    gradient: [Color(0xFFF97316), Color(0xFFEF4444)],
    category: BadgeCategory.streak,
  );

  static const streak30 = BadgeDefinition(
    key: 'streak_30',
    title: 'Monthly Dedication',
    description: 'Maintain a 30-day study streak',
    icon: Icons.whatshot_rounded,
    gradient: [Color(0xFFEF4444), Color(0xFFEC4899)],
    category: BadgeCategory.streak,
  );

  static const streak100 = BadgeDefinition(
    key: 'streak_100',
    title: 'Centurion',
    description: 'Maintain a 100-day study streak',
    icon: Icons.military_tech_rounded,
    gradient: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    category: BadgeCategory.streak,
  );

  // ── Review ─────────────────────────────────────────────────────────
  static const firstReview = BadgeDefinition(
    key: 'first_review',
    title: 'Memory Keeper',
    description: 'Complete your first flashcard review',
    icon: Icons.style_rounded,
    gradient: [Color(0xFF10B981), Color(0xFF06B6D4)],
    category: BadgeCategory.review,
  );

  static const review100 = BadgeDefinition(
    key: 'review_100',
    title: 'Card Shark',
    description: 'Review 100 flashcards',
    icon: Icons.layers_rounded,
    gradient: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    category: BadgeCategory.review,
  );

  static const review500 = BadgeDefinition(
    key: 'review_500',
    title: 'Flashcard Legend',
    description: 'Review 500 flashcards',
    icon: Icons.diamond_rounded,
    gradient: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    category: BadgeCategory.review,
  );

  // ── Mastery ────────────────────────────────────────────────────────
  static const level5 = BadgeDefinition(
    key: 'level_5',
    title: 'Rising Star',
    description: 'Reach Level 5',
    icon: Icons.trending_up_rounded,
    gradient: [Color(0xFF10B981), Color(0xFF059669)],
    category: BadgeCategory.mastery,
  );

  static const level10 = BadgeDefinition(
    key: 'level_10',
    title: 'Dedicated Learner',
    description: 'Reach Level 10',
    icon: Icons.workspace_premium_rounded,
    gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    category: BadgeCategory.mastery,
  );

  static const level25 = BadgeDefinition(
    key: 'level_25',
    title: 'Scholar Elite',
    description: 'Reach Level 25',
    icon: Icons.shield_rounded,
    gradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    category: BadgeCategory.mastery,
  );

  static const sharer = BadgeDefinition(
    key: 'sharer',
    title: 'Social Learner',
    description: 'Share a study result',
    icon: Icons.share_rounded,
    gradient: [Color(0xFF06B6D4), Color(0xFF10B981)],
    category: BadgeCategory.mastery,
  );

  /// All badge definitions, in display order.
  static const List<BadgeDefinition> all = [
    firstQuiz,
    quiz10,
    quiz50,
    perfectScore,
    perfect3,
    streak7,
    streak30,
    streak100,
    firstReview,
    review100,
    review500,
    level5,
    level10,
    level25,
    sharer,
  ];

  /// Lookup map by key.
  static final Map<String, BadgeDefinition> byKey = {
    for (final b in all) b.key: b,
  };
}
