import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/test_repository.dart';
import '../../data/models/test_question_model.dart';

/// Provider for the test repository.
final testRepositoryProvider = Provider<TestRepository>((ref) {
  return TestRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(supabaseFunctionsProvider),
  );
});

/// Fetches test results with questions.
final testResultsProvider = FutureProvider.autoDispose
    .family<TestWithQuestions, String>((ref, testId) async {
  return ref.watch(testRepositoryProvider).getTestResults(testId);
});

/// Fetches just the questions for a quiz session (before evaluation).
final quizQuestionsProvider = FutureProvider.autoDispose
    .family<List<TestQuestionModel>, String>((ref, testId) async {
  final result = await ref.read(testRepositoryProvider).getTestResults(testId);
  return result.questions;
});
