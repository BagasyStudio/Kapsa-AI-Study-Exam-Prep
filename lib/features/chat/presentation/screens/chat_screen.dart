import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/generation_provider.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../widgets/oracle_header.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/user_message_bubble.dart';
import '../widgets/citation_chip.dart';
import '../widgets/suggestion_chips_row.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/action_card_parser.dart';
import '../widgets/animated_orb_avatar.dart';
import '../widgets/inline_quiz_widget.dart';
import '../widgets/chat_preferences_sheet.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/widgets/typing_indicator.dart';
import '../../../../core/widgets/message_bubble_entrance.dart';
import '../../../../core/widgets/floating_orbs.dart';
import '../providers/chat_provider.dart';
import '../providers/inline_quiz_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

List<SuggestionItem> _defaultSuggestions(AppLocalizations l) => [
  SuggestionItem(icon: Icons.menu_book, label: l.chatSuggestStudyToday),
  SuggestionItem(icon: Icons.bar_chart, label: l.chatSuggestProgress),
  SuggestionItem(icon: Icons.psychology, label: l.chatSuggestWeakest),
  SuggestionItem(icon: Icons.quiz, label: l.chatSuggestQuiz),
  SuggestionItem(icon: Icons.summarize, label: l.chatSuggestSummarize),
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

  // ── Chat-to-Exercise Bridge Handlers (#84) ──────────────────────────────

  /// Trigger background flashcard generation for this course.
  void _bridgeAddToFlashcards() {
    HapticFeedback.mediumImpact();
    final course = ref.read(courseProvider(widget.courseId)).valueOrNull;
    final courseName = course?.displayTitle ?? 'Course';
    final started = ref
        .read(generationProvider.notifier)
        .generateFlashcards(widget.courseId, courseName);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          started
              ? 'Generating flashcards...'
              : 'Flashcard generation already in progress',
        ),
      ),
    );
  }

  /// Navigate to exercises for this course.
  void _bridgePracticeExercise(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.push(Routes.exercisePath(widget.courseId, 'fillBlanks'));
  }

  /// Trigger background quiz generation for this course.
  void _bridgeGenerateQuiz() {
    HapticFeedback.mediumImpact();
    final course = ref.read(courseProvider(widget.courseId)).valueOrNull;
    final courseName = course?.displayTitle ?? 'Course';
    final started = ref
        .read(generationProvider.notifier)
        .generateQuiz(widget.courseId, courseName);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          started
              ? 'Generating quiz...'
              : 'Quiz generation already in progress',
        ),
      ),
    );
  }

  void _showChatHistorySheet() {
    HapticFeedback.mediumImpact();
    final chatState = ref.read(chatMessagesProvider(widget.courseId));
    final messages = chatState.messages;
    final pinnedIds = chatState.pinnedMessageIds;
    final pinnedMessages = messages.where((m) => pinnedIds.contains(m.id)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.immersiveCard,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusSheet,
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title row
              Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Chat History',
                    style: AppTypography.h3.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Message count info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.immersiveSurface,
                  borderRadius: AppRadius.borderRadiusMd,
                  border: Border.all(color: AppColors.immersiveBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${messages.length} messages',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'in this conversation',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pinnedMessages.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${pinnedMessages.length}',
                              style: AppTypography.labelSmall.copyWith(
                                color: const Color(0xFFF59E0B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Pinned messages section
              if (pinnedMessages.isNotEmpty) ...[
                Text(
                  'PINNED MESSAGES',
                  style: AppTypography.sectionHeader.copyWith(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...pinnedMessages.take(5).map((msg) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                      borderRadius: AppRadius.borderRadiusMd,
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          msg.isUser
                              ? Icons.person_outline_rounded
                              : Icons.auto_awesome_rounded,
                          size: 16,
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            msg.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (msg.timestamp != null)
                          Text(
                            msg.timestamp!,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white24,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: AppSpacing.md),
              ],

              // Clear chat button
              TapScale(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showClearChatConfirmation();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: AppRadius.borderRadiusMd,
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Clear Chat',
                        style: AppTypography.labelLarge.copyWith(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Tip about pinning
              Center(
                child: Text(
                  'Long-press any message to pin it',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white24,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.immersiveCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Clear Chat',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        content: Text(
          'This will permanently delete all messages in this conversation. Are you sure?',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(chatMessagesProvider(widget.courseId).notifier)
                  .clearMessages();
              HapticFeedback.mediumImpact();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat cleared')),
                );
              }
            },
            child: Text(
              'Clear',
              style: AppTypography.labelLarge.copyWith(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMessageLongPress(String messageId) {
    HapticFeedback.mediumImpact();
    final chatState = ref.read(chatMessagesProvider(widget.courseId));
    final isPinned = chatState.pinnedMessageIds.contains(messageId);
    ref.read(chatMessagesProvider(widget.courseId).notifier).togglePin(messageId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPinned ? 'Message unpinned' : 'Message pinned'),
        duration: const Duration(seconds: 1),
      ),
    );
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
                  courseLabel: AppLocalizations.of(context)!.chatAiOracle,
                  onBack: () => Navigator.of(context).pop(),
                  onHistory: () => _showChatHistorySheet(),
                  onSettings: () {
                    showChatPreferencesSheet(context);
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

                                final isPinned = chatState
                                    .pinnedMessageIds
                                    .contains(msg.id);

                                return MessageBubbleEntrance(
                                  fromLeft: !msg.isUser,
                                  child: GestureDetector(
                                    onLongPress: () =>
                                        _handleMessageLongPress(
                                            msg.id),
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        bottom: bottomSpacing,
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          msg.isUser
                                              ? UserMessageBubble(
                                                  text: msg.content,
                                                  timestamp:
                                                      msg.timestamp,
                                                  isLastInGroup:
                                                      isLastInGroup,
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
                                            // ── Chat-to-Exercise Bridge (#84) ──
                                            // Show action chips only on the very last AI message
                                            showActionBridge: !msg.isUser &&
                                                realIndex ==
                                                    messages.length - 1 &&
                                                !chatState.isLoading,
                                            onAddToFlashcards: () =>
                                                _bridgeAddToFlashcards(),
                                            onPracticeExercise: () =>
                                                _bridgePracticeExercise(
                                                    context),
                                            onGenerateQuiz: () =>
                                                _bridgeGenerateQuiz(),
                                            // Show follow-up suggestions on the very last AI message
                                            followUpSuggestions:
                                                (!msg.isUser &&
                                                        realIndex ==
                                                            messages.length -
                                                                1 &&
                                                        !chatState.isLoading)
                                                    ? [
                                                        AppLocalizations.of(context)!.chatFollowUpExample,
                                                        AppLocalizations.of(context)!.chatFollowUpSimpler,
                                                        AppLocalizations.of(context)!.chatFollowUpRelated,
                                                      ]
                                                    : null,
                                            onFollowUpTap: (suggestion) {
                                              _textController.text = suggestion;
                                              _sendMessage();
                                            },
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
                                          // Pin indicator
                                          if (isPinned)
                                            Positioned(
                                              top: -4,
                                              right: msg.isUser
                                                  ? null
                                                  : -4,
                                              left: msg.isUser
                                                  ? -4
                                                  : null,
                                              child: Container(
                                                width: 20,
                                                height: 20,
                                                decoration:
                                                    BoxDecoration(
                                                  shape:
                                                      BoxShape.circle,
                                                  color: const Color(
                                                      0xFFF59E0B),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xFFF59E0B)
                                                          .withValues(
                                                              alpha:
                                                                  0.4),
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.star_rounded,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
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
                    items: _defaultSuggestions(AppLocalizations.of(context)!),
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
                  autoFocus: true,
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
              AppLocalizations.of(context)!.chatStudyCompanion,
              style: AppTypography.h3.copyWith(
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.chatStudyCompanionSub,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white38,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SuggestionChipsRow(
              items: _defaultSuggestions(AppLocalizations.of(context)!),
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
