import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/study_task_model.dart';
import '../providers/study_plan_provider.dart';

/// Full-screen study path with prioritized AI-driven tasks.
///
/// Uses [aiEnhancedStudyPlanProvider] which calls the AI edge function
/// for personalized task reasons and priorities, falling back to the
/// local [studyPlanProvider] if AI is unavailable.
class StudyPathScreen extends ConsumerStatefulWidget {
  const StudyPathScreen({super.key});

  @override
  ConsumerState<StudyPathScreen> createState() => _StudyPathScreenState();
}

class _StudyPathScreenState extends ConsumerState<StudyPathScreen> {
  final Set<int> _completedIndices = {};

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final tasksAsync = ref.watch(aiEnhancedStudyPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      body: Stack(
        children: [
          // Background gradient blobs
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.06 : 0.04),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
                  ),
                  child: Row(
                    children: [
                      TapScale(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: AppColors.textPrimaryFor(brightness),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Study Path',
                                  style: AppTypography.h3.copyWith(
                                    color: AppColors.textPrimaryFor(brightness),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6467F2),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'AI',
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Your personalized study plan',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMutedFor(brightness),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Content
                Expanded(
                  child: tasksAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: ShimmerList(count: 6, itemHeight: 90),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        'Could not load study plan',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryFor(brightness),
                        ),
                      ),
                    ),
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return _buildEmptyState(brightness, isDark);
                      }

                      final completedCount = _completedIndices.length;
                      final totalCount = tasks.length;
                      final progress = totalCount > 0
                          ? completedCount / totalCount
                          : 0.0;

                      // Find first uncompleted task
                      StudyTask? firstUncompleted;
                      for (int i = 0; i < tasks.length; i++) {
                        if (!_completedIndices.contains(i)) {
                          firstUncompleted = tasks[i];
                          break;
                        }
                      }

                      return Column(
                        children: [
                          // Progress ring
                          _ProgressHeader(
                            progress: progress,
                            completed: completedCount,
                            total: totalCount,
                            brightness: brightness,
                            isDark: isDark,
                          ),

                          // Focus Mode button
                          if (firstUncompleted != null && progress < 1.0)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
                              ),
                              child: TapScale(
                                onTap: () {
                                  final task = firstUncompleted;
                                  if (task?.route != null) {
                                    context.push(task!.route!);
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6467F2).withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.bolt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Focus Mode — ${firstUncompleted.title}',
                                        style: AppTypography.labelLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: AppSpacing.lg),

                          // Task list
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.huge,
                              ),
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                final isCompleted = _completedIndices.contains(index);
                                return _StudyPathTaskCard(
                                  task: task,
                                  index: index,
                                  isCompleted: isCompleted,
                                  isFirst: index == 0 && !isCompleted,
                                  brightness: brightness,
                                  isDark: isDark,
                                  onTap: () {
                                    if (task.route != null) {
                                      context.push(task.route!);
                                    }
                                  },
                                  onComplete: () {
                                    setState(() {
                                      if (isCompleted) {
                                        _completedIndices.remove(index);
                                      } else {
                                        _completedIndices.add(index);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Brightness brightness, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 40,
                color: const Color(0xFF10B981).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'All caught up!',
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimaryFor(brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No tasks for today. Great job staying on top of your studies!',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMutedFor(brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress ring header showing completion status.
class _ProgressHeader extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;
  final Brightness brightness;
  final bool isDark;

  const _ProgressHeader({
    required this.progress,
    required this.completed,
    required this.total,
    required this.brightness,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GlassPanel(
        tier: GlassTier.medium,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Progress ring
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: AppColors.textMutedFor(brightness)
                          .withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0
                            ? const Color(0xFF10B981)
                            : AppColors.primary,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress >= 1.0
                        ? 'All tasks completed!'
                        : '$completed of $total tasks done',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimaryFor(brightness),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    progress >= 1.0
                        ? 'Amazing work today!'
                        : 'Keep going, you\'re doing great',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(brightness),
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
}

/// Individual task card in the study path.
class _StudyPathTaskCard extends StatelessWidget {
  final StudyTask task;
  final int index;
  final bool isCompleted;
  final bool isFirst;
  final Brightness brightness;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const _StudyPathTaskCard({
    required this.task,
    required this.index,
    required this.isCompleted,
    required this.isFirst,
    required this.brightness,
    required this.isDark,
    required this.onTap,
    required this.onComplete,
  });

  Color get _accentColor {
    switch (task.type) {
      case StudyTaskType.flashcardReview:
        return const Color(0xFFF59E0B);
      case StudyTaskType.quiz:
        return const Color(0xFF3B82F6);
      case StudyTaskType.calendarExam:
        return const Color(0xFFEF4444);
      case StudyTaskType.calendarTask:
        return const Color(0xFF10B981);
      case StudyTaskType.materialReview:
        return const Color(0xFF8B5CF6);
      case StudyTaskType.summaryGeneration:
        return const Color(0xFF06B6D4);
      case StudyTaskType.glossaryGeneration:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData get _icon {
    switch (task.type) {
      case StudyTaskType.flashcardReview:
        return Icons.style;
      case StudyTaskType.quiz:
        return Icons.quiz;
      case StudyTaskType.calendarExam:
        return Icons.event;
      case StudyTaskType.calendarTask:
        return Icons.task_alt;
      case StudyTaskType.materialReview:
        return Icons.description;
      case StudyTaskType.summaryGeneration:
        return Icons.auto_stories;
      case StudyTaskType.glossaryGeneration:
        return Icons.menu_book;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TapScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isCompleted
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white.withValues(alpha: 0.4))
                : isFirst
                    ? (isDark
                        ? _accentColor.withValues(alpha: 0.08)
                        : _accentColor.withValues(alpha: 0.05))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFirst && !isCompleted
                  ? _accentColor.withValues(alpha: 0.25)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              // Completion checkbox
              GestureDetector(
                onTap: onComplete,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : Colors.transparent,
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : AppColors.textMutedFor(brightness).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor.withValues(alpha: isCompleted ? 0.05 : 0.1),
                ),
                child: Icon(
                  _icon,
                  size: 20,
                  color: isCompleted
                      ? AppColors.textMutedFor(brightness)
                      : _accentColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTypography.labelLarge.copyWith(
                        color: isCompleted
                            ? AppColors.textMutedFor(brightness)
                            : AppColors.textPrimaryFor(brightness),
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      task.subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedFor(brightness),
                      ),
                    ),
                    if (task.reason != null && !isCompleted) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.reason!,
                        style: AppTypography.caption.copyWith(
                          color: _accentColor.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Priority badge for first uncompleted
              if (isFirst && !isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'NEXT',
                    style: AppTypography.caption.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                )
              else if (!isCompleted)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textMutedFor(brightness),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
