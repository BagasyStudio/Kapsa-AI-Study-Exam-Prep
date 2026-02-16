import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/widgets/typing_indicator.dart';
import '../../../../core/widgets/message_bubble_entrance.dart';
import '../../../../core/widgets/floating_orbs.dart';
import '../../../chat/presentation/widgets/oracle_header.dart';
import '../../../chat/presentation/widgets/ai_message_bubble.dart';
import '../../../chat/presentation/widgets/user_message_bubble.dart';
import '../../../chat/presentation/widgets/citation_chip.dart';
import '../../../chat/presentation/widgets/suggestion_chips_row.dart';
import '../../../chat/presentation/widgets/chat_input_bar.dart';
import '../providers/assistant_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

const _globalSuggestions = [
  'What should I study today?',
  'How am I doing overall?',
  'Plan my week',
];

/// Full-screen chat with The Oracle (global AI assistant).
///
/// Similar to [ChatScreen] but uses the global chat provider
/// which knows about ALL user data across courses.
class GlobalChatScreen extends ConsumerStatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  ConsumerState<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends ConsumerState<GlobalChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Check feature access before sending
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'oracle',
      context: context,
    );
    if (!canUse) return;

    _textController.clear();
    ref.read(globalChatProvider.notifier).sendMessage(text);
    _scrollToBottom();

    // Record usage after successful send
    await recordFeatureUsage(ref: ref, feature: 'oracle');
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(globalChatProvider);
    final messages = chatState.messages;

    // Auto-scroll when new messages arrive
    if (messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Animated ambient orbs
          const Positioned.fill(
            child: FloatingOrbs(),
          ),

          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Oracle header
                OracleHeader(
                  courseLabel: 'The Oracle',
                  onBack: () => Navigator.of(context).pop(),
                  onSettings: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Chat settings coming soon')),
                    );
                  },
                ),

                // Messages list
                Expanded(
                  child: chatState.isLoading && messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : messages.isEmpty
                          ? _EmptyGlobalChatState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.sm,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              itemCount: messages.length +
                                  1 +
                                  (chatState.isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Date separator first
                                if (index == 0) {
                                  return EntranceAnimation(
                                    index: 0,
                                    child: Center(
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: AppSpacing.xxl,
                                          top: AppSpacing.sm,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.3),
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Text(
                                          'Today',
                                          style:
                                              AppTypography.caption.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                // Typing indicator at the end
                                if (chatState.isLoading &&
                                    index == messages.length + 1) {
                                  return _TypingIndicator();
                                }

                                final msg = messages[index - 1];
                                return MessageBubbleEntrance(
                                  fromLeft: !msg.isUser,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.xxl,
                                    ),
                                    child: msg.isUser
                                        ? UserMessageBubble(
                                            text: msg.content,
                                            timestamp: msg.timestamp,
                                          )
                                        : AiMessageBubble(
                                            text: msg.content,
                                            timestamp: msg.timestamp,
                                            trailing:
                                                msg.citations.isNotEmpty
                                                    ? Wrap(
                                                        spacing: 6,
                                                        runSpacing: 6,
                                                        children: msg
                                                            .citations
                                                            .map((c) =>
                                                                CitationChip(
                                                                    label: c))
                                                            .toList(),
                                                      )
                                                    : null,
                                          ),
                                  ),
                                );
                              },
                            ),
                ),

                // Error message
                if (chatState.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Text(
                      chatState.error!,
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),

                // Suggestion chips
                SuggestionChipsRow(
                  suggestions: _globalSuggestions,
                  onTap: (suggestion) {
                    _textController.text = suggestion;
                  },
                ),

                const SizedBox(height: AppSpacing.xs),

                // Input bar
                ChatInputBar(
                  controller: _textController,
                  onSend: _sendMessage,
                  onMic: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Voice input coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGlobalChatState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 32,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'The Oracle knows you',
              style:
                  AppTypography.h3.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'I know your courses, scores, weak areas, and upcoming exams. Ask me anything about your studies!',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MessageBubbleEntrance(
      fromLeft: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            child: const TypingIndicator(),
          ),
        ),
      ),
    );
  }
}
