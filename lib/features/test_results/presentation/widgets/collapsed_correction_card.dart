import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A compact, collapsed version of a correction card (light mode).
///
/// Shows question number badge, truncated question, and a correct/wrong
/// indicator. Taps expand to show the full [CorrectionCard].
/// Matches mockup: glass-card { white/45, blur 16, border white/50 }.
class CollapsedCorrectionCard extends StatelessWidget {
  final int questionNumber;
  final String question;
  final bool isCorrect;
  final VoidCallback? onTap;

  const CollapsedCorrectionCard({
    super.key,
    required this.questionNumber,
    required this.question,
    this.isCorrect = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.borderRadiusLg,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: AppRadius.borderRadiusLg,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: badge + bookmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Question $questionNumber',
                        style: AppTypography.caption.copyWith(
                          color: isCorrect
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.bookmark_border,
                      color: const Color(0xFFCBD5E1),
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Question text
                Text(
                  question,
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF64748B), // slate-500
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                if (!isCorrect) ...[
                  const SizedBox(height: AppSpacing.xs),
                  // Brief answer summary for wrong answers
                  Row(
                    children: [
                      Text(
                        'Your answer',
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFFF87171), // red-400
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 10,
                        color: const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Correct answer',
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFF22C55E), // green-500
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
