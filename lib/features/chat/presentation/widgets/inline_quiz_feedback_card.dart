import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Premium compact feedback card shown after answering a quiz question.
///
/// Green for correct, red for incorrect. Shows user's answer,
/// the correct answer (if wrong), and an optional AI insight.
class InlineQuizFeedbackCard extends StatelessWidget {
  final bool isCorrect;
  final String userAnswer;
  final String correctAnswer;
  final String? aiInsight;

  const InlineQuizFeedbackCard({
    super.key,
    required this.isCorrect,
    required this.userAnswer,
    required this.correctAnswer,
    this.aiInsight,
  });

  static const _successColor = Color(0xFF10B981);
  static const _errorColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? _successColor : _errorColor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result header
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Incorrect',
                style: AppTypography.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // User's answer
          _AnswerRow(
            label: 'Your answer',
            answer: userAnswer,
            color: color,
          ),

          // Correct answer (only if wrong)
          if (!isCorrect) ...[
            const SizedBox(height: 6),
            _AnswerRow(
              label: 'Correct answer',
              answer: correctAnswer,
              color: _successColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String answer;
  final Color color;

  const _AnswerRow({
    required this.label,
    required this.answer,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: AppTypography.caption.copyWith(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            answer,
            style: AppTypography.bodySmall.copyWith(
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact row for results summary — shows icon + question + insight.
class QuizResultRow extends StatelessWidget {
  final int index;
  final bool isCorrect;
  final String question;
  final String? aiInsight;

  const QuizResultRow({
    super.key,
    required this.index,
    required this.isCorrect,
    required this.question,
    this.aiInsight,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect
        ? AppColors.success
        : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check/X icon
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          // Question + insight
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (aiInsight != null && aiInsight!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    aiInsight!,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
