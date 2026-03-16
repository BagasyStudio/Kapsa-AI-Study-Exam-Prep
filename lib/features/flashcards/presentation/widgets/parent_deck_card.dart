import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/deck_model.dart';
import '../providers/flashcard_provider.dart';
import 'deck_cover_gradient.dart';

/// Card widget for a parent deck, used in the "Past Decks" section
/// of the Study Tools tab and the Deck List screen.
class ParentDeckCard extends ConsumerWidget {
  final DeckModel deck;

  const ParentDeckCard({super.key, required this.deck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childDecksAsync = ref.watch(childDecksProvider(deck.id));
    final childCount =
        childDecksAsync.whenOrNull(data: (c) => c.length) ?? 0;
    final dueAsync =
        ref.watch(dueCardsCountForParentDeckProvider(deck.id));
    final dueCount = dueAsync.whenOrNull(data: (c) => c) ?? 0;

    final gradient = DeckCoverGradient.forIndex(deck.coverGradientIndex);
    final primaryColor = gradient.colors.first;

    return TapScale(
      onTap: () => context.push(Routes.deckDetailPath(deck.id)),
      child: GlassPanel(
        tier: GlassTier.subtle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // ── Gradient icon ──
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.style_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.displayTitle,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(childCount),
                      style: AppTypography.caption.copyWith(
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Due badge ──
              if (dueCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$dueCount due',
                    style: AppTypography.caption.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),

              const SizedBox(width: AppSpacing.xs),

              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(int childCount) {
    final cards = '${deck.cardCount} card${deck.cardCount == 1 ? '' : 's'}';
    if (childCount > 0) {
      return '$cards \u00b7 $childCount topic${childCount == 1 ? '' : 's'}';
    }
    return cards;
  }
}
