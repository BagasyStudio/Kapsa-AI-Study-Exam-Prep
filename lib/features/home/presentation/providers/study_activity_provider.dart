import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../test_results/data/models/test_model.dart';
import '../../../flashcards/data/models/deck_model.dart';

/// Combined study activity data for the home screen.
class StudyActivity {
  final List<TestModel> tests;
  final List<DeckModel> decks;

  const StudyActivity({required this.tests, required this.decks});
}

/// Fetches recent study activity (quizzes + flashcard decks) for the home screen.
final studyActivityProvider =
    FutureProvider.autoDispose<StudyActivity>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return const StudyActivity(tests: [], decks: []);

  // Fetch recent tests (with scores — evaluated ones)
  final testsData = await client
      .from('tests')
      .select()
      .eq('user_id', userId)
      .not('score', 'is', null)
      .order('created_at', ascending: false)
      .limit(3);

  // Fetch recent flashcard decks
  final decksData = await client
      .from('flashcard_decks')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(3);

  return StudyActivity(
    tests:
        (testsData as List).map((e) => TestModel.fromJson(e)).toList(),
    decks:
        (decksData as List).map((e) => DeckModel.fromJson(e)).toList(),
  );
});
