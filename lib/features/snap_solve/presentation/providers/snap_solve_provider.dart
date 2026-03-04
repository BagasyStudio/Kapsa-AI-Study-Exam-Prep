import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../data/snap_solve_repository.dart';
import '../../data/models/snap_solution_model.dart';

// ══════════════════════════════════════════════════════════════
// Existing providers (unchanged)
// ══════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════
// Background job state (survives navigation)
// ══════════════════════════════════════════════════════════════

/// Possible states for the background solve job.
enum SnapSolveJobStatus { idle, uploading, solving, completed, error }

/// State for the background snap-solve job.
class SnapSolveJobState {
  final SnapSolveJobStatus status;
  final SnapSolutionModel? solution;
  final String? errorMessage;
  final String? rawError;
  final String? imageUrl;

  const SnapSolveJobState({
    this.status = SnapSolveJobStatus.idle,
    this.solution,
    this.errorMessage,
    this.rawError,
    this.imageUrl,
  });

  bool get isActive =>
      status == SnapSolveJobStatus.uploading ||
      status == SnapSolveJobStatus.solving;
}

/// Manages the background snap-solve job.
///
/// The notifier is **not** autoDispose so the solve survives
/// navigation away from the SnapSolveScreen.
class SnapSolveJobNotifier extends StateNotifier<SnapSolveJobState> {
  final SnapSolveRepository _repo;
  final SupabaseClient _client;
  final Ref _ref;

  SnapSolveJobNotifier(this._repo, this._client, this._ref)
      : super(const SnapSolveJobState());

  /// Start a solve job. Uploads image and calls the edge function.
  ///
  /// Returns immediately — the screen updates reactively via the provider.
  Future<void> startSolve(Uint8List imageBytes, String userId) async {
    if (state.isActive) return; // only one at a time

    state = const SnapSolveJobState(status: SnapSolveJobStatus.uploading);

    try {
      // ── Upload to Supabase Storage ──
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage
          .from('course-materials')
          .uploadBinary(fileName, imageBytes);
      final fileUrl =
          _client.storage.from('course-materials').getPublicUrl(fileName);

      if (!mounted) return;
      state = SnapSolveJobState(
        status: SnapSolveJobStatus.solving,
        imageUrl: fileUrl,
      );

      // ── Call edge function (~44s) ──
      final solution = await _repo.solveProblem(imageUrl: fileUrl);

      // ── Record usage + refresh history ──
      try {
        final user = _ref.read(currentUserProvider);
        if (user != null) {
          await _ref
              .read(subscriptionRepositoryProvider)
              .recordUsage(user.id, 'snap_solve');
          _ref.invalidate(dailyUsageProvider);
        }
      } catch (_) {
        // Best-effort usage recording
      }
      _ref.invalidate(snapSolveHistoryProvider);

      SoundService.playProcessingComplete();

      if (!mounted) return;
      state = SnapSolveJobState(
        status: SnapSolveJobStatus.completed,
        solution: solution,
        imageUrl: fileUrl,
      );
    } catch (e) {
      if (!mounted) return;
      final friendly = AppErrorHandler.friendlyMessage(e);
      String raw = e.toString();
      if (e is FunctionException) {
        raw = 'FunctionException(status=${e.status}, '
            'details=${e.details}, reasonPhrase=${e.reasonPhrase})';
      }
      debugPrint('[SnapSolveJob] Error: $raw');
      state = SnapSolveJobState(
        status: SnapSolveJobStatus.error,
        errorMessage: friendly,
        rawError: raw,
      );
    }
  }

  /// Reset back to idle (after user has viewed the result or dismissed error).
  void clear() {
    state = const SnapSolveJobState();
  }
}

/// Global snap-solve job provider. NOT autoDispose — survives navigation.
final snapSolveJobProvider =
    StateNotifierProvider<SnapSolveJobNotifier, SnapSolveJobState>((ref) {
  return SnapSolveJobNotifier(
    ref.watch(snapSolveRepositoryProvider),
    ref.watch(supabaseClientProvider),
    ref,
  );
});
