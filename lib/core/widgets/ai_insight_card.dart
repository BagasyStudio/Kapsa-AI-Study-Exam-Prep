import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// AI Insight card with sparkle icon and recommendation text.
///
/// Used in Course Detail, Test Results corrections, and Calendar suggestions.
class AiInsightCard extends StatelessWidget {
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const AiInsightCard({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x0D6467F2), // primary 5%
            Color(0x1A6467F2), // primary 10%
          ],
        ),
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: AppColors.primary,
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
          const SizedBox(height: 12),
          Text(title, style: AppTypography.labelLarge),
          const SizedBox(height: 4),
          Text(body, style: AppTypography.bodySmall.copyWith(height: 1.6)),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onActionTap,
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
                      actionLabel!,
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
        ],
      ),
    );
  }
}
