import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../providers/snap_solve_provider.dart';

/// Banner shown on the home screen while a Snap & Solve job runs in background.
///
/// Self-hides when idle. Shows progress, completion, or error states.
class SnapSolveBanner extends ConsumerWidget {
  const SnapSolveBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobState = ref.watch(snapSolveJobProvider);

    // Hidden when idle
    if (jobState.status == SnapSolveJobStatus.idle) {
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: TapScale(
            onTap: () => context.push(Routes.snapSolve),
            child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: _gradientColors(jobState.status, isDark),
                    ),
                    border: Border.all(
                      color: _borderColor(jobState.status, isDark),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildIcon(jobState.status),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _title(jobState.status),
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.textPrimaryFor(brightness),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _subtitle(jobState.status),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMutedFor(brightness),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (jobState.status == SnapSolveJobStatus.completed ||
                          jobState.status == SnapSolveJobStatus.error)
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.textMutedFor(brightness),
                        ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(SnapSolveJobStatus status) {
    switch (status) {
      case SnapSolveJobStatus.uploading:
      case SnapSolveJobStatus.solving:
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
                    AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Icon(
                Icons.psychology_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
        );
      case SnapSolveJobStatus.completed:
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
      case SnapSolveJobStatus.error:
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
      case SnapSolveJobStatus.idle:
        return const SizedBox.shrink();
    }
  }

  String _title(SnapSolveJobStatus status) {
    switch (status) {
      case SnapSolveJobStatus.uploading:
        return 'Uploading image...';
      case SnapSolveJobStatus.solving:
        return 'Solving your problem...';
      case SnapSolveJobStatus.completed:
        return 'Solution ready!';
      case SnapSolveJobStatus.error:
        return 'Solve failed';
      case SnapSolveJobStatus.idle:
        return '';
    }
  }

  String _subtitle(SnapSolveJobStatus status) {
    switch (status) {
      case SnapSolveJobStatus.uploading:
      case SnapSolveJobStatus.solving:
        return 'You can browse while we work';
      case SnapSolveJobStatus.completed:
        return 'Tap to view step-by-step solution';
      case SnapSolveJobStatus.error:
        return 'Tap to see details and retry';
      case SnapSolveJobStatus.idle:
        return '';
    }
  }

  List<Color> _gradientColors(SnapSolveJobStatus status, bool isDark) {
    switch (status) {
      case SnapSolveJobStatus.uploading:
      case SnapSolveJobStatus.solving:
        return isDark
            ? [
                AppColors.primary.withValues(alpha: 0.12),
                const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              ]
            : [
                AppColors.primary.withValues(alpha: 0.08),
                const Color(0xFF8B5CF6).withValues(alpha: 0.05),
              ];
      case SnapSolveJobStatus.completed:
        return isDark
            ? [
                AppColors.success.withValues(alpha: 0.12),
                AppColors.success.withValues(alpha: 0.06),
              ]
            : [
                AppColors.success.withValues(alpha: 0.08),
                AppColors.success.withValues(alpha: 0.04),
              ];
      case SnapSolveJobStatus.error:
        return isDark
            ? [
                AppColors.error.withValues(alpha: 0.12),
                AppColors.error.withValues(alpha: 0.06),
              ]
            : [
                AppColors.error.withValues(alpha: 0.08),
                AppColors.error.withValues(alpha: 0.04),
              ];
      case SnapSolveJobStatus.idle:
        return [Colors.transparent, Colors.transparent];
    }
  }

  Color _borderColor(SnapSolveJobStatus status, bool isDark) {
    final alpha = isDark ? 0.2 : 0.15;
    switch (status) {
      case SnapSolveJobStatus.uploading:
      case SnapSolveJobStatus.solving:
        return AppColors.primary.withValues(alpha: alpha);
      case SnapSolveJobStatus.completed:
        return AppColors.success.withValues(alpha: alpha);
      case SnapSolveJobStatus.error:
        return AppColors.error.withValues(alpha: alpha);
      case SnapSolveJobStatus.idle:
        return Colors.transparent;
    }
  }
}
