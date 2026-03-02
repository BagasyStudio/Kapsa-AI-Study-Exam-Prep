import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/xp_config.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/xp_repository.dart';

/// Repository provider.
final xpRepositoryProvider = Provider<XpRepository>((ref) {
  return XpRepository(ref.watch(supabaseClientProvider));
});

/// Total XP for the current user.
final xpTotalProvider = FutureProvider<int>((ref) async {
  return ref.watch(xpRepositoryProvider).getXpTotal();
});

/// Current level derived from total XP.
final xpLevelProvider = Provider<int>((ref) {
  final xp = ref.watch(xpTotalProvider).whenOrNull(data: (v) => v) ?? 0;
  return XpConfig.levelFromXp(xp);
});

/// Progress towards next level (0.0–1.0).
final xpProgressProvider = Provider<double>((ref) {
  final xp = ref.watch(xpTotalProvider).whenOrNull(data: (v) => v) ?? 0;
  return XpConfig.progressToNextLevel(xp);
});
