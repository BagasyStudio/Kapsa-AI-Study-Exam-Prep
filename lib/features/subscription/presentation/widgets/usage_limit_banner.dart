import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_limits.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../providers/subscription_provider.dart';

/// Beautiful credits banner that shows remaining daily credits.
///
/// Always visible for free users. Shows a large credit count,
/// progress bar, and contextual hint about what they can do.
/// Hidden for Pro users.
class UsageLimitBanner extends ConsumerWidget {
  const UsageLimitBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProAsync = ref.watch(isProProvider);
    final creditsAsync = ref.watch(remainingCreditsProvider);

    return isProAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (isPro) {
        if (isPro) return const SizedBox.shrink();

        return creditsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (remaining) {
            final brightness = Theme.of(context).brightness;
            final isDark = brightness == Brightness.dark;
            final total = AppLimits.freeCreditsPerDay;
            final progress = remaining / total;
            final isLow = remaining < 10;

            // Accent color based on remaining credits
            final accentColor = isLow
                ? const Color(0xFFF59E0B) // amber warning
                : const Color(0xFF8B5CF6); // purple default

            // Contextual hint
            final hint = _getContextHint(remaining);

            return TapScale(
              onTap: () => context.push(Routes.paywall),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accentColor.withValues(alpha: isDark ? 0.2 : 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    // Credit count with icon
                    _CreditCounter(
                      remaining: remaining,
                      total: total,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Text + progress bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLow
                                ? 'Running low!'
                                : '$remaining credits remaining',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textPrimaryFor(brightness),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor:
                                  accentColor.withValues(alpha: 0.1),
                              valueColor:
                                  AlwaysStoppedAnimation(accentColor),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hint,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMutedFor(brightness),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // PRO badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'PRO',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getContextHint(int remaining) {
    if (remaining <= 0) {
      return 'Credits reset tomorrow. Go PRO for unlimited.';
    }
    // Show what the user can still do
    final flashcardGens = remaining ~/ (AppLimits.creditCost['flashcards'] ?? 3);
    final snapSolves = remaining ~/ (AppLimits.creditCost['snap_solve'] ?? 2);

    if (flashcardGens >= 1 && snapSolves >= 1) {
      return '~$flashcardGens flashcard gens or ~$snapSolves snap solves left';
    }
    if (flashcardGens >= 1) {
      return '~$flashcardGens flashcard generations left';
    }
    return 'Resets daily. Go PRO for unlimited.';
  }
}

/// Circular credit counter with number display.
class _CreditCounter extends StatelessWidget {
  final int remaining;
  final int total;
  final Color accentColor;
  final bool isDark;

  const _CreditCounter({
    required this.remaining,
    required this.total,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: (remaining / total).clamp(0.0, 1.0),
              strokeWidth: 3,
              backgroundColor: accentColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(accentColor),
            ),
          ),
          // Number
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$remaining',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  height: 1,
                ),
              ),
              Text(
                '/$total',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black38,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
