import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/oracle_header.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/user_message_bubble.dart';
import '../widgets/citation_chip.dart';
import '../widgets/suggestion_chips_row.dart';
import '../widgets/chat_input_bar.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../providers/chat_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

const _defaultSuggestions = [
  'Explain the key concepts',
  'Quiz me on this',
  'Summarize the material',
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
    if (!canUse) return;

    _textController.clear();
    ref.read(chatMessagesProvider(widget.courseId).notifier).sendMessage(text);
    _scrollToBottom();

    // Record usage after successful send
    await recordFeatureUsage(ref: ref, feature: 'chat');
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatMessagesProvider(widget.courseId));
    final messages = chatState.messages;

    // Auto-scroll when new messages arrive
    if (messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Ambient decorative blobs
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD8B4FE).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: MediaQuery.of(context).size.width * 0.3,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBFDBFE).withValues(alpha: 0.2),
              ),
            ),
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
                          ? _EmptyChatState()
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
                                return EntranceAnimation(
                                  index: index,
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
                      'Error: ${chatState.error}',
                      style:
                          AppTypography.caption.copyWith(color: Colors.red),
                    ),
                  ),

                // Suggestion chips
                SuggestionChipsRow(
                  suggestions: _defaultSuggestions,
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

class _EmptyChatState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ask me anything about your course',
              style:
                  AppTypography.h3.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'I can explain concepts, create quizzes, and help you study more effectively.',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: AiMessageBubble(
        text: 'Thinking...',
        timestamp: null,
      ),
    );
  }
}
