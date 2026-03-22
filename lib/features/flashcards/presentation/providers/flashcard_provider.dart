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

/// Fetches all child (topic-level) decks for a course.
final childDecksForCourseProvider = FutureProvider.autoDispose
    .family<List<DeckModel>, String>((ref, courseId) async {
  return ref.watch(flashcardRepositoryProvider).getChildDecksForCourse(courseId);
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

/// Counts bookmarked cards for a parent deck (aggregated from children).
final bookmarkedCardsCountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, parentDeckId) async {
  return ref
      .watch(flashcardRepositoryProvider)
      .getBookmarkedCardsCountForParentDeck(parentDeckId);
});

/// Fetches ALL cards for a parent deck (aggregated from all children).
/// Falls back to the deck itself for legacy flat decks with no children.
final allCardsForParentDeckProvider = FutureProvider.autoDispose
    .family<List<FlashcardModel>, String>((ref, parentDeckId) async {
  final repo = ref.watch(flashcardRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);

  // Check for child decks first
  final childDecks = await client
      .from('flashcard_decks')
      .select('id')
      .eq('parent_deck_id', parentDeckId);

  if ((childDecks as List).isEmpty) {
    // Legacy flat deck — return its own cards
    return repo.getCards(parentDeckId);
  }

  final childIds = childDecks.map((d) => d['id'] as String).toList();
  final data = await client
      .from('flashcards')
      .select()
      .inFilter('deck_id', childIds)
      .order('created_at', ascending: true)
      .limit(500);

  return (data as List).map((e) => FlashcardModel.fromJson(e)).toList();
});

/// Counts reviews in the last 7 days for a parent deck.
/// Returns {count, lastReviewedAt} as a map.
final deckStudyStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, parentDeckId) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return {'count': 0, 'lastReviewedAt': null};

  // Get relevant deck IDs (children or the deck itself)
  final childDecks = await client
      .from('flashcard_decks')
      .select('id')
      .eq('parent_deck_id', parentDeckId);

  List<String> deckIds;
  if ((childDecks as List).isEmpty) {
    deckIds = [parentDeckId];
  } else {
    deckIds = childDecks.map((d) => d['id'] as String).toList();
  }

  // Get card IDs for these decks
  final cards = await client
      .from('flashcards')
      .select('id')
      .inFilter('deck_id', deckIds);

  if ((cards as List).isEmpty) return {'count': 0, 'lastReviewedAt': null};

  final cardIds = cards.map((c) => c['id'] as String).toList();

  // Count reviews in last 7 days
  final weekAgo =
      DateTime.now().subtract(const Duration(days: 7)).toUtc().toIso8601String();

  final reviews = await client
      .from('card_reviews')
      .select('reviewed_at')
      .eq('user_id', userId)
      .inFilter('card_id', cardIds)
      .gte('reviewed_at', weekAgo)
      .order('reviewed_at', ascending: false);

  final reviewList = reviews as List;
  DateTime? lastReviewedAt;
  if (reviewList.isNotEmpty) {
    lastReviewedAt =
        DateTime.parse(reviewList.first['reviewed_at'] as String);
  }

  return {
    'count': reviewList.length,
    'lastReviewedAt': lastReviewedAt,
  };
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
