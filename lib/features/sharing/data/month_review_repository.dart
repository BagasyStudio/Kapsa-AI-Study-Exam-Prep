import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/month_review_model.dart';

/// Calculates monthly review data from existing Supabase tables.
class MonthReviewRepository {
  final SupabaseClient _client;

  MonthReviewRepository(this._client);

  Future<MonthReviewModel> getReview({int? year, int? month}) async {
    final now = DateTime.now();
    // Default to previous month
    final targetDate = DateTime(year ?? now.year, (month ?? now.month) - 1);
    final targetYear = targetDate.year;
    final targetMonth = targetDate.month;

    final startDate = DateTime(targetYear, targetMonth, 1);
    final endDate = DateTime(targetYear, targetMonth + 1, 1);
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    final userId = _client.auth.currentUser!.id;
    final monthName = DateFormat('MMMM').format(startDate);

    // Run all queries in parallel
    final results = await Future.wait([
      _getXpData(userId, startStr, endStr),       // 0: {total, sessions, lateNight, earlyMorning}
      _getCardData(userId, startStr, endStr),       // 1: card review count
      _getQuizData(userId, startStr, endStr),       // 2: {count, avgScore}
      _getTopCourse(userId, startStr, endStr),      // 3: course name
    ]);

    final xpData = results[0] as Map<String, dynamic>;
    final cardsReviewed = results[1] as int;
    final quizData = results[2] as Map<String, dynamic>;
    final topCourse = results[3] as String;

    final totalXp = xpData['total'] as int;
    final totalSessions = xpData['sessions'] as int;
    final activeDays = xpData['activeDays'] as int;
    final lateNight = xpData['lateNight'] as int;
    final earlyMorning = xpData['earlyMorning'] as int;
    final avgScore = quizData['avgScore'] as double;

    final personality = StudyPersonality.determine(
      activeDays: activeDays,
      avgQuizScore: avgScore,
      lateNightSessions: lateNight,
      earlyMorningSessions: earlyMorning,
      totalSessions: totalSessions,
    );
    final pInfo = StudyPersonality.personalities[personality]!;

    return MonthReviewModel(
      year: targetYear,
      month: targetMonth,
      monthName: monthName,
      totalXpEarned: totalXp,
      totalSessions: totalSessions,
      cardsReviewed: cardsReviewed,
      quizzesTaken: quizData['count'] as int,
      averageQuizScore: avgScore,
      bestStreak: activeDays, // Approximate
      activeDays: activeDays,
      studyPersonality: personality,
      personalityEmoji: pInfo.emoji,
      personalityDescription: pInfo.description,
      knowledgeScoreStart: 0, // Would need historical data
      knowledgeScoreEnd: 0,
      topCourseName: topCourse,
    );
  }

  Future<Map<String, dynamic>> _getXpData(
      String userId, String start, String end) async {
    try {
      final events = await _client
          .from('xp_events')
          .select('xp_amount, created_at')
          .eq('user_id', userId)
          .gte('created_at', start)
          .lt('created_at', end);

      int total = 0;
      int lateNight = 0;
      int earlyMorning = 0;
      final days = <String>{};

      for (final e in events) {
        total += (e['xp_amount'] as int?) ?? 0;
        final date = e['created_at'] as String;
        days.add(date.substring(0, 10));

        final hour = DateTime.parse(date).hour;
        if (hour >= 21 || hour < 5) lateNight++;
        if (hour >= 5 && hour < 8) earlyMorning++;
      }

      return {
        'total': total,
        'sessions': (events as List).length,
        'activeDays': days.length,
        'lateNight': lateNight,
        'earlyMorning': earlyMorning,
      };
    } catch (_) {
      return {'total': 0, 'sessions': 0, 'activeDays': 0, 'lateNight': 0, 'earlyMorning': 0};
    }
  }

  Future<int> _getCardData(String userId, String start, String end) async {
    try {
      final reviews = await _client
          .from('card_reviews')
          .select('id')
          .eq('user_id', userId)
          .gte('reviewed_at', start)
          .lt('reviewed_at', end);
      return (reviews as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> _getQuizData(
      String userId, String start, String end) async {
    try {
      final tests = await _client
          .from('tests')
          .select('score')
          .eq('user_id', userId)
          .gte('created_at', start)
          .lt('created_at', end);

      if ((tests as List).isEmpty) {
        return {'count': 0, 'avgScore': 0.0};
      }

      final scores = tests.map((t) => (t['score'] as num?)?.toDouble() ?? 0).toList();
      final avg = scores.reduce((a, b) => a + b) / scores.length * 100;

      return {'count': tests.length, 'avgScore': avg};
    } catch (_) {
      return {'count': 0, 'avgScore': 0.0};
    }
  }

  Future<String> _getTopCourse(String userId, String start, String end) async {
    try {
      // Find most active course by XP events
      final events = await _client
          .from('xp_events')
          .select('metadata')
          .eq('user_id', userId)
          .gte('created_at', start)
          .lt('created_at', end);

      final courseCounts = <String, int>{};
      for (final e in events) {
        final meta = e['metadata'] as Map<String, dynamic>?;
        final courseId = meta?['course_id'] as String?;
        if (courseId != null) {
          courseCounts[courseId] = (courseCounts[courseId] ?? 0) + 1;
        }
      }

      if (courseCounts.isEmpty) return 'Your Courses';

      final topId = courseCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final course = await _client
          .from('courses')
          .select('title')
          .eq('id', topId)
          .maybeSingle();

      return course?['title'] as String? ?? 'Your Courses';
    } catch (_) {
      return 'Your Courses';
    }
  }
}
