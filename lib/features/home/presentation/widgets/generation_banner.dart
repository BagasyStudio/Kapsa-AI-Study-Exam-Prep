import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/generation_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Banner shown on the home screen for background AI generation tasks.
///
/// Shows a card for each active/completed/errored generation.
/// Self-hides when no tasks exist. Completed tasks are tappable to navigate
/// to the result. Error/completed tasks can be dismissed by swiping.
class GenerationBanner extends ConsumerWidget {
  const GenerationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(generationProvider);

    if (tasks.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final task in tasks)
              _GenerationTaskCard(key: ValueKey(task.id), task: task),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Individual task card
// ═══════════════════════════════════════════════════════════════════════════════

class _GenerationTaskCard extends ConsumerWidget {
  final GenerationTask task;

  const _GenerationTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final card = TapScale(
      onTap: task.isCompleted ? () => _onTapCompleted(context, ref) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _gradientColors(isDark),
          ),
          border: Border.all(
            color: _borderColor(isDark),
          ),
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _title,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimaryFor(brightness),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(brightness),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (task.isCompleted)
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.textMutedFor(brightness),
              ),
            if (task.isError)
              GestureDetector(
                onTap: () => ref.read(generationProvider.notifier).dismiss(task.id),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textMutedFor(brightness),
                ),
              ),
          ],
        ),
      ),
    );

    // Only completed/error tasks can be dismissed by swipe
    if (!task.isRunning) {
      return Dismissible(
        key: ValueKey('dismiss_${task.id}'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) {
          ref.read(generationProvider.notifier).dismiss(task.id);
        },
        child: card,
      );
    }

    return card;
  }

  void _onTapCompleted(BuildContext context, WidgetRef ref) {
    final route = task.resultRoute;
    if (route != null) {
      ref.read(generationProvider.notifier).dismiss(task.id);
      context.push(route);
    }
  }

  // ── Icon ───────────────────────────────────────────────────────────────

  Widget _buildIcon() {
    if (task.isRunning) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(
                  task.typeColor.withValues(alpha: 0.8),
                ),
              ),
            ),
            Icon(
              task.typeIcon,
              size: 16,
              color: task.typeColor,
            ),
          ],
        ),
      );
    }

    if (task.isCompleted) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success.withValues(alpha: 0.15),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 20,
          color: AppColors.success,
        ),
      );
    }

    // Error
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.error.withValues(alpha: 0.15),
      ),
      child: Icon(
        Icons.error_outline_rounded,
        size: 20,
        color: AppColors.error,
      ),
    );
  }

  // ── Text ───────────────────────────────────────────────────────────────

  String get _title {
    if (task.isRunning) return 'Creating ${task.typeLabel}...';
    if (task.isCompleted) return '${task.typeLabel} ready!';
    return '${task.typeLabel} failed';
  }

  String get _subtitle {
    if (task.isRunning) return 'Generating for ${task.courseName}';
    if (task.isCompleted) return 'Tap to view — ${task.courseName}';
    return task.errorMessage ?? 'Tap ✕ to dismiss';
  }

  // ── Gradient ───────────────────────────────────────────────────────────

  List<Color> _gradientColors(bool isDark) {
    if (task.isRunning) {
      return isDark
          ? [
              task.typeColor.withValues(alpha: 0.12),
              task.typeColor.withValues(alpha: 0.06),
            ]
          : [
              task.typeColor.withValues(alpha: 0.08),
              task.typeColor.withValues(alpha: 0.04),
            ];
    }

    if (task.isCompleted) {
      return isDark
          ? [
              AppColors.success.withValues(alpha: 0.12),
              AppColors.success.withValues(alpha: 0.06),
            ]
          : [
              AppColors.success.withValues(alpha: 0.08),
              AppColors.success.withValues(alpha: 0.04),
            ];
    }

    // Error
    return isDark
        ? [
            AppColors.error.withValues(alpha: 0.12),
            AppColors.error.withValues(alpha: 0.06),
          ]
        : [
            AppColors.error.withValues(alpha: 0.08),
            AppColors.error.withValues(alpha: 0.04),
          ];
  }

  Color _borderColor(bool isDark) {
    final alpha = isDark ? 0.2 : 0.15;
    if (task.isRunning) return task.typeColor.withValues(alpha: alpha);
    if (task.isCompleted) return AppColors.success.withValues(alpha: alpha);
    return AppColors.error.withValues(alpha: alpha);
  }
}
