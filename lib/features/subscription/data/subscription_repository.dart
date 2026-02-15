import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for managing subscription status and usage tracking.
///
/// Implements the freemium gate system by tracking daily usage
/// per feature and checking against free tier limits.
class SubscriptionRepository {
  final SupabaseClient _client;

  SubscriptionRepository(this._client);

  /// Free tier daily limits per feature.
  static const Map<String, int> freeLimits = {
    'chat': 2,
    'flashcards': 1,
    'quiz': 1,
    'ocr': 2,
    'whisper': 2,
    'oracle': 3,
  };

  /// Check if user is a Pro subscriber.
  Future<bool> getIsPro(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('is_pro')
          .eq('id', userId)
          .single();
      return data['is_pro'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Check if the user can use a given feature today.
  ///
  /// Returns true if:
  /// - User is Pro (unlimited), or
  /// - User hasn't exceeded the free daily limit.
  Future<bool> checkCanUseFeature(String userId, String feature) async {
    // Check if Pro first
    final isPro = await getIsPro(userId);
    if (isPro) return true;

    // Count today's usage
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await _client
        .from('usage_tracking')
        .select('id')
        .eq('user_id', userId)
        .eq('feature', feature)
        .eq('used_at', today);

    final used = (data as List).length;
    final limit = freeLimits[feature] ?? 2;

    return used < limit;
  }

  /// Record a usage of a feature.
  Future<void> recordUsage(String userId, String feature) async {
    await _client.from('usage_tracking').insert({
      'user_id': userId,
      'feature': feature,
    });
  }

  /// Get daily usage counts for all features.
  ///
  /// Returns a map of feature → count for today.
  Future<Map<String, int>> getDailyUsage(String userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await _client
        .from('usage_tracking')
        .select('feature')
        .eq('user_id', userId)
        .eq('used_at', today);

    final usage = <String, int>{};
    for (final row in (data as List)) {
      final feature = row['feature'] as String;
      usage[feature] = (usage[feature] ?? 0) + 1;
    }
    return usage;
  }

  /// Get remaining uses for a specific feature today.
  Future<int> getRemainingUses(String userId, String feature) async {
    final isPro = await getIsPro(userId);
    if (isPro) return 999; // unlimited

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await _client
        .from('usage_tracking')
        .select('id')
        .eq('user_id', userId)
        .eq('feature', feature)
        .eq('used_at', today);

    final used = (data as List).length;
    final limit = freeLimits[feature] ?? 2;
    return (limit - used).clamp(0, limit);
  }
}
