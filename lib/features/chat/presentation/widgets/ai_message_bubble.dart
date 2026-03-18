import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/markdown_math_builder.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/services/tts_service.dart';

/// AI message bubble with solid background, left accent border, and avatar support.
///
/// Displays a clean bubble aligned to the left side with an optional avatar orb,
/// left accent border, and grouped timestamp support.
/// Renders AI responses as markdown for rich formatting.
/// Supports inline action cards for tappable actions detected in the message.
/// Includes a TTS play/stop button and optional follow-up suggestion chips.
/// Shows a confidence indicator based on response length.
/// Optionally shows action bridge chips (flashcards / exercise / quiz) on the last AI message.
class AiMessageBubble extends StatefulWidget {
  final String text;
  final String? timestamp;
  final Widget? trailing; // for citation chips below message
  final Widget? actionCards; // for inline tappable action cards
  final bool showAvatar; // show avatar orb to the left
  final bool isLastInGroup; // show timestamp only when last in group
  final List<String>? followUpSuggestions; // follow-up suggestion labels
  final ValueChanged<String>? onFollowUpTap; // callback when a follow-up chip is tapped

  // ── Chat-to-Exercise Bridge (#84) ──
  final bool showActionBridge; // show action chips below AI response
  final VoidCallback? onAddToFlashcards;
  final VoidCallback? onPracticeExercise;
  final VoidCallback? onGenerateQuiz;

  const AiMessageBubble({
    super.key,
    required this.text,
    this.timestamp,
    this.trailing,
    this.actionCards,
    this.showAvatar = false,
    this.isLastInGroup = true,
    this.followUpSuggestions,
    this.onFollowUpTap,
    this.showActionBridge = false,
    this.onAddToFlashcards,
    this.onPracticeExercise,
    this.onGenerateQuiz,
  });

  @override
  State<AiMessageBubble> createState() => _AiMessageBubbleState();
}

class _AiMessageBubbleState extends State<AiMessageBubble>
    with SingleTickerProviderStateMixin {
  bool _isSpeaking = false;
  bool _bridgeVisible = false;

  // Animation controller for bridge chips entrance
  late final AnimationController _bridgeAnimController;
  late final Animation<double> _bridgeOpacity;
  late final Animation<Offset> _bridgeSlide;

  @override
  void initState() {
    super.initState();
    _bridgeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bridgeOpacity = CurvedAnimation(
      parent: _bridgeAnimController,
      curve: Curves.easeOut,
    );
    _bridgeSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bridgeAnimController,
      curve: Curves.easeOutCubic,
    ));

    // Trigger delayed entrance if bridge should be visible
    if (widget.showActionBridge) {
      _scheduleBridgeEntrance();
    }
  }

  @override
  void didUpdateWidget(covariant AiMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showActionBridge && !oldWidget.showActionBridge) {
      _bridgeVisible = false;
      _bridgeAnimController.reset();
      _scheduleBridgeEntrance();
    } else if (!widget.showActionBridge && oldWidget.showActionBridge) {
      _bridgeVisible = false;
      _bridgeAnimController.reset();
    }
  }

  void _scheduleBridgeEntrance() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && widget.showActionBridge) {
        setState(() => _bridgeVisible = true);
        _bridgeAnimController.forward();
      }
    });
  }

  Future<void> _toggleTts() async {
    if (_isSpeaking) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await TtsService.instance.speak(widget.text);
      // After speech completes, reset state
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  @override
  void dispose() {
    _bridgeAnimController.dispose();
    // Stop TTS if this bubble is disposed while speaking
    if (_isSpeaking) {
      TtsService.instance.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bubbleBorderRadius = widget.showAvatar
        ? const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(AppRadius.xl),
            bottomLeft: Radius.circular(AppRadius.xl),
            bottomRight: Radius.circular(AppRadius.xl),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(AppRadius.xl),
          );

    final bubbleWidget = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2040),
        borderRadius: bubbleBorderRadius,
        border: Border(
          left: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MarkdownBody(
            data: widget.text,
            selectable: true,
            shrinkWrap: true,
            inlineSyntaxes: mathInlineSyntaxes(),
            builders: mathBuilders(
              textStyle: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                height: 1.6,
              ),
            ),
            styleSheet: MarkdownStyleSheet(
              p: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                height: 1.6,
              ),
              strong: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.6,
              ),
              em: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
              h1: AppTypography.h3.copyWith(
                color: Colors.white,
              ),
              h2: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              h3: AppTypography.labelLarge.copyWith(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
              listBullet: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
              code: AppTypography.bodySmall.copyWith(
                color: const Color(0xFFFB7185),
                backgroundColor: const Color(0xFF1E293B),
                fontFamily: 'monospace',
              ),
              codeblockDecoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              codeblockPadding: const EdgeInsets.all(12),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 3,
                  ),
                ),
              ),
              blockquotePadding: const EdgeInsets.only(left: 12),
              a: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

          // Inline action cards (rendered inside the bubble)
          if (widget.actionCards != null) widget.actionCards!,

          // ── AI Confidence Indicator (#87) ──
          const SizedBox(height: AppSpacing.xs),
          _ConfidenceDots(text: widget.text),

          // ── TTS play/stop button at bottom-right ──
          const SizedBox(height: AppSpacing.xxs),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _toggleTts,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                  key: ValueKey(_isSpeaking),
                  size: 16,
                  color: _isSpeaking
                      ? AppColors.primary
                      : Colors.white38,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar row or indented bubble
            if (widget.showAvatar)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar orb
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.3),
                        colors: [
                          AppColors.primaryLight,
                          AppColors.primary,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Bubble
                  Expanded(child: bubbleWidget),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 36), // 28 orb + 8 gap
                child: bubbleWidget,
              ),

            // Timestamp (only when last in group)
            if (widget.isLastInGroup && widget.timestamp != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: 36 + AppSpacing.sm, // align with bubble text
                  top: AppSpacing.xxs,
                ),
                child: Text(
                  widget.timestamp!,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ),

            // ── Chat-to-Exercise Bridge (#84) ──
            // Chips animate in after a 500ms delay for a polished entrance
            if (widget.showActionBridge && _bridgeVisible)
              SlideTransition(
                position: _bridgeSlide,
                child: FadeTransition(
                  opacity: _bridgeOpacity,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 36,
                      top: AppSpacing.sm,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _ActionBridgeChip(
                            icon: Icons.style_rounded,
                            label: 'Practice with Flashcards',
                            onTap: widget.onAddToFlashcards,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _ActionBridgeChip(
                            icon: Icons.quiz_rounded,
                            label: 'Take a Quiz',
                            onTap: widget.onGenerateQuiz,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _ActionBridgeChip(
                            icon: Icons.fitness_center_rounded,
                            label: 'Try Exercises',
                            onTap: widget.onPracticeExercise,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Follow-up suggestion chips (shown below the last AI message in group)
            if (widget.isLastInGroup &&
                widget.followUpSuggestions != null &&
                widget.followUpSuggestions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: 36,
                  top: AppSpacing.sm,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: widget.followUpSuggestions!.map((suggestion) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: _FollowUpChip(
                          label: suggestion,
                          onTap: () => widget.onFollowUpTap?.call(suggestion),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Trailing widget (citations, etc.)
            if (widget.trailing != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: 36,
                  top: AppSpacing.xs,
                ),
                child: widget.trailing!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Glass-style follow-up suggestion chip.
class _FollowUpChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _FollowUpChip({
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AI Confidence Indicator (#87)
// ═══════════════════════════════════════════════════════════════════════════════

/// Row of 5 small dots indicating AI confidence based on response length.
///
/// - Short responses (<50 words): 3/5
/// - Normal responses (50-200 words): 4/5
/// - Long detailed responses (>200 words): 5/5
class _ConfidenceDots extends StatelessWidget {
  final String text;

  const _ConfidenceDots({required this.text});

  int get _filledCount {
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount > 200) return 5;
    if (wordCount < 50) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final filled = _filledCount;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final isFilled = i < filled;
        return Padding(
          padding: EdgeInsets.only(right: i < 4 ? 3.0 : 0),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? AppColors.primary : Colors.white12,
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Chat-to-Exercise Bridge Action Chip (#84)
// ═══════════════════════════════════════════════════════════════════════════════

/// Tappable action chip shown below the last AI response for quick study actions.
///
/// Uses [TapScale] for a tactile press animation and [HapticFeedback] on tap.
/// Displays an icon + label in a pill-shaped container styled with
/// the app's primary color palette.
class _ActionBridgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionBridgeChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
