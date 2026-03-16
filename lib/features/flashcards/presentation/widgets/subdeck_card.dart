import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/deck_model.dart';
import '../providers/flashcard_provider.dart';
import 'deck_cover_gradient.dart';

/// Card widget for a child subdeck displayed in the "Included Decks" grid.
class SubdeckCard extends ConsumerWidget {
  final DeckModel deck;
  final int parentGradientIndex;
  final int childIndex;
  final bool isRecommended;
  final String? parentBannerUrl;

  const SubdeckCard({
    super.key,
    required this.deck,
    required this.parentGradientIndex,
    required this.childIndex,
    this.isRecommended = false,
    this.parentBannerUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCountAsync =
        ref.watch(dueCardsCountForDeckProvider(deck.id));
    final dueCount = dueCountAsync.whenOrNull(data: (c) => c) ?? 0;
    final gradient = DeckCoverGradient.forChildIndex(
      parentGradientIndex,
      childIndex,
    );
    final gradientColor = gradient.colors.first;

    final effectiveBanner = deck.bannerUrl ?? parentBannerUrl;

    return TapScale(
      onTap: () => context.push(Routes.flashcardSessionPath(deck.id)),
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
            // ── Banner image or gradient strip ──
            if (effectiveBanner != null)
              SizedBox(
                height: 72,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: effectiveBanner,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        decoration: BoxDecoration(gradient: gradient),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        decoration: BoxDecoration(gradient: gradient),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.immersiveCard,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                ),
              ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                effectiveBanner != null ? 0 : AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──
                  Text(
                    deck.displayTitle,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // ── Card count ──
                  Text(
                    '${deck.cardCount} card${deck.cardCount == 1 ? '' : 's'}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white54,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Status badge ──
                  _StatusBadge(
                    dueCount: dueCount,
                    totalCards: deck.cardCount,
                    color: gradientColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status badge showing "new", "X due", or "mastered".
class _StatusBadge extends StatelessWidget {
  final int dueCount;
  final int totalCards;
  final Color color;

  const _StatusBadge({
    required this.dueCount,
    required this.totalCards,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color badgeColor;

    if (dueCount > 0) {
      label = '$dueCount due';
      badgeColor = color;
    } else if (totalCards == 0) {
      label = 'empty';
      badgeColor = Colors.white38;
    } else {
      // No due cards and has cards → either new or all caught up
      label = 'up to date';
      badgeColor = const Color(0xFF10B981); // Success green
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
