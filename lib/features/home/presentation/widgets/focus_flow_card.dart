import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/circular_progress_ring.dart';
import '../../../../core/widgets/primary_button.dart';

/// A single Focus Flow card (Biology 101 Exam, History Essay, etc.)
///
/// Primary cards show a circular progress ring.
/// Secondary cards show a simple icon placeholder.
class FocusFlowCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final Color tagTextColor;
  final String title;
  final String subtitle;
  final double? progress; // null = not started
  final String ctaLabel;
  final IconData? placeholderIcon;
  final bool isSecondary;
  final VoidCallback? onCtaTap;
  final VoidCallback? onMoreTap;

  const FocusFlowCard({
    super.key,
    required this.tag,
    required this.tagColor,
    required this.tagTextColor,
    required this.title,
    required this.subtitle,
    this.progress,
    required this.ctaLabel,
    this.placeholderIcon,
    this.isSecondary = false,
    this.onCtaTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderRadiusXxl,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: AppRadius.borderRadiusXxl,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: tag + more button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: tagColor,
                            borderRadius: AppRadius.borderRadiusPill,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: AppTypography.caption.copyWith(
                              color: tagTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle, style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  if (!isSecondary)
                    GestureDetector(
                      onTap: onMoreTap,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),

              // Center: progress ring or placeholder icon
              Expanded(
                child: Center(
                  child: progress != null
                      ? CircularProgressRing(
                          progress: progress!,
                          size: 160,
                          strokeWidth: 12,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(progress! * 100).round()}%',
                                style: AppTypography.h1.copyWith(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Mastery',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              placeholderIcon ?? Icons.edit_note,
                              size: 56,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Not started',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // CTA Button
              if (isSecondary)
                GestureDetector(
                  onTap: onCtaTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: AppRadius.borderRadiusPill,
                    ),
                    child: Center(
                      child: Text(
                        ctaLabel,
                        style: AppTypography.button.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                PrimaryButton(
                  label: ctaLabel,
                  trailingIcon: Icons.arrow_forward,
                  onPressed: onCtaTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
