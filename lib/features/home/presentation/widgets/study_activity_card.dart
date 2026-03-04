import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../test_results/data/models/test_model.dart';
import '../../../flashcards/data/models/deck_model.dart';
import '../providers/study_activity_provider.dart';

/// Card shown on the home screen with recent flashcard decks and quiz results.
///
/// Displays the latest study activity, allowing quick access to review.
class StudyActivityCard extends ConsumerWidget {
  const StudyActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(studyActivityProvider);

    return activityAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: ShimmerList(count: 2, itemHeight: 72, spacing: AppSpacing.sm),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (activity) {
        if (activity.decks.isEmpty && activity.tests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school,
                        size: 18,
                        color: AppColors.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text(
                      'Study Activity',
                      style: AppTypography.h4.copyWith(
                        color: AppColors.textPrimaryFor(Theme.of(context).brightness),
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const EmptyState(
                  icon: Icons.school,
                  title: 'No activity yet',
                  subtitle: 'Complete a quiz or review flashcards to see your activity here.',
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                children: [
                  Icon(Icons.school,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'Study Activity',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textPrimaryFor(Theme.of(context).brightness),
                      fontSize: 17,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Recent quizzes
              if (activity.tests.isNotEmpty) ...[
                ...activity.tests.take(2).map((test) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _QuizActivityItem(
                        test: test,
                        courseName: activity.courseNames[test.courseId],
                      ),
                    )),
              ],

              // Recent decks
              if (activity.decks.isNotEmpty) ...[
                ...activity.decks.take(2).map((deck) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _DeckActivityItem(
                        deck: deck,
                        courseName: activity.courseNames[deck.courseId],
                      ),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _QuizActivityItem extends StatelessWidget {
  final TestModel test;
  final String? courseName;

  const _QuizActivityItem({required this.test, this.courseName});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final brightness = Theme.of(context).brightness;
    final score = test.percentage;
    final color = score >= 80
        ? const Color(0xFF22C55E)
        : score >= 60
            ? const Color(0xFF3B82F6)
            : const Color(0xFFEF4444);

    return TapScale(
      onTap: () => context.push(Routes.testResultsPath(test.id)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.5),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Score badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '$score%',
                  style: AppTypography.labelLarge.copyWith(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title ?? 'Quiz',
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimaryFor(brightness),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (courseName != null) courseName!,
                      '${test.correctCount}/${test.totalCount} correct',
                      _timeAgo(test.createdAt),
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(brightness),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz, size: 11, color: const Color(0xFFEC4899)),
                  const SizedBox(width: 3),
                  Text(
                    'Quiz',
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFFEC4899),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class _DeckActivityItem extends StatelessWidget {
  final DeckModel deck;
  final String? courseName;

  const _DeckActivityItem({required this.deck, this.courseName});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final brightness = Theme.of(context).brightness;
    return TapScale(
      onTap: () => context.push(Routes.flashcardSessionPath(deck.id)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.5),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6467F2).withValues(alpha: 0.15),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.style, size: 20, color: Color(0xFF6467F2)),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.title,
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimaryFor(brightness),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (courseName != null) courseName!,
                      '${deck.cardCount} cards',
                      _timeAgo(deck.createdAt),
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(brightness),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF6467F2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.style, size: 11, color: const Color(0xFF6467F2)),
                  const SizedBox(width: 3),
                  Text(
                    'Cards',
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF6467F2),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
