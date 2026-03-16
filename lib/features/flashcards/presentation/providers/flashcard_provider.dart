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

/// Fetches due cards across ALL user courses (for Quick Review mode).
final allDueCardsProvider =
    FutureProvider.autoDispose<List<FlashcardModel>>((ref) async {
  return ref.watch(flashcardRepositoryProvider).getAllDueCards(limit: 20);
});

// ── Subdeck (parent/child) providers ──────────────────────────────

/// Fetches child subdecks of a parent deck.
final childDecksProvider = FutureProvider.autoDispose
    .family<List<DeckModel>, String>((ref, parentDeckId) async {
  return ref.watch(flashcardRepositoryProvider).getChildDecks(parentDeckId);
});

/// Fetches only parent (root-level) decks for a course.
final parentDecksProvider = FutureProvider.autoDispose
    .family<List<DeckModel>, String>((ref, courseId) async {
  return ref.watch(flashcardRepositoryProvider).getParentDecks(courseId);
});

/// Fetches a single deck by ID.
final deckProvider = FutureProvider.autoDispose
    .family<DeckModel?, String>((ref, deckId) async {
  return ref.watch(flashcardRepositoryProvider).getDeck(deckId);
});

/// Due cards count for a parent deck (aggregated from children).
final dueCardsCountForParentDeckProvider = FutureProvider.autoDispose
    .family<int, String>((ref, parentDeckId) async {
  return ref
      .watch(flashcardRepositoryProvider)
      .getDueCardsCountForParentDeck(parentDeckId);
});

/// Recommended next subdeck to study for a parent deck.
final recommendedSubdeckProvider = FutureProvider.autoDispose
    .family<DeckModel?, String>((ref, parentDeckId) async {
  return ref
      .watch(flashcardRepositoryProvider)
      .getRecommendedSubdeck(parentDeckId);
});

/// Total due cards across ALL user courses (for home screen badge).
final totalDueCardsProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return 0;

  final now = DateTime.now().toUtc().toIso8601String();

  // Get all deck IDs for all of the user's courses
  final decks = await client
      .from('flashcard_decks')
      .select('id')
      .eq('user_id', userId);

  if ((decks as List).isEmpty) return 0;

  final deckIds = decks.map((d) => d['id'] as String).toList();

  final response = await client
      .from('flashcards')
      .select('id')
      .inFilter('deck_id', deckIds)
      .lte('due', now);

  return (response as List).length;
});
