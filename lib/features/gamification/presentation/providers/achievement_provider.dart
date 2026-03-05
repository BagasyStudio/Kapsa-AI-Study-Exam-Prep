import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/achievement_repository.dart';
import '../../data/models/achievement_model.dart';

/// Repository provider for achievements.
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository(ref.watch(supabaseClientProvider));
});

/// Fetches all unlocked achievements for the current user.
///
/// NOT autoDispose — keeps cached data across navigation.
final unlockedAchievementsProvider =
    FutureProvider<List<UnlockedAchievement>>((ref) async {
  return ref.watch(achievementRepositoryProvider).getUnlocked();
});
