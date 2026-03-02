/// Data model for a monthly study review.
class MonthReviewModel {
  final int year;
  final int month;
  final String monthName;
  final int totalXpEarned;
  final int totalSessions;
  final int cardsReviewed;
  final int quizzesTaken;
  final double averageQuizScore; // 0-100
  final int bestStreak;
  final int activeDays;
  final String studyPersonality;
  final String personalityEmoji;
  final String personalityDescription;
  final double knowledgeScoreStart;
  final double knowledgeScoreEnd;
  final String topCourseName;

  const MonthReviewModel({
    required this.year,
    required this.month,
    required this.monthName,
    required this.totalXpEarned,
    required this.totalSessions,
    required this.cardsReviewed,
    required this.quizzesTaken,
    required this.averageQuizScore,
    required this.bestStreak,
    required this.activeDays,
    required this.studyPersonality,
    required this.personalityEmoji,
    required this.personalityDescription,
    required this.knowledgeScoreStart,
    required this.knowledgeScoreEnd,
    required this.topCourseName,
  });
}

/// Study personality types
class StudyPersonality {
  static const personalities = {
    'night_owl': (
      name: 'The Night Owl',
      emoji: '🦉',
      description: 'You thrive when the world sleeps. Late night study sessions are your superpower.',
    ),
    'early_bird': (
      name: 'The Early Bird',
      emoji: '🐦',
      description: 'You catch the worm! Morning study sessions give you the edge.',
    ),
    'sprinter': (
      name: 'The Sprinter',
      emoji: '⚡',
      description: 'Quick, focused bursts. You maximize every minute of study time.',
    ),
    'marathon_runner': (
      name: 'The Marathon Runner',
      emoji: '🏃',
      description: 'Long, deep study sessions. You go all in when you sit down.',
    ),
    'perfectionist': (
      name: 'The Perfectionist',
      emoji: '💎',
      description: 'Nothing less than the best. Your quiz scores prove your dedication.',
    ),
    'consistent': (
      name: 'The Consistent',
      emoji: '🎯',
      description: 'Day after day, you show up. Consistency is your greatest strength.',
    ),
  };

  static String determine({
    required int activeDays,
    required double avgQuizScore,
    required int lateNightSessions,
    required int earlyMorningSessions,
    required int totalSessions,
  }) {
    if (activeDays >= 20) return 'consistent';
    if (avgQuizScore >= 90) return 'perfectionist';
    if (totalSessions > 0 && lateNightSessions / totalSessions > 0.6) return 'night_owl';
    if (totalSessions > 0 && earlyMorningSessions / totalSessions > 0.6) return 'early_bird';
    if (totalSessions > 30) return 'sprinter';
    return 'marathon_runner';
  }
}
