import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// An empty time slot in the calendar timeline.
///
/// Shows a dashed border placeholder indicating free time
/// with an optional "Add task" action.
class EmptySlot extends StatelessWidget {
  final String time;
  final VoidCallback? onTap;

  const EmptySlot({
    super.key,
    required this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderRadiusLg,
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.2),
            // Dashed border effect simulated with dotted style
          ),
        ),
        child: Row(
          children: [
            // Add icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.add,
                size: 14,
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Free time label
            Text(
              'Free Time',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),

            const Spacer(),

            // Time
            Text(
              time,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
