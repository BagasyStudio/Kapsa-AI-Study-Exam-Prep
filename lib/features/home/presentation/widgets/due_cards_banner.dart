import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';

/// Prominent banner shown when the user has flashcards due for SRS review.
/// Returns SizedBox.shrink() when no cards are due.
class DueCardsBanner extends ConsumerWidget {
  const DueCardsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueAsync = ref.watch(totalDueCardsProvider);

    return dueAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (dueCount) {
        if (dueCount == 0) return const SizedBox.shrink();

        final l = AppLocalizations.of(context)!;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: TapScale(
            onTap: () => context.push(Routes.quickReview),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.ctaLime,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ctaLime.withValues(alpha: 0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.ctaLimeText.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.replay_rounded,
                      color: AppColors.ctaLimeText,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.homeDueCardsBanner(dueCount),
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.ctaLimeText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l.homeDueCardsReviewNow,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.ctaLimeText.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.ctaLimeText.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
