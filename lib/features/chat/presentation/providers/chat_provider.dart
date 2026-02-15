import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_message_model.dart';

/// Provider for the chat repository.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

/// State for a chat session.
class ChatState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? error;
  final String? sessionId;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.sessionId,
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? error,
    String? sessionId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

/// StateNotifier for managing chat messages and AI interactions.
class ChatMessagesNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repo;
  final String courseId;
  final String userId;

  ChatMessagesNotifier({
    required ChatRepository repo,
    required this.courseId,
    required this.userId,
  })  : _repo = repo,
        super(const ChatState()) {
    _init();
  }

  Future<void> _init() async {
    if (userId.isEmpty) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final sessionId = await _repo.getOrCreateSession(courseId, userId);
      final messages = await _repo.getMessages(sessionId);
      state = state.copyWith(
        sessionId: sessionId,
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Send a message and get AI response.
  Future<void> sendMessage(String message) async {
    if (state.sessionId == null) return;

    // Add user message optimistically
    final userMsg = ChatMessageModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: state.sessionId!,
      role: 'user',
      content: message,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      // Build history for context
      final history = state.messages
          .where((m) => m.id != userMsg.id)
          .take(10)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final aiResponse = await _repo.sendMessage(
        courseId: courseId,
        sessionId: state.sessionId!,
        message: message,
        history: history,
      );

      state = state.copyWith(
        messages: [...state.messages, aiResponse],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider family for chat state per course.
final chatMessagesProvider = StateNotifierProvider.autoDispose
    .family<ChatMessagesNotifier, ChatState, String>((ref, courseId) {
  final user = ref.watch(currentUserProvider);
  return ChatMessagesNotifier(
    repo: ref.watch(chatRepositoryProvider),
    courseId: courseId,
    userId: user?.id ?? '',
  );
});
