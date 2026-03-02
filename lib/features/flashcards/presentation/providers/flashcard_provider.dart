import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/flashcard_repository.dart';
import '../../data/models/deck_model.dart';
import '../../data/models/flashcard_model.dart';

/// Provider for the flashcard repository.
final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(supabaseFunctionsProvider),
  );
});

/// Fetches all decks for a course.
final flashcardDecksProvider = FutureProvider.autoDispose
    .family<List<DeckModel>, String>((ref, courseId) async {
  return ref.watch(flashcardRepositoryProvider).getDecks(courseId);
});

/// Fetches all cards in a deck.
final flashcardsProvider = FutureProvider.autoDispose
    .family<List<FlashcardModel>, String>((ref, deckId) async {
  return ref.watch(flashcardRepositoryProvider).getCards(deckId);
});

/// Fetches all cards due for review in a course.
final dueCardsProvider = FutureProvider.autoDispose
    .family<List<FlashcardModel>, String>((ref, courseId) async {
  return ref.watch(flashcardRepositoryProvider).getDueCards(courseId);
});

/// Counts cards due for review in a course (for badges/indicators).
final dueCardsCountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, courseId) async {
  return ref.watch(flashcardRepositoryProvider).getDueCardsCount(courseId);
});

/// Counts cards due for review in a specific deck.
final dueCardsCountForDeckProvider = FutureProvider.autoDispose
    .family<int, String>((ref, deckId) async {
  return ref.watch(flashcardRepositoryProvider).getDueCardsCountForDeck(deckId);
});
