import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../flashcards/data/models/deck_model.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../flashcards/presentation/widgets/deck_cover_gradient.dart';

/// Section showing parent flashcard decks for the selected course in a 2-column grid.
class HomeDeckGrid extends ConsumerWidget {
  final String courseId;
  const HomeDeckGrid({super.key, required this.courseId});

  static const _maxVisible = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final decksAsync = ref.watch(parentDecksProvider(courseId));

    return decksAsync.when(
      loading: () => const _DeckGridShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (decks) {
        if (decks.isEmpty) return _EmptyDecks(label: l.homeNoDecksYet);

        final visible = decks.length > _maxVisible
            ? decks.sublist(0, _maxVisible)
            : decks;
        final hasMore = decks.length > _maxVisible;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    l.homeFlashcardDecks,
                    style: AppTypography.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${decks.length}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TapScale(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push(Routes.deckListPath(courseId));
                    },
                    child: Text(
                      l.homeSeeAll,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // 2-column grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.85,
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) =>
                    _HomeDeckCard(deck: visible[index]),
              ),

              // "View all" link
              if (hasMore) ...[
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TapScale(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push(Routes.deckListPath(courseId));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        l.homeViewAllDecks(decks.length),
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Compact card for a parent deck in the home grid.
class _HomeDeckCard extends ConsumerWidget {
  final DeckModel deck;
  const _HomeDeckCard({required this.deck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueAsync = ref.watch(dueCardsCountForParentDeckProvider(deck.id));
    final dueCount = dueAsync.whenOrNull(data: (c) => c) ?? 0;
    final gradient = DeckCoverGradient.forIndex(deck.coverGradientIndex);
    final primaryColor = gradient.colors.first;

    return TapScale(
      onTap: () => context.push(Routes.deckDetailPath(deck.id)),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient top strip
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg - 1),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.style_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 24,
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      deck.displayTitle,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Card count
                    Text(
                      '${deck.cardCount} card${deck.cardCount == 1 ? '' : 's'}',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),

                    const Spacer(),

                    // Due badge
                    if (dueCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$dueCount due',
                          style: AppTypography.caption.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'up to date',
                          style: AppTypography.caption.copyWith(
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact empty state for no decks.
class _EmptyDecks extends StatelessWidget {
  final String label;
  const _EmptyDecks({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.style_rounded,
              color: Colors.white24,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: Colors.white38),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading shimmer for the deck grid.
class _DeckGridShimmer extends StatelessWidget {
  const _DeckGridShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Container(
            width: 140,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Grid shimmer
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
