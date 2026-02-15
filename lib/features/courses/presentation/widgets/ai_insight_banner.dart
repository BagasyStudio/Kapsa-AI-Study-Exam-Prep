import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// AI Insight banner card for the Course Detail screen.
///
/// "You're weak on Cell Division" with sparkle icon and CTA.
class AiInsightBanner extends StatelessWidget {
  final String weakTopic;
  final String recommendation;
  final VoidCallback? onReviewTap;

  const AiInsightBanner({
    super.key,
    required this.weakTopic,
    required this.recommendation,
    this.onReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderRadiusLg,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative glow
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI INSIGHT',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Title with highlighted topic
                  RichText(
                    text: TextSpan(
                      style: AppTypography.h4.copyWith(fontSize: 17),
                      children: [
                        const TextSpan(text: "You're weak on "),
                        TextSpan(
                          text: weakTopic,
                          style: const TextStyle(color: AppColors.primary),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    recommendation,
                    style: AppTypography.bodySmall.copyWith(
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // CTA button
                  GestureDetector(
                    onTap: onReviewTap,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: AppRadius.borderRadiusMd,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Review Suggested Topic',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
