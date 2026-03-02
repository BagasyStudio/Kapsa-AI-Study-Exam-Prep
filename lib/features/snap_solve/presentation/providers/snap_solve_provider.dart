import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/snap_solve_repository.dart';
import '../../data/models/snap_solution_model.dart';

/// Provider for the [SnapSolveRepository].
final snapSolveRepositoryProvider = Provider<SnapSolveRepository>((ref) {
  return SnapSolveRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(supabaseFunctionsProvider),
  );
});

/// Solution history for the current user.
final snapSolveHistoryProvider =
    FutureProvider.autoDispose<List<SnapSolutionModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(snapSolveRepositoryProvider).getSolutions(user.id);
});

/// Single solution by ID (for viewing from history).
final snapSolutionProvider = FutureProvider.autoDispose
    .family<SnapSolutionModel?, String>((ref, id) async {
  return ref.read(snapSolveRepositoryProvider).getSolution(id);
});
