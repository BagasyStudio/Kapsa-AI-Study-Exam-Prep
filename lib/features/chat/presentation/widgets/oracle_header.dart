import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'animated_orb_avatar.dart';

/// Chat header with animated AI orb, course title, and oracle status.
///
/// Light-mode design matching the mockup: back arrow, centered orb,
/// course name as title, "The Oracle is online" as subtitle.
class OracleHeader extends StatelessWidget {
  final String courseLabel;
  final VoidCallback? onBack;
  final VoidCallback? onSettings;

  const OracleHeader({
    super.key,
    this.courseLabel = 'Biology 101',
    this.onBack,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            children: [
              // Top row: back + settings buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onSettings,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.more_vert,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              // Orb avatar (smaller for light mode header)
              const AnimatedOrbAvatar(size: 48),

              const SizedBox(height: AppSpacing.xs),

              // Course name as title
              Text(
                courseLabel,
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 2),

              // Oracle status
              Text(
                'The Oracle is online',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
