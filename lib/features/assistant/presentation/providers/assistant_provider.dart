import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/data/models/chat_message_model.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../data/assistant_repository.dart';
import '../../data/models/assistant_insight_model.dart';

/// Provider for the assistant repository.
final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(supabaseFunctionsProvider),
  );
});

/// Provider for the home screen AI insight card.
final assistantInsightProvider =
    FutureProvider.autoDispose<AssistantInsightModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  try {
    return await ref.watch(assistantRepositoryProvider).getInsight();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[AssistantInsight] Error fetching insight: $e');
    }
    return null; // Insight card won't show, but error is logged
  }
});

/// StateNotifier for the global AI chat (not tied to any course).
class GlobalChatNotifier extends StateNotifier<ChatState> {
  final AssistantRepository _repo;
  final String userId;

  GlobalChatNotifier({
    required AssistantRepository repo,
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
      final sessionId = await _repo.getOrCreateGlobalSession(userId);
      final messages = await _repo.getMessages(sessionId);
      state = state.copyWith(
        sessionId: sessionId,
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: AppErrorHandler.friendlyMessage(e));
    }
  }

  /// Send a message to the global assistant.
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
    SoundService.playMessageSent();

    try {
      // Build history for context
      final history = state.messages
          .where((m) => m.id != userMsg.id)
          .take(10)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final aiResponse = await _repo.sendGlobalMessage(
        sessionId: state.sessionId!,
        message: message,
        history: history,
      );

      state = state.copyWith(
        messages: [...state.messages, aiResponse],
        isLoading: false,
      );
      SoundService.playMessageReceived();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: AppErrorHandler.friendlyMessage(e));
    }
  }
}

/// Provider for the global chat state.
final globalChatProvider =
    StateNotifierProvider.autoDispose<GlobalChatNotifier, ChatState>((ref) {
  final user = ref.watch(currentUserProvider);
  return GlobalChatNotifier(
    repo: ref.watch(assistantRepositoryProvider),
    userId: user?.id ?? '',
  );
});
