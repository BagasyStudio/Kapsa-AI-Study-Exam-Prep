import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../providers/resume_quiz_provider.dart';

/// Motivational banner shown on the home screen when the user has an
/// in-progress quiz. Tapping it resumes the quiz session.
///
/// Self-hides when no in-progress quizzes exist.
class ResumeQuizBanner extends ConsumerWidget {
  const ResumeQuizBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(inProgressQuizzesProvider);

    return quizzesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (quizzes) {
        if (quizzes.isEmpty) return const SizedBox.shrink();

        // Show only the most recent in-progress quiz
        final quiz = quizzes.first;
        return _ResumeCard(quiz: quiz);
      },
    );
  }
}

class _ResumeCard extends StatelessWidget {
  final InProgressQuiz quiz;

  const _ResumeCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = Theme.of(context).brightness;

    const accentColor = Color(0xFF10B981); // emerald green

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm,
        ),
        child: TapScale(
          onTap: () => context.push(Routes.quizSessionPath(quiz.test.id)),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: isDark ? 0.12 : 0.10),
                  accentColor.withValues(alpha: isDark ? 0.06 : 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.20 : 0.15),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Progress ring with quiz icon
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              value: quiz.progress,
                              strokeWidth: 3,
                              backgroundColor: accentColor
                                  .withValues(alpha: isDark ? 0.15 : 0.12),
                              valueColor: const AlwaysStoppedAnimation(
                                accentColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.quiz_rounded,
                            size: 18,
                            color: accentColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continue Quiz',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryFor(brightness),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${quiz.answeredCount}/${quiz.test.totalCount} answered \u2022 ${quiz.courseName}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMutedFor(brightness),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${quiz.motivationText} ${quiz.motivationEmoji}',
                            style: AppTypography.caption.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: accentColor.withValues(alpha: 0.6),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Progress bar
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: quiz.progress),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 3,
                      backgroundColor: accentColor
                          .withValues(alpha: isDark ? 0.10 : 0.08),
                      valueColor: const AlwaysStoppedAnimation(accentColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
