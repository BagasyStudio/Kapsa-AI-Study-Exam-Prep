import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/achievement_model.dart';

/// Repository for checking and unlocking achievement badges.
class AchievementRepository {
  final SupabaseClient _client;

  AchievementRepository(this._client);

  /// Fetch all unlocked achievements for the current user.
  Future<List<UnlockedAchievement>> getUnlocked() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('achievements')
        .select()
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false);

    return (data as List)
        .map((e) => UnlockedAchievement.fromJson(e))
        .toList();
  }

  /// Unlock a badge (idempotent — silently ignores if already unlocked).
  Future<bool> unlock(String badgeKey) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _client.from('achievements').upsert(
        {
          'user_id': userId,
          'badge_key': badgeKey,
        },
        onConflict: 'user_id,badge_key',
        ignoreDuplicates: true,
      );
      return true;
    } catch (e) {
      debugPrint('AchievementRepository: unlock failed: $e');
      return false;
    }
  }

  /// Check conditions and unlock any new badges the user has earned.
  ///
  /// Returns list of badge keys that were newly unlocked (empty if none).
  Future<List<String>> checkAndUnlock() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Fetch already-unlocked keys
    final unlocked = await getUnlocked();
    final unlockedKeys = unlocked.map((a) => a.badgeKey).toSet();

    // Gather stats in parallel
    final results = await Future.wait([
      _countXpEvents('quiz_complete'),
      _countXpEvents('perfect_quiz'),
      _countXpEvents('flashcard_review'),
      _countXpEvents('share_result'),
      _getStreakDays(),
      _getLevel(),
    ]);

    final quizCount = results[0];
    final perfectCount = results[1];
    final reviewCount = results[2];
    final shareCount = results[3];
    final streakDays = results[4];
    final level = results[5];

    // Determine which badges the user qualifies for
    final earned = <String>[];

    // Study badges
    if (quizCount >= 1) earned.add('first_quiz');
    if (quizCount >= 10) earned.add('quiz_10');
    if (quizCount >= 50) earned.add('quiz_50');
    if (perfectCount >= 1) earned.add('perfect_score');
    if (perfectCount >= 3) earned.add('perfect_3');

    // Streak badges
    if (streakDays >= 7) earned.add('streak_7');
    if (streakDays >= 30) earned.add('streak_30');
    if (streakDays >= 100) earned.add('streak_100');

    // Review badges
    if (reviewCount >= 1) earned.add('first_review');
    if (reviewCount >= 100) earned.add('review_100');
    if (reviewCount >= 500) earned.add('review_500');

    // Mastery badges
    if (level >= 5) earned.add('level_5');
    if (level >= 10) earned.add('level_10');
    if (level >= 25) earned.add('level_25');

    // Social badges
    if (shareCount >= 1) earned.add('sharer');

    // Filter to only new ones
    final newBadges = earned.where((k) => !unlockedKeys.contains(k)).toList();

    // Persist new unlocks
    for (final key in newBadges) {
      await unlock(key);
    }

    return newBadges;
  }

  // ── Private helpers ────────────────────────────────────────────────

  Future<int> _countXpEvents(String action) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final data = await _client
        .from('xp_events')
        .select('id')
        .eq('user_id', userId)
        .eq('action', action);

    return (data as List).length;
  }

  Future<int> _getStreakDays() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final data = await _client
        .from('profiles')
        .select('streak_days')
        .eq('id', userId)
        .maybeSingle();

    return (data?['streak_days'] as int?) ?? 0;
  }

  Future<int> _getLevel() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final data = await _client
        .from('profiles')
        .select('xp_level')
        .eq('id', userId)
        .maybeSingle();

    return (data?['xp_level'] as int?) ?? 0;
  }
}
