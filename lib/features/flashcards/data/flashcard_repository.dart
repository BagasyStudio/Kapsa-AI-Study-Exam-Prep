import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_functions.dart';
import 'models/deck_model.dart';
import 'models/flashcard_model.dart';
import 'fsrs.dart';

/// Repository for flashcard operations.
class FlashcardRepository {
  final SupabaseClient _client;
  final SupabaseFunctions _functions;

  FlashcardRepository(this._client, this._functions);

  /// Fetch all decks for a course.
  Future<List<DeckModel>> getDecks(String courseId) async {
    final data = await _client
        .from('flashcard_decks')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: false)
        .limit(30);
    return (data as List).map((e) => DeckModel.fromJson(e)).toList();
  }

  /// Fetch all cards in a deck.
  Future<List<FlashcardModel>> getCards(String deckId) async {
    final data = await _client
        .from('flashcards')
        .select()
        .eq('deck_id', deckId)
        .order('created_at', ascending: true)
        .limit(100);
    return (data as List).map((e) => FlashcardModel.fromJson(e)).toList();
  }

  /// Generate flashcards via Edge Function.
  Future<DeckModel> generateFlashcards({
    required String courseId,
    int? count,
    String? materialId,
    String? topic,
  }) async {
    final response = await _functions.invoke(
      'ai-generate-flashcards',
      body: {
        'courseId': courseId,
        if (count != null) 'count': count,
        if (materialId != null) 'materialId': materialId,
        if (topic != null) 'topic': topic,
      },
    );
    final responseData = response.data;
    if (responseData == null || responseData is! Map<String, dynamic>) {
      throw Exception('Invalid response from flashcard generation');
    }
    return DeckModel.fromJson(responseData);
  }

  /// Update card content fields (question, answer, topic).
  Future<void> updateCard({
    required String cardId,
    required String questionBefore,
    required String keyword,
    required String questionAfter,
    required String answer,
    required String topic,
  }) async {
    await _client.from('flashcards').update({
      'question_before': questionBefore,
      'keyword': keyword,
      'question_after': questionAfter,
      'answer': answer,
      'topic': topic,
    }).eq('id', cardId);
  }

  /// Update mastery level for a card (legacy — still works for swipe sessions).
  Future<void> updateMastery(String cardId, String mastery) async {
    await _client
        .from('flashcards')
        .update({'mastery': mastery})
        .eq('id', cardId);
  }

  /// Update a card after an SRS review and log the review.
  ///
  /// [updatedCard] should have the FSRS-computed fields already applied.
  /// [log] is the review log entry to insert.
  Future<void> updateCardAfterReview(
    FlashcardModel updatedCard,
    ReviewLog log,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Update card SRS fields
    await _client
        .from('flashcards')
        .update(updatedCard.toSrsJson())
        .eq('id', updatedCard.id);

    // Insert review log
    await _client.from('card_reviews').insert({
      'card_id': updatedCard.id,
      'user_id': userId,
      'rating': log.rating.value,
      'state': log.state.value,
      'scheduled_days': log.scheduledDays,
      'elapsed_days': log.elapsedDays,
      'reviewed_at': log.reviewedAt.toUtc().toIso8601String(),
    });
  }

  /// Fetch all cards that are due for review across all decks of a course.
  Future<List<FlashcardModel>> getDueCards(String courseId) async {
    final now = DateTime.now().toUtc().toIso8601String();

    // Get all deck IDs for this course
    final decks = await _client
        .from('flashcard_decks')
        .select('id')
        .eq('course_id', courseId);

    if ((decks as List).isEmpty) return [];

    final deckIds = decks.map((d) => d['id'] as String).toList();

    final data = await _client
        .from('flashcards')
        .select()
        .inFilter('deck_id', deckIds)
        .lte('due', now)
        .order('due', ascending: true)
        .limit(100);

    return (data as List).map((e) => FlashcardModel.fromJson(e)).toList();
  }

  /// Fetch all due cards across ALL of the user's courses (for quick review).
  ///
  /// Limited to [limit] cards, ordered by oldest due first.
  Future<List<FlashcardModel>> getAllDueCards({int limit = 20}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final now = DateTime.now().toUtc().toIso8601String();

    // Get all deck IDs for the current user
    final decks = await _client
        .from('flashcard_decks')
        .select('id')
        .eq('user_id', userId);

    if ((decks as List).isEmpty) return [];

    final deckIds = decks.map((d) => d['id'] as String).toList();

    final data = await _client
        .from('flashcards')
        .select()
        .inFilter('deck_id', deckIds)
        .lte('due', now)
        .order('due', ascending: true)
        .limit(limit);

    return (data as List).map((e) => FlashcardModel.fromJson(e)).toList();
  }

  /// Count cards due for review in a course.
  Future<int> getDueCardsCount(String courseId) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final decks = await _client
        .from('flashcard_decks')
        .select('id')
        .eq('course_id', courseId);

    if ((decks as List).isEmpty) return 0;

    final deckIds = decks.map((d) => d['id'] as String).toList();

    final response = await _client
        .from('flashcards')
        .select('id')
        .inFilter('deck_id', deckIds)
        .lte('due', now);

    return (response as List).length;
  }

  /// Count cards due for review in a specific deck.
  Future<int> getDueCardsCountForDeck(String deckId) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('flashcards')
        .select('id')
        .eq('deck_id', deckId)
        .lte('due', now);

    return (response as List).length;
  }

  /// Fetch all root-level decks across all courses with course name (for home).
  ///
  /// Excludes child subdecks — only parent and legacy flat decks.
  Future<List<Map<String, dynamic>>> getAllDecksWithCourseName({
    int limit = 10,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('flashcard_decks')
        .select('*, courses!inner(title)')
        .eq('user_id', userId)
        .isFilter('parent_deck_id', null)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Subdeck (parent/child) operations ─────────────────────────────

  /// Fetch child subdecks of a parent deck, ordered by creation date.
  Future<List<DeckModel>> getChildDecks(String parentDeckId) async {
    final data = await _client
        .from('flashcard_decks')
        .select()
        .eq('parent_deck_id', parentDeckId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => DeckModel.fromJson(e)).toList();
  }

  /// Fetch only root-level (parent) decks for a course.
  ///
  /// Excludes child subdecks — returns parent decks and legacy flat decks.
  Future<List<DeckModel>> getParentDecks(String courseId) async {
    final data = await _client
        .from('flashcard_decks')
        .select()
        .eq('course_id', courseId)
        .isFilter('parent_deck_id', null)
        .order('created_at', ascending: false)
        .limit(30);
    return (data as List).map((e) => DeckModel.fromJson(e)).toList();
  }

  /// Fetch a single deck by ID.
  Future<DeckModel?> getDeck(String deckId) async {
    final data = await _client
        .from('flashcard_decks')
        .select()
        .eq('id', deckId)
        .maybeSingle();
    if (data == null) return null;
    return DeckModel.fromJson(data);
  }

  /// Count due cards for a parent deck (aggregated across all children).
  Future<int> getDueCardsCountForParentDeck(String parentDeckId) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final childDecks = await _client
        .from('flashcard_decks')
        .select('id')
        .eq('parent_deck_id', parentDeckId);

    if ((childDecks as List).isEmpty) {
      // Legacy flat deck — check the deck itself
      final response = await _client
          .from('flashcards')
          .select('id')
          .eq('deck_id', parentDeckId)
          .lte('due', now);
      return (response as List).length;
    }

    final childIds = childDecks.map((d) => d['id'] as String).toList();
    final response = await _client
        .from('flashcards')
        .select('id')
        .inFilter('deck_id', childIds)
        .lte('due', now);
    return (response as List).length;
  }

  /// Get the recommended subdeck to study next.
  ///
  /// Priority: most due cards → most new cards → most recently created.
  Future<DeckModel?> getRecommendedSubdeck(String parentDeckId) async {
    final children = await getChildDecks(parentDeckId);
    if (children.isEmpty) return null;

    final now = DateTime.now().toUtc().toIso8601String();
    DeckModel? bestDue;
    int bestDueCount = 0;
    DeckModel? bestNew;
    int bestNewCount = 0;

    for (final child in children) {
      // Count due cards
      final dueResponse = await _client
          .from('flashcards')
          .select('id')
          .eq('deck_id', child.id)
          .lte('due', now);
      final dueCount = (dueResponse as List).length;

      if (dueCount > bestDueCount) {
        bestDueCount = dueCount;
        bestDue = child;
      }

      // Count new (never reviewed) cards
      final newResponse = await _client
          .from('flashcards')
          .select('id')
          .eq('deck_id', child.id)
          .eq('srs_state', 0);
      final newCount = (newResponse as List).length;

      if (newCount > bestNewCount) {
        bestNewCount = newCount;
        bestNew = child;
      }
    }

    // Priority: due cards first, then new cards, then first child
    if (bestDueCount > 0) return bestDue;
    if (bestNewCount > 0) return bestNew;
    return children.firstOrNull;
  }

  /// Get the course ID for a deck.
  Future<String?> getCourseIdForDeck(String deckId) async {
    final data = await _client
        .from('flashcard_decks')
        .select('course_id')
        .eq('id', deckId)
        .maybeSingle();
    return data?['course_id'] as String?;
  }

  /// Share a deck and get a 6-character share code.
  Future<String> shareDeck(String deckId) async {
    final response = await _functions.invoke(
      'share-deck',
      body: {'action': 'share', 'deckId': deckId},
    );
    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from share function');
    }
    return data['shareCode'] as String;
  }

  /// Look up a share code to preview the deck without importing.
  Future<Map<String, dynamic>> lookupShareCode(String shareCode) async {
    final response = await _functions.invoke(
      'share-deck',
      body: {'action': 'lookup', 'shareCode': shareCode},
    );
    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid share code');
    }
    return data;
  }

  /// Create a flashcard deck locally (for image occlusion).
  Future<DeckModel> createDeck({
    required String courseId,
    required String title,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final data = await _client
        .from('flashcard_decks')
        .insert({
          'user_id': userId,
          'course_id': courseId,
          'title': title,
        })
        .select()
        .single();
    return DeckModel.fromJson(data);
  }

  /// Insert flashcards locally (for image occlusion).
  Future<void> insertCards(List<Map<String, dynamic>> cards) async {
    if (cards.isEmpty) return;
    await _client.from('flashcards').insert(cards);
  }

  /// Delete multiple flashcards by their IDs.
  Future<void> deleteCardsByIds(List<String> cardIds) async {
    if (cardIds.isEmpty) return;
    await _client.from('flashcards').delete().inFilter('id', cardIds);
  }

  /// Delete a deck and all its flashcards (including child subdecks).
  Future<void> deleteDeck(String deckId) async {
    // Delete child subdecks' cards first
    final children = await _client
        .from('flashcard_decks')
        .select('id')
        .eq('parent_deck_id', deckId);
    for (final child in (children as List)) {
      await _client
          .from('flashcards')
          .delete()
          .eq('deck_id', child['id'] as String);
    }
    // Delete child subdecks
    await _client
        .from('flashcard_decks')
        .delete()
        .eq('parent_deck_id', deckId);
    // Delete this deck's cards
    await _client.from('flashcards').delete().eq('deck_id', deckId);
    // Delete the deck itself
    await _client.from('flashcard_decks').delete().eq('id', deckId);
  }

  // ── Bookmark operations ──────────────────────────────────────────

  /// Toggle bookmark state for a card.
  Future<void> toggleBookmark(String cardId, bool isBookmarked) async {
    await _client
        .from('flashcards')
        .update({'is_bookmarked': isBookmarked})
        .eq('id', cardId);
  }

  /// Fetch bookmarked cards for a deck.
  Future<List<FlashcardModel>> getBookmarkedCards(String deckId) async {
    final data = await _client
        .from('flashcards')
        .select()
        .eq('deck_id', deckId)
        .eq('is_bookmarked', true)
        .order('created_at', ascending: true)
        .limit(100);
    return (data as List).map((e) => FlashcardModel.fromJson(e)).toList();
  }

  /// Count bookmarked cards for a deck.
  Future<int> getBookmarkedCardsCount(String deckId) async {
    final data = await _client
        .from('flashcards')
        .select('id')
        .eq('deck_id', deckId)
        .eq('is_bookmarked', true);
    return (data as List).length;
  }

  /// Count bookmarked cards across all children of a parent deck.
  Future<int> getBookmarkedCardsCountForParentDeck(String parentDeckId) async {
    final childDecks = await _client
        .from('flashcard_decks')
        .select('id')
        .eq('parent_deck_id', parentDeckId);

    if ((childDecks as List).isEmpty) {
      // Legacy flat deck — check the deck itself
      return getBookmarkedCardsCount(parentDeckId);
    }

    final childIds = childDecks.map((d) => d['id'] as String).toList();
    final data = await _client
        .from('flashcards')
        .select('id')
        .inFilter('deck_id', childIds)
        .eq('is_bookmarked', true);
    return (data as List).length;
  }

  /// Import a shared deck by code into a target course.
  Future<DeckModel> importDeck(String shareCode, String courseId) async {
    final response = await _functions.invoke(
      'share-deck',
      body: {
        'action': 'import',
        'shareCode': shareCode,
        'courseId': courseId,
      },
    );
    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from import');
    }
    return DeckModel.fromJson(data);
  }
}
