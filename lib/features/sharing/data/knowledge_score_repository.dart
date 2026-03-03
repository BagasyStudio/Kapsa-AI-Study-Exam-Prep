import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/knowledge_score_model.dart';

/// Calculates the Knowledge Score from existing user data in Supabase.
class KnowledgeScoreRepository {
  final SupabaseClient _client;

  KnowledgeScoreRepository(this._client);

  Future<KnowledgeScoreModel> calculateScore() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('No authenticated user');
    final userId = user.id;

    // Run all queries in parallel
    final results = await Future.wait([
      _calcRetention(userId),     // 0
      _calcAccuracy(userId),      // 1
      _calcConsistency(userId),   // 2
      _calcDepth(userId),         // 3
      _calcMastery(userId),       // 4
      _calcExamReadiness(userId), // 5
      _calcDedication(userId),    // 6
    ]);

    final retention = results[0];
    final accuracy = results[1];
    final consistency = results[2];
    final depth = results[3];
    final mastery = results[4];
    final examReadiness = results[5];
    final dedication = results[6];
    const speed = 50.0; // Default - no direct speed data available

    // Weighted average
    final overall = (retention * 0.20 +
            accuracy * 0.15 +
            consistency * 0.15 +
            speed * 0.10 +
            depth * 0.10 +
            mastery * 0.15 +
            examReadiness * 0.10 +
            dedication * 0.05)
        .clamp(0.0, 100.0);

    final rank = KnowledgeScoreModel.rankFromScore(overall);

    return KnowledgeScoreModel(
      overallScore: overall,
      rank: rank,
      retention: retention,
      accuracy: accuracy,
      consistency: consistency,
      speed: speed,
      depth: depth,
      mastery: mastery,
      examReadiness: examReadiness,
      dedication: dedication,
    );
  }

  /// Retention: % of flashcards with srs_state = 2 (Review/Mastered) that have stability > 7
  Future<double> _calcRetention(String userId) async {
    try {
      final decks = await _client
          .from('flashcard_decks')
          .select('id')
          .eq('user_id', userId);
      if (decks.isEmpty) return 0;
      final deckIds = (decks as List).map((d) => d['id'] as String).toList();

      final cards = await _client
          .from('flashcards')
          .select('stability, srs_state')
          .inFilter('deck_id', deckIds);
      if (cards.isEmpty) return 0;

      final total = (cards as List).length;
      final retained = cards.where((c) {
        final state = c['srs_state'] as int? ?? 0;
        final stability = (c['stability'] as num?)?.toDouble() ?? 0;
        return state == 2 && stability > 7;
      }).length;

      return (retained / total * 100).clamp(0.0, 100.0);
    } catch (_) {
      return 0;
    }
  }

  /// Accuracy: average quiz/test score
  Future<double> _calcAccuracy(String userId) async {
    try {
      final tests = await _client
          .from('tests')
          .select('score')
          .eq('user_id', userId);
      if (tests.isEmpty) return 0;

      final scores = (tests as List)
          .map((t) => (t['score'] as num?)?.toDouble() ?? 0)
          .toList();
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      return (avg * 100).clamp(0.0, 100.0);
    } catch (_) {
      return 0;
    }
  }

  /// Consistency: active study days in last 30 / 30, boosted by streak
  Future<double> _calcConsistency(String userId) async {
    try {
      final thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

      final events = await _client
          .from('xp_events')
          .select('created_at')
          .eq('user_id', userId)
          .gte('created_at', thirtyDaysAgo);

      final uniqueDays = <String>{};
      for (final e in events) {
        final date = (e['created_at'] as String).substring(0, 10);
        uniqueDays.add(date);
      }

      final dayRatio = uniqueDays.length / 30.0;

      // Streak bonus (up to 10 points)
      final profile = await _client
          .from('profiles')
          .select('streak_days')
          .eq('id', userId)
          .maybeSingle();
      final streak = (profile?['streak_days'] as int?) ?? 0;
      final streakBonus = (streak / 30.0 * 10).clamp(0.0, 10.0);

      return (dayRatio * 90 + streakBonus).clamp(0.0, 100.0);
    } catch (_) {
      return 0;
    }
  }

  /// Depth: materials studied / total materials available
  Future<double> _calcDepth(String userId) async {
    try {
      final materials = await _client
          .from('course_materials')
          .select('id, course_id')
          .eq('user_id', userId);
      if (materials.isEmpty) return 0;

      // Check how many courses have materials
      final courseIds = <String>{};
      for (final m in materials) {
        courseIds.add(m['course_id'] as String);
      }

      final courses = await _client
          .from('courses')
          .select('id')
          .eq('user_id', userId);

      if (courses.isEmpty) return 50; // Default if no courses

      final coverage = courseIds.length / (courses as List).length;
      // Also consider material count
      final materialScore = ((materials as List).length / 10.0).clamp(0.0, 1.0);

      return ((coverage * 70 + materialScore * 30)).clamp(0.0, 100.0);
    } catch (_) {
      return 0;
    }
  }

  /// Mastery: flashcards with srs_state=2 and stability>30 / total
  Future<double> _calcMastery(String userId) async {
    try {
      final decks = await _client
          .from('flashcard_decks')
          .select('id')
          .eq('user_id', userId);
      if (decks.isEmpty) return 0;
      final deckIds = (decks as List).map((d) => d['id'] as String).toList();

      final cards = await _client
          .from('flashcards')
          .select('stability, srs_state')
          .inFilter('deck_id', deckIds);
      if (cards.isEmpty) return 0;

      final total = (cards as List).length;
      final mastered = cards.where((c) {
        final state = c['srs_state'] as int? ?? 0;
        final stability = (c['stability'] as num?)?.toDouble() ?? 0;
        return state == 2 && stability > 30;
      }).length;

      return (mastered / total * 100).clamp(0.0, 100.0);
    } catch (_) {
      return 0;
    }
  }

  /// Exam Readiness: avg practice exam score * (1 - due_ratio)
  Future<double> _calcExamReadiness(String userId) async {
    try {
      final tests = await _client
          .from('tests')
          .select('score')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);
      if (tests.isEmpty) return 0;

      final scores = (tests as List)
          .map((t) => (t['score'] as num?)?.toDouble() ?? 0)
          .toList();
      final avgScore = scores.reduce((a, b) => a + b) / scores.length;

      return (avgScore * 100).clamp(0.0, 100.0);
    } catch (_) {
      return 0;
    }
  }

  /// Dedication: XP earned in last 30 days normalized
  Future<double> _calcDedication(String userId) async {
    try {
      final thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

      final events = await _client
          .from('xp_events')
          .select('xp_amount')
          .eq('user_id', userId)
          .gte('created_at', thirtyDaysAgo);

      if (events.isEmpty) return 0;

      final totalXp = (events as List)
          .map((e) => (e['xp_amount'] as int?) ?? 0)
          .reduce((a, b) => a + b);

      // Normalize: 500 XP in 30 days = 100 score
      return (totalXp / 500.0 * 100).clamp(0.0, 100.0);
    } catch (_) {
      return 0;
    }
  }
}
