import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../providers/subscription_provider.dart';
import '../../data/subscription_repository.dart';

/// Banner that shows remaining free uses for the day.
///
/// Glassmorphism styled banner with progress indicator
/// that changes color based on remaining usage (green → yellow → red).
class UsageLimitBanner extends ConsumerWidget {
  const UsageLimitBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProAsync = ref.watch(isProProvider);
    final usageAsync = ref.watch(dailyUsageProvider);

    return isProAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (isPro) {
        if (isPro) return const SizedBox.shrink();

        return usageAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (usage) {
            // Calculate total usage across features
            final totalUsed = usage.values.fold(0, (a, b) => a + b);
            final totalLimit = SubscriptionRepository.freeLimits.values
                .fold(0, (a, b) => a + b);

            if (totalUsed == 0) return const SizedBox.shrink();

            final progress = (totalUsed / totalLimit).clamp(0.0, 1.0);
            final progressColor = progress < 0.5
                ? const Color(0xFF10B981) // green
                : progress < 0.8
                    ? const Color(0xFFF59E0B) // yellow
                    : const Color(0xFFEF4444); // red

            return TapScale(
                onTap: () => context.push(Routes.paywall),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: progressColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: progressColor.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              progress >= 0.8
                                  ? Icons.lock_outline
                                  : Icons.auto_awesome,
                              color: progressColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // Text + progress bar
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progress >= 1.0
                                      ? 'Daily free limit reached'
                                      : '$totalUsed of $totalLimit free uses today',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor:
                                        progressColor.withValues(alpha: 0.1),
                                    valueColor:
                                        AlwaysStoppedAnimation(progressColor),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // Upgrade CTA
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'Upgrade',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            );
          },
        );
      },
    );
  }
}
