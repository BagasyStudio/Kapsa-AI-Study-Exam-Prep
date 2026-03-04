import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/glossary_repository.dart';
import '../../data/models/glossary_term_model.dart';

/// Provider for the glossary repository.
final glossaryRepositoryProvider = Provider<GlossaryRepository>((ref) {
  return GlossaryRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(supabaseFunctionsProvider),
  );
});

/// Fetches all glossary terms for a course.
final glossaryTermsProvider = FutureProvider.autoDispose
    .family<List<GlossaryTermModel>, String>((ref, courseId) async {
  return ref.watch(glossaryRepositoryProvider).getTerms(courseId);
});
