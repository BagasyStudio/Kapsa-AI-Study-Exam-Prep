import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';

/// A single feature card for the onboarding carousel.
///
/// Displays mascot image (with parallax offset), feature title, and description.
class FeatureCarouselCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final IconData icon;
  final double imageParallaxOffset;

  const FeatureCarouselCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.icon,
    this.imageParallaxOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: AppRadius.borderRadiusCard,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderRadiusCard,
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mascot with parallax
                  Transform.translate(
                    offset: Offset(imageParallaxOffset, 0),
                    child: Image.asset(
                      imagePath,
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 140,
                        height: 140,
                        child: Icon(Icons.image_not_supported_outlined,
                            size: 48, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Icon badge top-right
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
