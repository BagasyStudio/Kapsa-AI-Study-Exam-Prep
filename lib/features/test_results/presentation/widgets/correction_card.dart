import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Expanded correction card showing the full question, user's answer,
/// correct answer, and AI insight (light mode).
///
/// Used in the Test Results screen for detailed review.
/// Matches mockup: glass-card { white/45, blur 16, border white/50 }.
class CorrectionCard extends StatelessWidget {
  final int questionNumber;
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final String aiInsight;
  final bool isCorrect;

  const CorrectionCard({
    super.key,
    required this.questionNumber,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.aiInsight,
    this.isCorrect = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderRadiusXl,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: AppRadius.borderRadiusXl,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question header with badge + bookmark
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Question number badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? const Color(0xFFDCFCE7) // green-100
                          : const Color(0xFFFEE2E2), // red-100
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Question $questionNumber',
                      style: AppTypography.caption.copyWith(
                        color: isCorrect
                            ? const Color(0xFF16A34A) // green-600
                            : const Color(0xFFDC2626), // red-600
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.bookmark_border,
                    color: const Color(0xFFCBD5E1), // slate-300
                    size: 20,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Question text
              Text(
                question,
                style: AppTypography.bodyMedium.copyWith(
                  color: const Color(0xFF64748B), // slate-500
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Your answer
              _AnswerRow(
                label: 'YOUR ANSWER',
                answer: userAnswer,
                isCorrect: isCorrect,
                showStrikethrough: !isCorrect,
              ),

              if (!isCorrect) ...[
                const SizedBox(height: AppSpacing.sm),

                // Correct answer
                _AnswerRow(
                  label: 'CORRECT ANSWER',
                  answer: correctAnswer,
                  isCorrect: true,
                  showStrikethrough: false,
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // AI Insight
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.05),
                      AppColors.primary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: AppRadius.borderRadiusMd,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI icon circle
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        aiInsight,
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFF475569), // slate-700 (light)
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String answer;
  final bool isCorrect;
  final bool showStrikethrough;

  const _AnswerRow({
    required this.label,
    required this.answer,
    required this.isCorrect,
    this.showStrikethrough = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF22C55E) : const Color(0xFFF87171);
    final bgColor = isCorrect
        ? const Color(0xFFF0FDF4).withValues(alpha: 0.5) // green-50/50
        : const Color(0xFFFEF2F2).withValues(alpha: 0.5); // red-50/50
    final borderColor = isCorrect
        ? const Color(0xFFDCFCE7) // green-100
        : const Color(0xFFFEE2E2); // red-100

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.check : Icons.close,
            size: 18,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  answer,
                  style: AppTypography.bodySmall.copyWith(
                    color: showStrikethrough
                        ? const Color(0xFF475569)
                        : const Color(0xFF1E293B),
                    fontWeight: showStrikethrough
                        ? FontWeight.w400
                        : FontWeight.w500,
                    decoration: showStrikethrough
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: color.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
