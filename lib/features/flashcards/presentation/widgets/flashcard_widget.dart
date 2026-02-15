import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A single flashcard face (question or answer).
///
/// White card with paper grain texture, topic chip, question text
/// with gradient keyword, and "Tap to reveal" hint.
class FlashcardWidget extends StatelessWidget {
  final String topic;
  final String questionBefore; // text before highlighted keyword
  final String keyword; // highlighted in gradient
  final String questionAfter; // text after highlighted keyword
  final String? answer;
  final bool isRevealed;
  final bool isBookmarked;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;

  const FlashcardWidget({
    super.key,
    required this.topic,
    required this.questionBefore,
    required this.keyword,
    required this.questionAfter,
    this.answer,
    this.isRevealed = false,
    this.isBookmarked = false,
    this.onTap,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFB),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Paper grain texture overlay (subtle noise)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: CustomPaint(
                  painter: _PaperGrainPainter(),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top: topic chip + bookmark
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
                          color: AppColors.primary.withValues(alpha: 0.1),
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
                              topic.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bookmark
                      GestureDetector(
                        onTap: onBookmark,
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: isBookmarked
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  // Center: question or answer
                  Expanded(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isRevealed
                            ? _AnswerContent(answer: answer ?? '')
                            : _QuestionContent(
                                before: questionBefore,
                                keyword: keyword,
                                after: questionAfter,
                              ),
                      ),
                    ),
                  ),

                  // Bottom: hint
                  if (!isRevealed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TAP TO REVEAL',
                          style: AppTypography.labelSmall.copyWith(
                            letterSpacing: 2,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Question text with gradient highlighted keyword.
class _QuestionContent extends StatelessWidget {
  final String before;
  final String keyword;
  final String after;

  const _QuestionContent({
    required this.before,
    required this.keyword,
    required this.after,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.h2.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
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
            color: const Color(0xFFE5E7EB),
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

  const _AnswerContent({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Text(
      answer,
      textAlign: TextAlign.center,
      style: AppTypography.bodyLarge.copyWith(
        fontSize: 18,
        height: 1.6,
        color: const Color(0xFF374151),
      ),
    );
  }
}

/// Subtle paper grain texture using a CustomPainter.
class _PaperGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Very subtle noise dots
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.02)
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
