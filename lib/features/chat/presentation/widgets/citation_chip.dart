import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// A small citation reference chip shown below AI messages.
///
/// Displays a source name with a document icon, indicating the
/// material from which the AI sourced its response.
class CitationChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const CitationChip({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 12,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
