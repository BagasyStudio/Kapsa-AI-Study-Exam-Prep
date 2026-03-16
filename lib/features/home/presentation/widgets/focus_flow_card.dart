import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/circular_progress_ring.dart';

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
  final int dueCount;
  final VoidCallback? onCtaTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onDueTap;

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
    this.dueCount = 0,
    this.onCtaTap,
    this.onMoreTap,
    this.onDueTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.immersiveCard,
            borderRadius: AppRadius.borderRadiusXxl,
            border: Border.all(
              color: AppColors.immersiveBorder,
            ),
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
                              color: Colors.white.withValues(alpha: 0.1),
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
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                        // Due cards badge
                        if (dueCount > 0) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: onDueTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.12),
                                borderRadius: AppRadius.borderRadiusPill,
                                border: Border.all(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    size: 12,
                                    color: Color(0xFFFBBF24),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$dueCount card${dueCount == 1 ? '' : 's'} due',
                                    style: AppTypography.caption.copyWith(
                                      color: const Color(0xFFFBBF24),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          color: Colors.white60,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),

              // Center: compact inline progress row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: progress != null
                    ? Row(
                        children: [
                          // Small progress circle
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressRing(
                              progress: progress!,
                              size: 40,
                              strokeWidth: 4,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${(progress! * 100).round()}%',
                            style: AppTypography.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Mastery',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(
                            placeholderIcon ?? Icons.edit_note,
                            size: 28,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Not started',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ],
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
                      color: AppColors.immersiveSurface,
                      borderRadius: AppRadius.borderRadiusPill,
                    ),
                    child: Center(
                      child: Text(
                        ctaLabel,
                        style: AppTypography.button.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: onCtaTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.ctaLime,
                      borderRadius: AppRadius.borderRadiusPill,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ctaLabel,
                          style: AppTypography.button.copyWith(
                            color: AppColors.ctaLimeText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: AppColors.ctaLimeText,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
    );
  }
}
