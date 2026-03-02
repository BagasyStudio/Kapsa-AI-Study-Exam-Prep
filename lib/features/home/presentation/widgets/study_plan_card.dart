import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/study_task_model.dart';
import '../providers/study_plan_provider.dart';

/// Card on the Home screen showing today's study plan.
///
/// Renders a list of study tasks computed from existing data:
/// due flashcards, suggested quizzes, and calendar events.
class StudyPlanCard extends ConsumerWidget {
  const StudyPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(studyPlanProvider);
    final brightness = Theme.of(context).brightness;

    return planAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: GlassPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      "Today's Study Plan",
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${tasks.length} task${tasks.length > 1 ? 's' : ''}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Task list (max 5)
                ...tasks.take(5).map((task) => _TaskRow(task: task)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaskRow extends StatelessWidget {
  final StudyTask task;

  const _TaskRow({required this.task});

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
    }
  }

  Color _accentColor(StudyTaskType type) {
    switch (type) {
      case StudyTaskType.flashcardReview:
        return const Color(0xFFF59E0B); // amber
      case StudyTaskType.quiz:
        return const Color(0xFF6467F2); // primary
      case StudyTaskType.calendarExam:
        return const Color(0xFFEF4444); // red
      case StudyTaskType.calendarTask:
        return const Color(0xFF22C55E); // green
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final accent = _accentColor(task.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TapScale(
        onTap: () {
          HapticFeedback.lightImpact();
          if (task.route != null) {
            context.push(task.route!);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, size: 18, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      task.subtitle,
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
              // Arrow
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textMutedFor(brightness),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
