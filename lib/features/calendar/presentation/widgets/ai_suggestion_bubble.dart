import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// An AI suggestion bubble in the calendar timeline.
///
/// Displays an AI-generated study recommendation with a sparkle
/// icon and optional action button.
class AiSuggestionBubble extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AiSuggestionBubble({
    super.key,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI sparkle icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                ],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 14,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
