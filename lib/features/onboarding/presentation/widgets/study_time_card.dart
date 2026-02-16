import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/tap_scale.dart';

/// A tappable glass card for study time selection.
///
/// Shows emoji, time label, and motivational subtitle.
/// Selected state lifts the card and glows with primary color.
class StudyTimeCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final bool isSelected;
  final bool hasSelection; // true if ANY card is selected (for dimming)
  final VoidCallback onTap;

  const StudyTimeCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.hasSelection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: hasSelection && !isSelected ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, isSelected ? -4 : 0, 0),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: isSelected ? 20 : 8,
                offset: Offset(0, isSelected ? 8 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.7)
                      : AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
