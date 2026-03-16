import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/oracle_header.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/user_message_bubble.dart';
import '../widgets/citation_chip.dart';
import '../widgets/suggestion_chips_row.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/action_card_parser.dart';
import '../widgets/animated_orb_avatar.dart';
import '../widgets/inline_quiz_widget.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/widgets/typing_indicator.dart';
import '../../../../core/widgets/message_bubble_entrance.dart';
import '../../../../core/widgets/floating_orbs.dart';
import '../providers/chat_provider.dart';
import '../providers/inline_quiz_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

const _defaultSuggestions = [
  SuggestionItem(icon: Icons.menu_book, label: 'What should I study today?'),
  SuggestionItem(icon: Icons.bar_chart, label: 'How am I doing overall?'),
  SuggestionItem(icon: Icons.psychology, label: 'Explain my weakest topic'),
  SuggestionItem(icon: Icons.quiz, label: 'Quiz me on this'),
  SuggestionItem(icon: Icons.summarize, label: 'Summarize the material'),
];

class ChatScreen extends ConsumerStatefulWidget {
  final String courseId;

  const ChatScreen({super.key, required this.courseId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
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
      feature: 'chat',
      context: context,
    );
    if (!canUse || !mounted) return;

    _textController.clear();
    ref.read(chatMessagesProvider(widget.courseId).notifier).sendMessage(text);
    _scrollToBottom();

    // Record usage after successful send
    await recordFeatureUsage(ref: ref, feature: 'chat');
  }

  void _handleActionTap(BuildContext context, ActionType actionType) {
    switch (actionType) {
      case ActionType.flashcards:
        context.push(Routes.srsReviewPath(widget.courseId));
        break;
      case ActionType.practice:
        ref
            .read(inlineQuizProvider(widget.courseId).notifier)
            .startQuiz();
        _scrollToBottom();
        break;
      case ActionType.upload:
        context.push(Routes.courseDetailPath(widget.courseId));
        break;
      case ActionType.results:
        context.push(Routes.courseDetailPath(widget.courseId));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatMessagesProvider(widget.courseId));
    final messages = chatState.messages;
    final quizState = ref.watch(inlineQuizProvider(widget.courseId));
    final quizActive = quizState.phase != InlineQuizPhase.idle;

    // Auto-scroll when new messages arrive
    if (messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
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
                  courseLabel: 'AI Oracle',
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
                          ? _EmptyChatState(
                              textController: _textController,
                            )
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
                                  (chatState.isLoading ? 1 : 0) +
                                  (quizActive ? 1 : 0),
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
                                          color: AppColors.immersiveSurface,
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          border: Border.all(
                                            color: AppColors.immersiveBorder,
                                          ),
                                        ),
                                        child: Text(
                                          'Today',
                                          style:
                                              AppTypography.caption.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                // Inline quiz widget after messages
                                final quizSlotIndex = messages.length + 1;
                                if (quizActive && index == quizSlotIndex) {
                                  return InlineQuizWidget(
                                    courseId: widget.courseId,
                                    onScrollToBottom: _scrollToBottom,
                                  );
                                }

                                // Typing indicator at the end
                                final typingIndex = quizSlotIndex +
                                    (quizActive ? 1 : 0);
                                if (chatState.isLoading &&
                                    index == typingIndex) {
                                  return const _TypingIndicator();
                                }

                                // Message grouping logic
                                final realIndex = index - 1;
                                final msg = messages[realIndex];
                                final prevMsg = realIndex > 0
                                    ? messages[realIndex - 1]
                                    : null;
                                final nextMsg =
                                    realIndex < messages.length - 1
                                        ? messages[realIndex + 1]
                                        : null;
                                final isFirstInGroup = prevMsg == null ||
                                    prevMsg.isUser != msg.isUser;
                                final isLastInGroup = nextMsg == null ||
                                    nextMsg.isUser != msg.isUser;

                                // Spacing logic
                                final double bottomSpacing;
                                if (nextMsg == null) {
                                  // Truly last message
                                  bottomSpacing = AppSpacing.xxl;
                                } else if (isLastInGroup) {
                                  // Inter-group (different sender next)
                                  bottomSpacing = AppSpacing.md;
                                } else {
                                  // Intra-group (same sender consecutive)
                                  bottomSpacing = AppSpacing.xs;
                                }

                                return MessageBubbleEntrance(
                                  fromLeft: !msg.isUser,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: bottomSpacing,
                                    ),
                                    child: msg.isUser
                                        ? UserMessageBubble(
                                            text: msg.content,
                                            timestamp: msg.timestamp,
                                            isLastInGroup: isLastInGroup,
                                          )
                                        : AiMessageBubble(
                                            text: msg.content,
                                            timestamp: msg.timestamp,
                                            showAvatar: isFirstInGroup,
                                            isLastInGroup: isLastInGroup,
                                            actionCards:
                                                ActionCardsFromMessage(
                                              messageText: msg.content,
                                              onActionTap: (actionType) =>
                                                  _handleActionTap(
                                                      context, actionType),
                                            ),
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
                        color: AppColors.error,
                      ),
                    ),
                  ),

                // Suggestion chips: only show inline row when messages exist
                if (messages.isNotEmpty)
                  SuggestionChipsRow(
                    items: _defaultSuggestions,
                    onTap: (suggestion) {
                      _textController.text = suggestion;
                    },
                  ),

                const SizedBox(height: AppSpacing.xs),

                // Input bar (disabled during active quiz)
                ChatInputBar(
                  controller: _textController,
                  onSend: quizActive ? null : _sendMessage,
                  isLoading: chatState.isLoading || quizActive,
                  onStop: quizActive
                      ? () => ref
                          .read(inlineQuizProvider(widget.courseId).notifier)
                          .reset()
                      : () {
                          // For now, no-op -- future: cancel streaming
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

/// Empty state with hero section: orb avatar, title, description,
/// and suggestion chips in grid mode.
class _EmptyChatState extends StatelessWidget {
  final TextEditingController textController;

  const _EmptyChatState({required this.textController});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AnimatedOrbAvatar(size: 72),
            const SizedBox(height: 20),
            Text(
              'Your AI study companion',
              style: AppTypography.h3.copyWith(
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask questions, get explanations, and ace your exams.',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white38,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SuggestionChipsRow(
              items: _defaultSuggestions,
              showAsGrid: true,
              onTap: (suggestion) {
                textController.text = suggestion;
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Typing indicator bubble with forced dark styling.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

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
              color: AppColors.immersiveCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: const TypingIndicator(),
          ),
        ),
      ),
    );
  }
}
