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
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/models/deck_model.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/deck_cover_gradient.dart';
import '../widgets/subdeck_card.dart';

/// Immersive detail screen for a parent deck with subdecks.
///
/// Handles both:
/// - Parent decks with children → full subdeck grid experience
/// - Legacy flat decks → simplified card list with study button
class DeckDetailScreen extends ConsumerWidget {
  final String deckId;

  const DeckDetailScreen({super.key, required this.deckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckAsync = ref.watch(deckProvider(deckId));

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: deckAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppErrorHandler.friendlyMessage(e),
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                TapScale(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('Go Back', style: AppTypography.button),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (deck) {
          if (deck == null) {
            return Center(
              child: Text(
                'Deck not found',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white38,
                ),
              ),
            );
          }
          return _DeckDetailContent(deck: deck);
        },
      ),
    );
  }
}

class _DeckDetailContent extends ConsumerWidget {
  final DeckModel deck;

  const _DeckDetailContent({required this.deck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childDecksAsync = ref.watch(childDecksProvider(deck.id));
    final recommendedAsync = ref.watch(recommendedSubdeckProvider(deck.id));
    final dueCountAsync =
        ref.watch(dueCardsCountForParentDeckProvider(deck.id));
    final dueCount = dueCountAsync.whenOrNull(data: (c) => c) ?? 0;

    final gradient = DeckCoverGradient.forIndex(deck.coverGradientIndex);
    final primaryColor = gradient.colors.first;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero Section ──
        SliverToBoxAdapter(
          child: _HeroSection(
            deck: deck,
            gradient: gradient,
            primaryColor: primaryColor,
            dueCount: dueCount,
          ),
        ),

        // ── CTA Section ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: _CTASection(
              deck: deck,
              primaryColor: primaryColor,
            ),
          ),
        ),

        // ── Recommended Next (if subdecks exist) ──
        childDecksAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
          error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          data: (children) {
            if (children.isEmpty) {
              // Legacy flat deck — show card preview
              return SliverToBoxAdapter(
                child: _LegacyFlatDeckSection(deck: deck),
              );
            }

            return SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Recommended ──
                  recommendedAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (recommended) {
                      if (recommended == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.xxl,
                          AppSpacing.xl,
                          0,
                        ),
                        child: _RecommendedSection(
                          recommended: recommended,
                          parentGradientIndex: deck.coverGradientIndex,
                          childIndex: children.indexOf(recommended),
                        ),
                      );
                    },
                  ),

                  // ── Included Decks Grid ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xxl,
                      AppSpacing.xl,
                      0,
                    ),
                    child: _IncludedDecksGrid(
                      children: children,
                      parentGradientIndex: deck.coverGradientIndex,
                      parentBannerUrl: deck.bannerUrl,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 120),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Hero Section
// ═══════════════════════════════════════════════════════════════════════

class _HeroSection extends StatelessWidget {
  final DeckModel deck;
  final LinearGradient gradient;
  final Color primaryColor;
  final int dueCount;

  const _HeroSection({
    required this.deck,
    required this.gradient,
    required this.primaryColor,
    required this.dueCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Background: Pexels image or gradient ──
        if (deck.hasBanner)
          SizedBox(
            height: 260,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: deck.bannerUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                decoration: BoxDecoration(gradient: gradient),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
          )
        else
          Container(
            height: 260,
            decoration: BoxDecoration(gradient: gradient),
          ),

        // ── Dark scrim overlay ──
        Container(
          height: 260,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: deck.hasBanner ? 0.30 : 0.15),
                Colors.black.withValues(alpha: deck.hasBanner ? 0.85 : 0.75),
              ],
            ),
          ),
        ),

        // ── Content overlay ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),

                // ── Navigation bar ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _GlassCircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => context.pop(),
                    ),
                    _GlassCircleButton(
                      icon: Icons.more_horiz,
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ── Title ──
                Text(
                  deck.displayTitle,
                  style: AppTypography.h1.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (deck.description != null &&
                    deck.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      deck.description!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // ── Metadata chips ──
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _MetadataChip(
                      icon: Icons.style_rounded,
                      label: '${deck.cardCount} cards',
                    ),
                    if (dueCount > 0)
                      _MetadataChip(
                        icon: Icons.schedule_rounded,
                        label: '$dueCount due',
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Progress bar ──
                // For now show a placeholder — actual progress needs
                // aggregation from child decks' SRS state
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: 0, // Will be computed from children
                    minHeight: 4,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetadataChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.immersiveBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CTA Section
// ═══════════════════════════════════════════════════════════════════════

class _CTASection extends StatelessWidget {
  final DeckModel deck;
  final Color primaryColor;

  const _CTASection({
    required this.deck,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Primary CTA (lime) ──
        TapScale(
          onTap: () {
            context.push(Routes.srsReviewPath(deck.courseId));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.ctaLime,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ctaLime.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded,
                    color: AppColors.ctaLimeText, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Study Now',
                  style: AppTypography.button.copyWith(
                    color: AppColors.ctaLimeText,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // ── Secondary actions ──
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SecondaryButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () {
                  context.push(Routes.deckListPath(deck.courseId));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white60),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Recommended Section
// ═══════════════════════════════════════════════════════════════════════

class _RecommendedSection extends ConsumerWidget {
  final DeckModel recommended;
  final int parentGradientIndex;
  final int childIndex;

  const _RecommendedSection({
    required this.recommended,
    required this.parentGradientIndex,
    required this.childIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCountAsync =
        ref.watch(dueCardsCountForDeckProvider(recommended.id));
    final dueCount = dueCountAsync.whenOrNull(data: (c) => c) ?? 0;
    final gradient = DeckCoverGradient.forChildIndex(
      parentGradientIndex,
      childIndex < 0 ? 0 : childIndex,
    );
    final gradientColor = gradient.colors.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTINUE STUDYING',
          style: AppTypography.sectionHeader.copyWith(
            color: Colors.white60,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TapScale(
          onTap: () =>
              context.push(Routes.flashcardSessionPath(recommended.id)),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.immersiveCard,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(color: AppColors.immersiveBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // ── Gradient icon ──
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // ── Info ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommended.displayTitle,
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${recommended.cardCount} cards'
                          '${dueCount > 0 ? ' \u00b7 $dueCount due' : ''}',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Arrow ──
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.immersiveSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: gradientColor,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Included Decks Grid
// ═══════════════════════════════════════════════════════════════════════

class _IncludedDecksGrid extends StatelessWidget {
  final List<DeckModel> children;
  final int parentGradientIndex;
  final String? parentBannerUrl;

  const _IncludedDecksGrid({
    required this.children,
    required this.parentGradientIndex,
    this.parentBannerUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'INCLUDED DECKS',
              style: AppTypography.sectionHeader.copyWith(
                color: Colors.white60,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${children.length}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── 2-column grid ──
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.95,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) {
            return EntranceAnimation(
              index: index,
              child: SubdeckCard(
                deck: children[index],
                parentGradientIndex: parentGradientIndex,
                childIndex: index,
                parentBannerUrl: parentBannerUrl,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Legacy Flat Deck Section
// ═══════════════════════════════════════════════════════════════════════

class _LegacyFlatDeckSection extends ConsumerWidget {
  final DeckModel deck;

  const _LegacyFlatDeckSection({required this.deck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(flashcardsProvider(deck.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FLASHCARDS',
            style: AppTypography.sectionHeader.copyWith(
              color: Colors.white60,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          cardsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text(AppErrorHandler.friendlyMessage(e)),
            data: (cards) {
              if (cards.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.immersiveCard,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.immersiveBorder),
                  ),
                  child: Center(
                    child: Text(
                      'No flashcards yet',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white38,
                      ),
                    ),
                  ),
                );
              }

              // Show first 5 cards as preview
              return Column(
                children: [
                  ...cards.take(5).map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.immersiveCard,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.immersiveBorder),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${card.questionBefore}${card.keyword}${card.questionAfter}',
                                  style:
                                      AppTypography.bodyMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  card.topic,
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  if (cards.length > 5)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        '+${cards.length - 5} more cards',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white38,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
