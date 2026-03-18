import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
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
import '../../../chat/presentation/widgets/action_card_parser.dart';
import '../../../chat/presentation/widgets/animated_orb_avatar.dart';
import '../../../chat/presentation/widgets/chat_preferences_sheet.dart';
import '../providers/assistant_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

List<SuggestionItem> _globalSuggestions(AppLocalizations l) => [
  SuggestionItem(icon: Icons.menu_book, label: l.chatSuggestStudyToday),
  SuggestionItem(icon: Icons.bar_chart, label: l.chatSuggestProgress),
  SuggestionItem(icon: Icons.psychology, label: l.chatSuggestWeakest),
  SuggestionItem(icon: Icons.quiz, label: l.chatSuggestQuiz),
  SuggestionItem(icon: Icons.summarize, label: l.chatSuggestSummarize),
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

  void _handleActionTap(BuildContext context, ActionType actionType) {
    switch (actionType) {
      case ActionType.flashcards:
        // Global chat has no courseId — navigate to courses list
        // so user can pick a course to review flashcards
        context.push(Routes.courses);
        break;
      case ActionType.practice:
        context.push(Routes.practiceExam);
        break;
      case ActionType.upload:
        context.push(Routes.courses);
        break;
      case ActionType.results:
        context.push(Routes.home);
        break;
    }
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
                  courseLabel: AppLocalizations.of(context)!.chatTheOracle,
                  onBack: () => Navigator.of(context).pop(),
                  onSettings: () {
                    showChatPreferencesSheet(context);
                  },
                ),

                // Messages list
                Expanded(
                  child: chatState.isLoading && messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : messages.isEmpty
                          ? _EmptyGlobalChatState(
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
                                          color: AppColors.immersiveSurface
                                              .withValues(alpha: 0.6),
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          border: Border.all(
                                            color: AppColors.immersiveSurface
                                                .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!.chatToday,
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

                                // Typing indicator at the end
                                if (chatState.isLoading &&
                                    index == messages.length + 1) {
                                  return const _ThinkingIndicator();
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
                    items: _globalSuggestions(AppLocalizations.of(context)!),
                    onTap: (suggestion) {
                      _textController.text = suggestion;
                    },
                  ),

                const SizedBox(height: AppSpacing.xs),

                // Input bar
                ChatInputBar(
                  controller: _textController,
                  onSend: _sendMessage,
                  isLoading: chatState.isLoading,
                  autoFocus: true,
                  onStop: () {
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
class _EmptyGlobalChatState extends StatelessWidget {
  final TextEditingController textController;

  const _EmptyGlobalChatState({required this.textController});

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
              AppLocalizations.of(context)!.chatOracleKnows,
              style: AppTypography.h3.copyWith(
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.chatOracleKnowsSub,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white38,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SuggestionChipsRow(
              items: _globalSuggestions(AppLocalizations.of(context)!),
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

/// Enhanced thinking indicator with pulsing glow animation.
class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator();

  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.08, end: 0.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MessageBubbleEntrance(
      fromLeft: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
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
                    color: AppColors.primary
                        .withValues(alpha: _pulseAnimation.value),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: _pulseAnimation.value * 0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const TypingIndicator(),
              );
            },
          ),
        ),
      ),
    );
  }
}
