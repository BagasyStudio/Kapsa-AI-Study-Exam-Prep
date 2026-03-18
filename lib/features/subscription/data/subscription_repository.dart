import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_limits.dart';

/// Repository for managing subscription status and usage tracking.
///
/// Free users have a unified credit pool (50 credits/day).
/// Pro users have per-feature safety limits (effectively unlimited).
class SubscriptionRepository {
  final SupabaseClient _client;

  SubscriptionRepository(this._client);

  /// Pro tier daily limits per feature (anti-abuse safety net).
  static const Map<String, int> proLimits = AppLimits.proDailyLimits;

  /// Check if user is a Pro subscriber.
  Future<bool> getIsPro(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('is_pro, pro_override')
          .eq('id', userId)
          .single();
      return data['is_pro'] == true || data['pro_override'] == true;
    } catch (e) {
      debugPrint('SubscriptionRepository: getIsPro failed: $e');
      return false;
    }
  }

  /// Check if the user can use a given feature today.
  ///
  /// Pro: per-feature safety limits.
  /// Free: unified credit pool — checks if remaining credits >= feature cost.
  Future<bool> checkCanUseFeature(String userId, String feature) async {
    final isPro = await getIsPro(userId);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (isPro) {
      // Pro: per-feature safety limit
      final data = await _client
          .from('usage_tracking')
          .select('id')
          .eq('user_id', userId)
          .eq('feature', feature)
          .eq('used_at', today);

      final limit = proLimits[feature] ?? 10;
      return (data as List).length < limit;
    }

    // Free: unified credit pool
    final creditsUsed = await getCreditsUsedToday(userId);
    final cost = AppLimits.creditCost[feature] ?? 3;
    return creditsUsed + cost <= AppLimits.freeCreditsPerDay;
  }

  /// Record a usage of a feature (for both free and Pro users).
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

  /// Get total credits consumed today (free users).
  ///
  /// Sums creditCost[feature] × count for each feature used today.
  Future<int> getCreditsUsedToday(String userId) async {
    final usage = await getDailyUsage(userId);
    int total = 0;
    for (final entry in usage.entries) {
      total += (AppLimits.creditCost[entry.key] ?? 3) * entry.value;
    }
    return total;
  }

  /// Get remaining credits for today (free users).
  Future<int> getRemainingCredits(String userId) async {
    final used = await getCreditsUsedToday(userId);
    return (AppLimits.freeCreditsPerDay - used)
        .clamp(0, AppLimits.freeCreditsPerDay);
  }

  /// Get remaining uses for a specific feature today.
  Future<int> getRemainingUses(String userId, String feature) async {
    final isPro = await getIsPro(userId);

    if (isPro) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final data = await _client
          .from('usage_tracking')
          .select('id')
          .eq('user_id', userId)
          .eq('feature', feature)
          .eq('used_at', today);

      final used = (data as List).length;
      final limit = proLimits[feature] ?? 10;
      return (limit - used).clamp(0, limit);
    }

    // Free: return how many times this feature can be used with remaining credits
    final remaining = await getRemainingCredits(userId);
    final cost = AppLimits.creditCost[feature] ?? 3;
    if (cost == 0) return 999;
    return remaining ~/ cost;
  }
}
