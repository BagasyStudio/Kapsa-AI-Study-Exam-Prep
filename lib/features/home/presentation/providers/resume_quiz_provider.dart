import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../test_results/data/test_repository.dart';
export '../../../test_results/data/test_repository.dart' show InProgressQuiz;
import '../../../test_results/presentation/providers/test_provider.dart';

/// Fetches in-progress quizzes for the resume banner on the home screen.
///
/// NOT autoDispose — keeps cached data across navigation to avoid refetch flicker.
final inProgressQuizzesProvider =
    FutureProvider<List<InProgressQuiz>>((ref) async {
  return ref.watch(testRepositoryProvider).getInProgressQuizzes();
});
