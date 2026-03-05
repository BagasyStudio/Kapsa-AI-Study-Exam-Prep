import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';

/// "Got 2 min?" Quick Review card shown on the home screen.
///
/// Tapping it launches a micro-review session for due flashcards
/// across ALL courses. Self-hides when there are no due cards.
class QuickReviewCard extends ConsumerWidget {
  const QuickReviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCountAsync = ref.watch(totalDueCardsProvider);

    return dueCountAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        return _QuickReviewContent(dueCount: count);
      },
    );
  }
}

class _QuickReviewContent extends StatelessWidget {
  final int dueCount;

  const _QuickReviewContent({required this.dueCount});

  String _subtitle(int count) {
    if (count == 1) return '1 card waiting for you';
    if (count <= 5) return '$count cards — takes under 2 min';
    if (count <= 15) return '$count cards — a quick 5-min session';
    return '$count cards ready for review';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = Theme.of(context).brightness;

    const accentColor = Color(0xFF8B5CF6); // violet

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: TapScale(
        onTap: () => context.push(Routes.quickReview),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: isDark ? 0.14 : 0.10),
                const Color(0xFF06B6D4)
                    .withValues(alpha: isDark ? 0.08 : 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.22 : 0.15),
            ),
          ),
          child: Row(
            children: [
              // Icon with glow
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Quick Review',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryFor(brightness),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '$dueCount',
                            style: AppTypography.caption.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(dueCount),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedFor(brightness),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: accentColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
