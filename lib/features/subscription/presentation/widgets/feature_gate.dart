import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../providers/subscription_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Widget that overlays a lock screen when the feature is gated.
///
/// If the user has exceeded their daily free limit for the given feature,
/// shows a blurred overlay with a lock icon and upgrade CTA.
class FeatureGate extends ConsumerWidget {
  final String feature;
  final Widget child;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProAsync = ref.watch(isProProvider);
    final user = ref.watch(currentUserProvider);

    return isProAsync.when(
      loading: () => child,
      error: (_, __) => child,
      data: (isPro) {
        if (isPro || user == null) return child;

        final remainingAsync = ref.watch(
          remainingUsesProvider(
            (userId: user.id, feature: feature),
          ),
        );

        return remainingAsync.when(
          loading: () => child,
          error: (_, __) => child,
          data: (remaining) {
            if (remaining > 0) return child;

            // Feature is locked
            return Stack(
              children: [
                child,
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.7),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Daily limit reached',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Upgrade to Pro for unlimited access',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TapScale(
                                onTap: () => context.push(Routes.paywall),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    'Unlock with Pro',
                                    style: AppTypography.button.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
