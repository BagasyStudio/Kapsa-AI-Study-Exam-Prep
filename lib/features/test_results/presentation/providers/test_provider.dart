import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/test_repository.dart';

/// Provider for the test repository.
final testRepositoryProvider = Provider<TestRepository>((ref) {
  return TestRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(supabaseFunctionsProvider),
  );
});

/// Fetches test results with questions.
final testResultsProvider = FutureProvider.autoDispose
    .family<TestWithQuestions?, String>((ref, testId) async {
  return ref.watch(testRepositoryProvider).getTestResults(testId);
});
