import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../flashcards/data/models/deck_model.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';

/// A deck with its parent course name, for display on the home screen.
class DeckWithCourse {
  final DeckModel deck;
  final String courseName;

  const DeckWithCourse({required this.deck, required this.courseName});
}

/// Fetches recent flashcard decks across all courses for the home quick access.
///
/// NOT autoDispose — keeps cached data across navigation to avoid refetch flicker.
final flashcardQuickAccessProvider =
    FutureProvider<List<DeckWithCourse>>((ref) async {
  final repo = ref.watch(flashcardRepositoryProvider);
  final rawDecks = await repo.getAllDecksWithCourseName(limit: 10);

  return rawDecks.map((json) {
    // Extract the joined course title
    final coursesJoin = json['courses'];
    final courseName = coursesJoin is Map<String, dynamic>
        ? (coursesJoin['title'] as String? ?? 'Course')
        : 'Course';

    return DeckWithCourse(
      deck: DeckModel.fromJson(json),
      courseName: courseName,
    );
  }).toList();
});
