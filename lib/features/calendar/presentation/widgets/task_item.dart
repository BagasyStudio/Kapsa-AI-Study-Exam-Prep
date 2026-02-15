import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// A task/study item in the calendar timeline.
///
/// Shows a colored icon circle, task title, subtitle, and optional
/// check circle or trailing text. Matches the mockup's glass-card-outline style.
class TaskItem extends StatelessWidget {
  final String title;
  final String time;
  final String? subtitle;
  final bool isCompleted;
  final IconData? icon;
  final Color? iconBgColor;
  final Color? iconColor;
  final String? trailingText;
  final VoidCallback? onTap;

  const TaskItem({
    super.key,
    required this.title,
    required this.time,
    this.subtitle,
    this.isCompleted = false,
    this.icon,
    this.iconBgColor,
    this.iconColor,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.borderRadiusLg,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: AppRadius.borderRadiusLg,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Opacity(
              opacity: isCompleted ? 0.6 : 1.0,
              child: Row(
                children: [
                  // Icon circle
                  if (icon != null)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconBgColor ?? AppColors.primary.withValues(alpha: 0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: iconColor ?? AppColors.primary,
                      ),
                    )
                  else
                    // Fallback checkbox circle
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.success.withValues(alpha: 0.2)
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.success
                              : AppColors.textMuted,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: AppColors.success,
                            )
                          : null,
                    ),

                  const SizedBox(width: AppSpacing.sm),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.labelLarge.copyWith(
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCompleted
                                ? AppColors.textMuted
                                : const Color(0xFF1E293B), // slate-800
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (time.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            time,
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF64748B), // slate-500
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Trailing: either text or check button
                  if (trailingText != null)
                    Text(
                      trailingText!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    )
                  else
                    TapScale(
                      scaleDown: 0.85,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task marked as complete')),
                        );
                      },
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 24,
                        color: const Color(0xFF94A3B8), // slate-400
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
