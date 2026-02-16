import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/deck_model.dart';
import 'models/flashcard_model.dart';

/// Repository for flashcard operations.
class FlashcardRepository {
  final SupabaseClient _client;

  FlashcardRepository(this._client);

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
    int count = 10,
    String? materialId,
    String? topic,
  }) async {
    try { await _client.auth.refreshSession(); } catch (_) {}
    final response = await _client.functions.invoke(
      'ai-generate-flashcards',
      body: {
        'courseId': courseId,
        'count': count,
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

  /// Update mastery level for a card.
  Future<void> updateMastery(String cardId, String mastery) async {
    await _client
        .from('flashcards')
        .update({'mastery': mastery})
        .eq('id', cardId);
  }
}
