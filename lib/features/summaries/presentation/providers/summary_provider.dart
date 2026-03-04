import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/summary_repository.dart';
import '../../data/models/summary_model.dart';

/// Provider for the summary repository.
final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  return SummaryRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(supabaseFunctionsProvider),
  );
});

/// Fetches all summaries for a course.
final courseSummariesProvider = FutureProvider.autoDispose
    .family<List<SummaryModel>, String>((ref, courseId) async {
  return ref.watch(summaryRepositoryProvider).getSummariesForCourse(courseId);
});

/// Fetches a single summary.
final summaryProvider = FutureProvider.autoDispose
    .family<SummaryModel?, String>((ref, summaryId) async {
  return ref.watch(summaryRepositoryProvider).getSummary(summaryId);
});
