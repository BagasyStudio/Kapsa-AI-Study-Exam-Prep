import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/xp_config.dart';
import 'models/xp_event_model.dart';

/// Repository for XP / gamification operations.
class XpRepository {
  final SupabaseClient _client;

  XpRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Award XP for an action and update profile totals.
  ///
  /// Returns the XP amount awarded.
  Future<int> awardXp({
    required String action,
    required int amount,
    Map<String, dynamic> metadata = const {},
  }) async {
    // Insert event
    await _client.from('xp_events').insert({
      'user_id': _userId,
      'action': action,
      'xp_amount': amount,
      'metadata': metadata,
    });

    // Update profile totals
    final profile = await _client
        .from('profiles')
        .select('xp_total')
        .eq('id', _userId)
        .single();

    final newTotal = ((profile['xp_total'] as num?)?.toInt() ?? 0) + amount;
    final newLevel = XpConfig.levelFromXp(newTotal);

    await _client.from('profiles').update({
      'xp_total': newTotal,
      'xp_level': newLevel,
    }).eq('id', _userId);

    return amount;
  }

  /// Get total XP for the current user.
  Future<int> getXpTotal() async {
    final data = await _client
        .from('profiles')
        .select('xp_total')
        .eq('id', _userId)
        .single();
    return (data['xp_total'] as num?)?.toInt() ?? 0;
  }

  /// Get XP events for a date range (for heatmap).
  ///
  /// Returns a map of date string (yyyy-MM-dd) → total XP for that day.
  Future<Map<String, int>> getXpForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final data = await _client
        .from('xp_events')
        .select('xp_amount, created_at')
        .eq('user_id', _userId)
        .gte('created_at', start.toUtc().toIso8601String())
        .lte('created_at', end.toUtc().toIso8601String())
        .order('created_at', ascending: true);

    final Map<String, int> dailyXp = {};
    for (final row in data as List) {
      final dt = DateTime.parse(row['created_at'] as String).toLocal();
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      dailyXp[key] = (dailyXp[key] ?? 0) + (row['xp_amount'] as num).toInt();
    }
    return dailyXp;
  }

  /// Get recent XP events (for activity feed).
  Future<List<XpEventModel>> getRecentEvents({int limit = 20}) async {
    final data = await _client
        .from('xp_events')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => XpEventModel.fromJson(e)).toList();
  }

  /// Check if streak XP was already awarded today.
  Future<bool> hasStreakXpToday() async {
    final now = DateTime.now();
    final todayStart =
        DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

    final data = await _client
        .from('xp_events')
        .select('id')
        .eq('user_id', _userId)
        .eq('action', 'streak_day')
        .gte('created_at', todayStart)
        .limit(1);

    return (data as List).isNotEmpty;
  }
}
