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

  /// Fetch all decks across all courses with their course name (for home quick access).
  Future<List<Map<String, dynamic>>> getAllDecksWithCourseName({
    int limit = 10,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('flashcard_decks')
        .select('*, courses!inner(title)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data as List);
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
