import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_functions.dart';
import 'models/assistant_insight_model.dart';
import '../../chat/data/models/chat_message_model.dart';

/// Repository for AI assistant operations.
///
/// Communicates with the `ai-assistant` Edge Function which has
/// three modes: insights, chat, and calendar_suggestions.
class AssistantRepository {
  final SupabaseClient _client;
  final SupabaseFunctions _functions;

  AssistantRepository(this._client, this._functions);

  /// Get a personalized insight for the home screen.
  Future<AssistantInsightModel> getInsight() async {
    final response = await _functions.invoke(
      'ai-assistant',
      body: {'mode': 'insights'},
    );

    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from AI assistant');
    }
    return AssistantInsightModel.fromJson(data);
  }

  /// Get or create a global chat session (not tied to a course).
  Future<String> getOrCreateGlobalSession(String userId) async {
    // Look for existing global session (course_id is null)
    final existing = await _client
        .from('chat_sessions')
        .select('id')
        .eq('user_id', userId)
        .isFilter('course_id', null)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // Create new global session
    final data = await _client
        .from('chat_sessions')
        .insert({'user_id': userId})
        .select('id')
        .single();
    return data['id'] as String;
  }

  /// Fetch all messages for a global session.
  Future<List<ChatMessageModel>> getMessages(String sessionId) async {
    final data = await _client
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => ChatMessageModel.fromJson(e)).toList();
  }

  /// Send a message to the global AI assistant and get response.
  Future<ChatMessageModel> sendGlobalMessage({
    required String sessionId,
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    // Save user message to DB
    await _client.from('chat_messages').insert({
      'session_id': sessionId,
      'role': 'user',
      'content': message,
    });

    // Call Edge Function for AI response
    final response = await _functions.invoke(
      'ai-assistant',
      body: {
        'mode': 'chat',
        'message': message,
        'history': history,
      },
    );

    final responseData = response.data;
    if (responseData == null || responseData is! Map<String, dynamic>) {
      throw Exception('Invalid response from AI assistant');
    }
    final aiContent = responseData['content'] as String? ?? '';

    // Save AI response to DB
    final savedMsg = await _client
        .from('chat_messages')
        .insert({
          'session_id': sessionId,
          'role': 'assistant',
          'content': aiContent,
        })
        .select()
        .single();

    return ChatMessageModel.fromJson(savedMsg);
  }

  /// Generate AI-powered calendar suggestions.
  Future<int> generateCalendarSuggestions() async {
    final response = await _functions.invoke(
      'ai-assistant',
      body: {'mode': 'calendar_suggestions'},
    );

    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from AI assistant');
    }
    final suggestions = data['suggestions'] as List? ?? [];
    return suggestions.length;
  }
}
