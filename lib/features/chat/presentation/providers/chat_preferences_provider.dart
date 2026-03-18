import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available response style options.
enum ChatResponseStyle { brief, detailed, eli5 }

/// State for chat preferences.
class ChatPreferencesState {
  final ChatResponseStyle responseStyle;
  final bool includeExamples;

  const ChatPreferencesState({
    this.responseStyle = ChatResponseStyle.detailed,
    this.includeExamples = true,
  });

  ChatPreferencesState copyWith({
    ChatResponseStyle? responseStyle,
    bool? includeExamples,
  }) {
    return ChatPreferencesState(
      responseStyle: responseStyle ?? this.responseStyle,
      includeExamples: includeExamples ?? this.includeExamples,
    );
  }
}

/// StateNotifier for managing chat preferences with SharedPreferences persistence.
class ChatPreferencesNotifier extends StateNotifier<ChatPreferencesState> {
  static const _styleKey = 'chat_style';
  static const _examplesKey = 'chat_examples';

  ChatPreferencesNotifier() : super(const ChatPreferencesState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final styleIndex = prefs.getInt(_styleKey) ?? ChatResponseStyle.detailed.index;
    final includeExamples = prefs.getBool(_examplesKey) ?? true;
    state = ChatPreferencesState(
      responseStyle: ChatResponseStyle.values[styleIndex],
      includeExamples: includeExamples,
    );
  }

  Future<void> setResponseStyle(ChatResponseStyle style) async {
    state = state.copyWith(responseStyle: style);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_styleKey, style.index);
  }

  Future<void> setIncludeExamples(bool value) async {
    state = state.copyWith(includeExamples: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_examplesKey, value);
  }
}

/// Provider for chat preferences.
final chatPreferencesProvider =
    StateNotifierProvider<ChatPreferencesNotifier, ChatPreferencesState>((ref) {
  return ChatPreferencesNotifier();
});
