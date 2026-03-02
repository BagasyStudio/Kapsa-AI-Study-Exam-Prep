import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/xp_repository.dart';

/// Provides daily XP data for the last 91 days (13 weeks) for the heatmap.
final heatmapDataProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = XpRepository(ref.watch(supabaseClientProvider));
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 91));
  return repo.getXpForDateRange(start, now);
});
