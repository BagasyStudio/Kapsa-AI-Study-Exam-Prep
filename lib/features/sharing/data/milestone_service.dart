import 'package:supabase_flutter/supabase_flutter.dart';

/// Checks and tracks milestone achievements to trigger share prompts.
class MilestoneService {
  static const streakMilestones = [7, 30, 50, 100, 365];

  /// Check if a streak value is a milestone.
  static bool isStreakMilestone(int streakDays) {
    return streakMilestones.contains(streakDays);
  }

  /// Check if a milestone has already been shown.
  static Future<bool> hasBeenShown(String type, String value) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return true;

      final result = await Supabase.instance.client
          .from('milestones_shown')
          .select('id')
          .eq('user_id', userId)
          .eq('milestone_type', type)
          .eq('milestone_value', value)
          .maybeSingle();

      return result != null;
    } catch (_) {
      return true; // Assume shown on error
    }
  }

  /// Mark a milestone as shown.
  static Future<void> markShown(String type, String value) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('milestones_shown').upsert({
        'user_id': userId,
        'milestone_type': type,
        'milestone_value': value,
      });
    } catch (_) {}
  }

  /// Generic milestone check: returns the value if not yet shown, null otherwise.
  static Future<String?> checkMilestone(String type, String value) async {
    final shown = await hasBeenShown(type, value);
    return shown ? null : value;
  }

  /// Check for streak milestone and return the value if it should be shown.
  static Future<int?> checkStreakMilestone(int streakDays) async {
    if (!isStreakMilestone(streakDays)) return null;
    final shown = await hasBeenShown('streak', '$streakDays');
    if (shown) return null;
    return streakDays;
  }
}
