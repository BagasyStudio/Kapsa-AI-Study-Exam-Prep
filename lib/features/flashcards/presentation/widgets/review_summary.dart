import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// End-of-session summary shown after completing an SRS review.
class ReviewSummary extends StatelessWidget {
  final int totalReviewed;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;
  final int xpEarned;
  final VoidCallback onDone;
  final VoidCallback? onShare;

  const ReviewSummary({
    super.key,
    required this.totalReviewed,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    this.xpEarned = 0,
    required this.onDone,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final retention = totalReviewed > 0
        ? ((goodCount + easyCount) / totalReviewed * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Trophy icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primaryLight.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 40,
              color: Color(0xFFFBBF24),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Session Complete!',
            style: AppTypography.h2.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            '$totalReviewed cards reviewed',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMutedFor(brightness),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                label: 'Again',
                count: againCount,
                color: const Color(0xFFEF4444),
              ),
              _StatChip(
                label: 'Hard',
                count: hardCount,
                color: const Color(0xFFF97316),
              ),
              _StatChip(
                label: 'Good',
                count: goodCount,
                color: const Color(0xFF22C55E),
              ),
              _StatChip(
                label: 'Easy',
                count: easyCount,
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Retention indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.5),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: retention >= 80
                      ? const Color(0xFF22C55E)
                      : retention >= 60
                          ? const Color(0xFFF97316)
                          : const Color(0xFFEF4444),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$retention% retention',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // XP earned
          if (xpEarned > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '+$xpEarned XP earned',
                    style: AppTypography.labelLarge.copyWith(
                      color: const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),

          // Done button
          TapScale(
            onTap: onDone,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'Done',
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Share button
          if (onShare != null) ...[
            const SizedBox(height: AppSpacing.md),
            TapScale(
              onTap: onShare,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        Colors.white.withValues(alpha: isDark ? 0.12 : 0.6),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.ios_share,
                      color: AppColors.textSecondaryFor(brightness),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share Results',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
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

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Text(
              '$count',
              style: AppTypography.h4.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMutedFor(brightness),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
