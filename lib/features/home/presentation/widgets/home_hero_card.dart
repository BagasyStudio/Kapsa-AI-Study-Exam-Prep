import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/generation_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../providers/resume_quiz_provider.dart';
import '../providers/study_plan_provider.dart';
import '../../data/models/study_task_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Home Hero Card — ONE contextual card based on priority
// ═══════════════════════════════════════════════════════════════════════════════
//
// Priority (highest to lowest):
// 1. Generation running → progress + "Open deck" secondary action
// 2. Quiz in progress → "Continue your quiz" with % completed
// 3. Due flashcards → "Review X due cards"
// 4. Study plan → today's tasks (compact, max 3)
// 5. Default → "You're all caught up!" + calm action
//
// Auto-refreshes when any watched provider changes.
// AnimatedSwitcher for smooth transitions between states.
// Stable ValueKey per priority type prevents flicker on pull-to-refresh.
// ═══════════════════════════════════════════════════════════════════════════════

/// The priority type determines the hero card content.
enum _HeroPriority {
  generation,
  quiz,
  dueCards,
  studyPlan,
  caughtUp,
}

class HomeHeroCard extends ConsumerWidget {
  const HomeHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all data sources — triggers rebuild when any changes
    final generationTasks = ref.watch(generationProvider);
    final quizzesAsync = ref.watch(inProgressQuizzesProvider);
    final dueCardsAsync = ref.watch(totalDueCardsProvider);
    final studyPlanAsync = ref.watch(studyPlanProvider);

    // Determine priority
    final runningTasks = generationTasks.where((t) => t.isRunning).toList();
    final completedTasks =
        generationTasks.where((t) => t.isCompleted || t.isError).toList();
    final quizzes =
        quizzesAsync.whenOrNull(data: (q) => q) ?? [];
    final dueCount = dueCardsAsync.whenOrNull(data: (c) => c) ?? 0;
    final studyTasks =
        studyPlanAsync.whenOrNull(data: (t) => t) ?? [];

    // Build the hero content based on priority
    _HeroPriority priority;
    Widget content;

    if (runningTasks.isNotEmpty || completedTasks.isNotEmpty) {
      priority = _HeroPriority.generation;
      content = _GenerationHero(
        runningTasks: runningTasks,
        completedTasks: completedTasks,
      );
    } else if (quizzes.isNotEmpty) {
      priority = _HeroPriority.quiz;
      content = _QuizHero(quiz: quizzes.first);
    } else if (dueCount > 0) {
      priority = _HeroPriority.dueCards;
      content = _DueCardsHero(count: dueCount);
    } else if (studyTasks.isNotEmpty) {
      priority = _HeroPriority.studyPlan;
      content = _StudyPlanHero(tasks: studyTasks.take(3).toList());
    } else {
      priority = _HeroPriority.caughtUp;
      content = const _CaughtUpHero();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: child,
            ),
          );
        },
        // Stable key per priority type — prevents flicker on pull-to-refresh
        child: KeyedSubtree(
          key: ValueKey(priority),
          child: content,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Priority 1: Generation in progress / completed
// ═══════════════════════════════════════════════════════════════════════════════

class _GenerationHero extends ConsumerWidget {
  final List<GenerationTask> runningTasks;
  final List<GenerationTask> completedTasks;

  const _GenerationHero({
    required this.runningTasks,
    required this.completedTasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show the most relevant task: first running, then first completed/error
    final allTasks = [...runningTasks, ...completedTasks];
    if (allTasks.isEmpty) return const SizedBox.shrink();
    final task = allTasks.first;

    final accentColor = task.isRunning
        ? task.typeColor
        : task.isCompleted
            ? AppColors.success
            : AppColors.error;

    return TapScale(
      onTap: task.isCompleted && task.resultRoute != null
          ? () {
              ref.read(generationProvider.notifier).dismiss(task.id);
              context.push(task.resultRoute!);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: accentColor.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                _buildIcon(task, accentColor),
                const SizedBox(width: AppSpacing.sm),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(task),
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(task),
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Dismiss for any status (including running)
                GestureDetector(
                  onTap: () {
                    final wasRunning = task.isRunning;
                    ref
                        .read(generationProvider.notifier)
                        .dismiss(task.id);
                    if (wasRunning) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Generation dismissed'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),

            // Progress bar for running tasks
            if (task.isRunning) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  backgroundColor:
                      accentColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(accentColor),
                  minHeight: 4,
                ),
              ),
            ],

            // Action buttons
            if (task.isCompleted && task.resultRoute != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tap to view',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white60,
                  ),
                ],
              ),
            ],

            if (task.isError) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                task.errorMessage ?? 'Something went wrong',
                style: AppTypography.caption.copyWith(
                  color: AppColors.error,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Additional running/completed tasks count
            if (runningTasks.length + completedTasks.length > 1) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '+ ${runningTasks.length + completedTasks.length - 1} more task${runningTasks.length + completedTasks.length - 1 > 1 ? 's' : ''}',
                style: AppTypography.caption.copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(GenerationTask task, Color accent) {
    if (task.isRunning) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(
                  accent.withValues(alpha: 0.8),
                ),
              ),
            ),
            Icon(task.typeIcon, size: 18, color: accent),
          ],
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.15),
      ),
      child: Icon(
        task.isCompleted ? Icons.check_rounded : Icons.error_outline_rounded,
        size: 22,
        color: accent,
      ),
    );
  }

  String _title(GenerationTask task) {
    if (task.isRunning) return 'Generating ${task.typeLabel}...';
    if (task.isCompleted) return '${task.typeLabel} ready!';
    return '${task.typeLabel} failed';
  }

  String _subtitle(GenerationTask task) {
    if (task.isRunning) {
      final elapsed = DateTime.now().difference(task.startedAt).inSeconds;
      if (elapsed > 30) {
        return '${task.displayCourseName} \u00b7 Taking longer than usual...';
      }
      if (elapsed > 10) {
        return '${task.displayCourseName} \u00b7 ${elapsed}s';
      }
      return task.displayCourseName;
    }
    if (task.isCompleted) return task.displayCourseName;
    return task.displayCourseName;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Priority 2: Quiz in progress
// ═══════════════════════════════════════════════════════════════════════════════

class _QuizHero extends StatelessWidget {
  final InProgressQuiz quiz;

  const _QuizHero({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final progress = quiz.progress;
    final pct = (progress * 100).toInt();

    return TapScale(
      onTap: () => context.push(Routes.quizSessionPath(quiz.test.id)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular progress indicator
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3.5,
                      backgroundColor:
                          AppColors.info.withValues(alpha: 0.15),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.info),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continue your quiz',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${quiz.courseName} \u2022 ${quiz.answeredCount}/${quiz.test.totalCount} questions',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Arrow
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.info.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 18,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Priority 3: Due flashcards
// ═══════════════════════════════════════════════════════════════════════════════

class _DueCardsHero extends StatelessWidget {
  final int count;

  const _DueCardsHero({required this.count});

  // UX-08: Estimate study time — 15 seconds per card
  static String _estimateTime(int cards) {
    if (cards <= 0) return '';
    final totalSeconds = cards * 15;
    final minutes = (totalSeconds / 60).ceil();
    if (minutes < 1) return '< 1 min';
    if (minutes >= 60) return '~${minutes ~/ 60}h ${minutes % 60}min';
    return '~$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFFF59E0B); // amber

    return TapScale(
      onTap: () => context.push(Routes.quickReview),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: accentColor.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Card count circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accentColor,
                    accentColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: count > 99 ? 12 : 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time to review!',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // UX-08: Time estimation — 15s per card
                    '$count card${count != 1 ? 's' : ''} due · ${_estimateTime(count)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Arrow
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.style_rounded,
                size: 18,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Priority 4: Study plan tasks
// ═══════════════════════════════════════════════════════════════════════════════

class _StudyPlanHero extends StatelessWidget {
  final List<StudyTask> tasks;

  const _StudyPlanHero({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.immersiveBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.today_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                "Today's Plan",
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TapScale(
                onTap: () {
                  final firstCourseId = tasks
                      .where((t) => t.courseId != null)
                      .map((t) => t.courseId!)
                      .firstOrNull;
                  if (firstCourseId != null) {
                    context.push(Routes.journeyPath(firstCourseId));
                  } else {
                    context.push(Routes.studyPath);
                  }
                },
                child: Text(
                  'See all',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Task items (max 3)
          ...tasks.map((task) => _StudyPlanTaskRow(task: task)),
        ],
      ),
    );
  }
}

class _StudyPlanTaskRow extends StatelessWidget {
  final StudyTask task;

  const _StudyPlanTaskRow({required this.task});

  IconData get _icon {
    switch (task.type) {
      case StudyTaskType.flashcardReview:
        return Icons.style_rounded;
      case StudyTaskType.quiz:
        return Icons.quiz_rounded;
      case StudyTaskType.calendarExam:
        return Icons.event_rounded;
      case StudyTaskType.calendarTask:
        return Icons.task_alt_rounded;
      case StudyTaskType.materialReview:
        return Icons.description_rounded;
      case StudyTaskType.summaryGeneration:
        return Icons.auto_stories_rounded;
      case StudyTaskType.glossaryGeneration:
        return Icons.menu_book_rounded;
    }
  }

  Color get _iconColor {
    switch (task.type) {
      case StudyTaskType.flashcardReview:
        return const Color(0xFFF59E0B);
      case StudyTaskType.quiz:
        return AppColors.info;
      case StudyTaskType.calendarExam:
        return AppColors.error;
      case StudyTaskType.calendarTask:
        return const Color(0xFF10B981);
      case StudyTaskType.materialReview:
        return AppColors.primary;
      case StudyTaskType.summaryGeneration:
        return const Color(0xFF8B5CF6);
      case StudyTaskType.glossaryGeneration:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: task.route != null ? () => context.push(task.route!) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _iconColor.withValues(alpha: 0.12),
              ),
              child: Icon(_icon, size: 16, color: _iconColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.reason != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      task.reason!,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.white60,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Priority 5: All caught up (default)
// ═══════════════════════════════════════════════════════════════════════════════

class _CaughtUpHero extends StatelessWidget {
  const _CaughtUpHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.immersiveBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkmark circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981),
                  const Color(0xFF34D399),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're all caught up!",
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Browse your decks or start studying',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Arrow to courses
          TapScale(
            onTap: () => context.go(Routes.courses),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
