import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/math_text.dart';

/// Lightweight data class for related card previews.
class RelatedCardInfo {
  final String keyword;
  final String questionPreview;

  const RelatedCardInfo({
    required this.keyword,
    required this.questionPreview,
  });
}

/// A single flashcard with 3D flip animation between question and answer faces.
///
/// Card with paper grain texture, topic chip, question text
/// with gradient keyword, and "Tap to reveal" hint.
/// Uses a Y-axis rotation with perspective for a realistic 3D flip effect.
class FlashcardWidget extends StatefulWidget {
  final String topic;
  final String questionBefore; // text before highlighted keyword
  final String keyword; // highlighted in gradient
  final String questionAfter; // text after highlighted keyword
  final String? answer;
  final bool isRevealed;
  final bool isBookmarked;
  final bool isSpeaking;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final VoidCallback? onSpeak;

  /// Optional custom font size for question and answer text.
  /// When null, defaults to 26 for questions and 18 for answers.
  final double? fontSize;

  /// Related cards with the same topic. Shown as a chip on the back side.
  /// Only displayed when non-null and non-empty.
  final List<RelatedCardInfo>? relatedCards;

  const FlashcardWidget({
    super.key,
    required this.topic,
    required this.questionBefore,
    required this.keyword,
    required this.questionAfter,
    this.answer,
    this.isRevealed = false,
    this.isBookmarked = false,
    this.isSpeaking = false,
    this.onTap,
    this.onBookmark,
    this.onSpeak,
    this.fontSize,
    this.relatedCards,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  /// Tracks which face is currently showing so we can swap content
  /// at the midpoint of the flip.
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    // Listen to the animation to swap content at the halfway point.
    _animation.addListener(_handleAnimationProgress);

    // If the widget is created already revealed, snap to the answer face.
    if (widget.isRevealed) {
      _controller.value = 1.0;
      _showAnswer = true;
    }
  }

  @override
  void didUpdateWidget(covariant FlashcardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed != oldWidget.isRevealed) {
      if (widget.isRevealed) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _handleAnimationProgress() {
    // Swap the displayed face at the midpoint of the animation.
    final shouldShowAnswer = _animation.value >= 0.5;
    if (shouldShowAnswer != _showAnswer) {
      setState(() {
        _showAnswer = shouldShowAnswer;
      });
    }
  }

  @override
  void dispose() {
    _animation.removeListener(_handleAnimationProgress);
    _controller.dispose();
    super.dispose();
  }

  void _showRelatedCardsSheet(BuildContext context) {
    final related = widget.relatedCards;
    if (related == null || related.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.immersiveCard,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusSheet,
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Related Cards',
                    style: AppTypography.h4.copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${related.length}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Other cards about "${widget.topic}"',
                style: AppTypography.bodySmall
                    .copyWith(color: Colors.white38),
              ),
              const SizedBox(height: AppSpacing.md),

              // Card list (constrained height)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.35,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: related.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (_, index) {
                    final item = related[index];
                    return GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.immersiveSurface,
                          borderRadius: AppRadius.borderRadiusMd,
                          border:
                              Border.all(color: AppColors.immersiveBorder),
                        ),
                        child: Row(
                          children: [
                            // Keyword badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(100),
                              ),
                              child: Text(
                                item.keyword,
                                style:
                                    AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // Question preview
                            Expanded(
                              child: Text(
                                item.questionPreview,
                                style: AppTypography.bodySmall
                                    .copyWith(color: Colors.white70),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Compute the Y rotation angle.
          // First half  (0.0 -> 0.5): rotate from 0 to pi/2 (0 -> 90 degrees)
          // Second half (0.5 -> 1.0): rotate from -pi/2 to 0 (-90 -> 0 degrees)
          // This creates the illusion that the card flips over smoothly.
          final double angle;
          if (_animation.value <= 0.5) {
            // Question face rotating away: 0 -> 90 degrees
            angle = _animation.value * math.pi;
          } else {
            // Answer face rotating in: -90 -> 0 degrees
            angle = (_animation.value - 1.0) * math.pi;
          }

          // Dynamic shadow: intensity peaks at 45 degrees (animation value 0.25 or 0.75).
          // Use a sine curve mapped to the animation progress for smooth shadow modulation.
          final shadowIntensity =
              0.35 + 0.25 * math.sin(_animation.value * math.pi);

          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(angle);

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.immersiveCard,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: shadowIntensity),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Paper grain texture overlay (subtle noise)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: CustomPaint(
                        painter: _PaperGrainPainter(isDark: true),
                      ),
                    ),
                  ),

                  // Card content
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top: topic chip + bookmark (always visible on both faces)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Topic chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: AppRadius.borderRadiusPill,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.topic.toUpperCase(),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Speaker + Bookmark
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.onSpeak != null)
                                  GestureDetector(
                                    onTap: widget.onSpeak,
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Icon(
                                          widget.isSpeaking
                                              ? Icons.volume_up
                                              : Icons.volume_up_outlined,
                                          key: ValueKey(widget.isSpeaking),
                                          color: widget.isSpeaking
                                              ? AppColors.primary
                                              : Colors.white38,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: widget.onBookmark,
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      widget.isBookmarked
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color: widget.isBookmarked
                                          ? AppColors.primary
                                          : Colors.white38,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Center: question or answer (swaps at flip midpoint)
                        Expanded(
                          child: Center(
                            child: _showAnswer
                                ? _AnswerContent(
                                    answer: widget.answer ?? '',
                                    fontSize: widget.fontSize,
                                  )
                                : _QuestionContent(
                                    before: widget.questionBefore,
                                    keyword: widget.keyword,
                                    after: widget.questionAfter,
                                    fontSize: widget.fontSize,
                                  ),
                          ),
                        ),

                        // Bottom: hint on front, related + web lookup on back
                        if (!_showAnswer)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.immersiveSurface,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'TAP TO REVEAL',
                                  style: AppTypography.labelSmall.copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Related cards button (or empty spacer)
                              if (widget.relatedCards != null &&
                                  widget.relatedCards!.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _showRelatedCardsSheet(context);
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color:
                                            AppColors.primary.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.link_rounded,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Related (${widget.relatedCards!.length})',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),

                              // Web lookup button (only if keyword is non-empty)
                              if (widget.keyword.trim().isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    final query = Uri.encodeComponent(widget.keyword.trim());
                                    launchUrl(
                                      Uri.parse('https://www.google.com/search?q=$query'),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.language,
                                          size: 16,
                                          color: Colors.white54,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Look up',
                                          style: AppTypography.caption.copyWith(
                                            color: Colors.white54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Question text with gradient highlighted keyword.
/// Falls back to MathText if the question contains LaTeX.
class _QuestionContent extends StatelessWidget {
  final String before;
  final String keyword;
  final String after;
  final double? fontSize;

  const _QuestionContent({
    required this.before,
    required this.keyword,
    required this.after,
    this.fontSize,
  });

  static bool _containsMath(String text) {
    return text.contains('\$') &&
        RegExp(
          r'[\\^_{}]|frac|sqrt|sum|int|lim|alpha|beta|gamma|theta|pi|infty',
        ).hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    final fullQuestion = '$before$keyword$after';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_containsMath(fullQuestion))
          MathText(
            text: fullQuestion,
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(
              fontSize: fontSize ?? 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.35,
            ),
          )
        else
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.h2.copyWith(
                fontSize: fontSize ?? 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.35,
              ),
              children: [
                TextSpan(text: before),
                TextSpan(
                  text: keyword,
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF4F46E5)],
                      ).createShader(
                        const Rect.fromLTWH(0, 0, 200, 40),
                      ),
                  ),
                ),
                TextSpan(text: after),
              ],
            ),
          ),
        const SizedBox(height: 24),
        // Decorative divider
        Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: AppRadius.borderRadiusPill,
          ),
        ),
      ],
    );
  }
}

/// Answer content displayed after reveal.
class _AnswerContent extends StatelessWidget {
  final String answer;
  final double? fontSize;

  const _AnswerContent({required this.answer, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return MathText(
      text: answer,
      textAlign: TextAlign.center,
      style: AppTypography.bodyLarge.copyWith(
        fontSize: fontSize ?? 18,
        height: 1.6,
        color: const Color(0xFFCBD5E1),
      ),
    );
  }
}

/// Subtle paper grain texture using a CustomPainter.
class _PaperGrainPainter extends CustomPainter {
  final bool isDark;
  _PaperGrainPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Very subtle noise dots
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.02)
          : Colors.black.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;

    // Simple deterministic "grain" pattern
    for (double x = 0; x < size.width; x += 4) {
      for (double y = 0; y < size.height; y += 4) {
        final hash = (x * 7 + y * 13).toInt() % 5;
        if (hash == 0) {
          canvas.drawCircle(Offset(x, y), 0.5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
