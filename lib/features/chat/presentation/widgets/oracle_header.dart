import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'animated_orb_avatar.dart';

/// Compact horizontal chat header: back arrow | orb + title | history | settings.
class OracleHeader extends StatelessWidget {
  final String courseLabel;
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final VoidCallback? onHistory;

  const OracleHeader({
    super.key,
    this.courseLabel = 'Biology 101',
    this.onBack,
    this.onSettings,
    this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back arrow
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),

          // Orb + title, centered in available space
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnimatedOrbAvatar(size: 36),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    courseLabel,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          // History button
          if (onHistory != null)
            GestureDetector(
              onTap: onHistory,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Icon(
                    Icons.history_rounded,
                    color: Colors.white38,
                    size: 22,
                  ),
                ),
              ),
            ),

          // Settings button
          GestureDetector(
            onTap: onSettings,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Icon(
                  Icons.tune_rounded,
                  color: Colors.white38,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
