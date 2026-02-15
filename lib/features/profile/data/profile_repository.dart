import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/profile_model.dart';

/// Repository for reading and writing user profile data.
class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  /// Fetch the profile for the given [userId].
  ///
  /// Returns a default profile if not found in database.
  Future<ProfileModel> getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return ProfileModel.fromJson(data);
    } catch (_) {
      return ProfileModel(id: userId);
    }
  }

  /// Update profile fields. Only non-null values are written.
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    int? streakDays,
    int? totalCourses,
    String? averageGrade,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (streakDays != null) updates['streak_days'] = streakDays;
    if (totalCourses != null) updates['total_courses'] = totalCourses;
    if (averageGrade != null) updates['average_grade'] = averageGrade;

    await _client.from('profiles').update(updates).eq('id', userId);
  }

  /// Update the user's daily streak.
  ///
  /// Calls the update_streak RPC function which handles:
  /// - Same day: no change
  /// - Consecutive day: increment streak
  /// - Gap: reset to 1
  Future<void> updateStreak(String userId) async {
    try {
      await _client.rpc('update_streak', params: {'p_user_id': userId});
    } catch (_) {
      // Silently fail — streak update is non-critical
    }
  }
}
