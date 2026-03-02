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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = Theme.of(context).brightness;
    return ClipRRect(
      borderRadius: AppRadius.borderRadiusXxl,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.45),
            borderRadius: AppRadius.borderRadiusXxl,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.6),
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
                            color: AppColors.textPrimaryFor(brightness),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMutedFor(brightness),
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
                                color: const Color(0xFFFEF3C7).withValues(alpha: isDark ? 0.15 : 0.6),
                                borderRadius: AppRadius.borderRadiusPill,
                                border: Border.all(
                                  color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.3 : 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 12,
                                    color: isDark
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$dueCount card${dueCount == 1 ? '' : 's'} due',
                                    style: AppTypography.caption.copyWith(
                                      color: isDark
                                          ? const Color(0xFFFBBF24)
                                          : const Color(0xFFD97706),
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
                          color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.5),
                        ),
                        child: Icon(
                          Icons.more_horiz,
                          color: AppColors.textMutedFor(brightness),
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
                          size: 100,
                          strokeWidth: 9,
                          child: progress! > 0
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(progress! * 100).round()}%',
                                      style: AppTypography.h1.copyWith(
                                        fontSize: 28,
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
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_arrow_rounded,
                                        size: 24,
                                        color: AppColors.primary),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Start',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                        fontSize: 10,
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
                              size: 44,
                              color: AppColors.textMutedFor(brightness).withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Not started',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMutedFor(brightness),
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
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.5),
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
