import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/audio_summary_repository.dart';
import '../../data/models/audio_summary_model.dart';

/// Repository provider.
final audioSummaryRepositoryProvider =
    Provider<AudioSummaryRepository>((ref) {
  return AudioSummaryRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(supabaseFunctionsProvider),
  );
});

/// Audio summaries for a course.
final audioSummariesProvider = FutureProvider.autoDispose
    .family<List<AudioSummaryModel>, String>((ref, courseId) async {
  return ref
      .watch(audioSummaryRepositoryProvider)
      .getSummariesForCourse(courseId);
});
