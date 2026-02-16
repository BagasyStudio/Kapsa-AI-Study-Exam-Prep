import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_functions.dart';
import 'models/chat_message_model.dart';

/// Repository for AI chat operations.
class ChatRepository {
  final SupabaseClient _client;
  final SupabaseFunctions _functions;

  ChatRepository(this._client, this._functions);

  /// Get or create a chat session for a course.
  Future<String> getOrCreateSession(String courseId, String userId) async {
    // Try to find existing session
    final existing = await _client
        .from('chat_sessions')
        .select('id')
        .eq('course_id', courseId)
        .eq('user_id', userId)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // Create new session
    final data = await _client
        .from('chat_sessions')
        .insert({
          'course_id': courseId,
          'user_id': userId,
        })
        .select('id')
        .single();
    return data['id'] as String;
  }

  /// Fetch all messages for a session.
  Future<List<ChatMessageModel>> getMessages(String sessionId) async {
    final data = await _client
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: false)
        .limit(50);
    // Reverse to get chronological order (oldest first) after limiting
    return (data as List)
        .map((e) => ChatMessageModel.fromJson(e))
        .toList()
        .reversed
        .toList();
  }

  /// Send a message and get AI response via Edge Function.
  Future<ChatMessageModel> sendMessage({
    required String courseId,
    required String sessionId,
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    // Save user message first
    await _client.from('chat_messages').insert({
      'session_id': sessionId,
      'role': 'user',
      'content': message,
    });

    // Call Edge Function for AI response
    final response = await _functions.invoke(
      'ai-chat',
      body: {
        'courseId': courseId,
        'sessionId': sessionId,
        'message': message,
        'history': history,
      },
    );

    final responseData = response.data;
    if (responseData == null || responseData is! Map<String, dynamic>) {
      throw Exception('Invalid response from AI chat');
    }
    return ChatMessageModel.fromJson(responseData);
  }
}
