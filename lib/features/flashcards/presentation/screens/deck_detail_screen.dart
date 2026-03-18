import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/models/deck_model.dart';
import '../../data/models/flashcard_model.dart';
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
          child: Hero(
            tag: 'hero_deck_${deck.id}',
            // Prevent layout issues during flight
            flightShuttleBuilder: (flightContext, animation, flightDirection,
                fromHeroContext, toHeroContext) {
              return Material(
                type: MaterialType.transparency,
                child: toHeroContext.widget,
              );
            },
            child: Material(
              type: MaterialType.transparency,
              child: _HeroSection(
                deck: deck,
                gradient: gradient,
                primaryColor: primaryColor,
                dueCount: dueCount,
              ),
            ),
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

        // ── Deck Statistics (#16) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: _DeckStatsSection(deckId: deck.id),
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

class _HeroSection extends ConsumerWidget {
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

  // UX-08: Estimate study time from due cards
  String _estimateTime(int cards) {
    if (cards <= 0) return '';
    final minutes = (cards * 15 / 60).ceil(); // ~15s per card
    if (minutes < 1) return '< 1 min';
    if (minutes >= 60) return '~${minutes ~/ 60}h ${minutes % 60}min';
    return '~$minutes min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // UX-03: Bookmark count
    final bookmarkCountAsync =
        ref.watch(bookmarkedCardsCountProvider(deck.id));
    final bookmarkCount =
        bookmarkCountAsync.whenOrNull(data: (c) => c) ?? 0;

    // UX-10: Real progress bar — count reviewed cards vs total
    final cardsAsync = ref.watch(flashcardsProvider(deck.id));
    final totalCards = deck.cardCount;
    double progress = 0;
    int reviewedCount = 0;
    if (totalCards > 0) {
      final cards = cardsAsync.whenOrNull(data: (c) => c);
      if (cards != null) {
        reviewedCount = cards.where((c) => c.lastReview != null).length;
        progress = reviewedCount / totalCards;
      }
    }

    // UX-10: Progress color based on percentage
    final progressColor = progress < 0.3
        ? const Color(0xFFEF4444)
        : progress < 0.6
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);

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
                    // UX-11: Deck menu (delete)
                    _DeckMenuButton(deck: deck),
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

                // ── Metadata chips ── (UX-08: time estimate)
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
                        label: '$dueCount due · ${_estimateTime(dueCount)}',
                      ),
                    if (bookmarkCount > 0)
                      _MetadataChip(
                        icon: Icons.bookmark_rounded,
                        label: '$bookmarkCount bookmarked',
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // ── UX-10: Real progress bar ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      ),
                    ),
                    if (totalCards > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$reviewedCount/$totalCards studied',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UX-11: Deck Menu Button (Delete, Rename)
// ═══════════════════════════════════════════════════════════════════════

class _DeckMenuButton extends ConsumerWidget {
  final DeckModel deck;

  const _DeckMenuButton({required this.deck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuAction(context, ref, value),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      color: AppColors.immersiveCard,
      offset: const Offset(0, 44),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'export_csv',
          child: Row(
            children: [
              const Icon(Icons.file_download_outlined, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'Export as CSV',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'customize',
          child: Row(
            children: [
              const Icon(Icons.palette_outlined, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'Customize',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Delete Deck',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'export_csv') {
      _exportAsCsv(context, ref);
    } else if (action == 'customize') {
      _showCustomizeSheet(context);
    } else if (action == 'delete') {
      _showDeleteConfirmation(context, ref);
    }
  }

  void _showCustomizeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.immersiveCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DeckCustomizeSheet(deckId: deck.id),
    );
  }

  Future<void> _exportAsCsv(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(flashcardRepositoryProvider);

      // Collect cards: if parent deck, gather from all child subdecks;
      // otherwise get cards directly from this deck.
      List<FlashcardModel> allCards = [];

      if (deck.isParent) {
        final children = await repo.getChildDecks(deck.id);
        for (final child in children) {
          final cards = await repo.getCards(child.id);
          allCards.addAll(cards);
        }
      }

      // Also get direct cards on this deck (flat or legacy decks)
      final directCards = await repo.getCards(deck.id);
      allCards.addAll(directCards);

      if (allCards.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No cards to export'),
              backgroundColor: AppColors.immersiveCard,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      // Build CSV string
      final buffer = StringBuffer();
      buffer.writeln('Question,Answer,Keyword,Topic');
      for (final card in allCards) {
        buffer.writeln(
          '${_escapeCsv(card.questionBefore + card.keyword + card.questionAfter)},'
          '${_escapeCsv(card.answer)},'
          '${_escapeCsv(card.keyword)},'
          '${_escapeCsv(card.topic)}',
        );
      }

      await SharePlus.instance.share(
        ShareParams(
          text: buffer.toString(),
          title: '${deck.displayTitle}.csv',
        ),
      );

      if (context.mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Deck exported \u2713'),
              ],
            ),
            backgroundColor: AppColors.immersiveCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.friendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Escapes a value for CSV: wraps in quotes and doubles internal quotes.
  static String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.immersiveCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text(
          'Delete Deck',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${deck.displayTitle}"? '
          'This will remove all ${deck.cardCount} cards. '
          'This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white60,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(flashcardRepositoryProvider)
                    .deleteDeck(deck.id);
                HapticFeedback.mediumImpact();
                ref.invalidate(flashcardDecksProvider(deck.courseId));
                ref.invalidate(parentDecksProvider(deck.courseId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('Deck deleted'),
                        ],
                      ),
                      backgroundColor: AppColors.immersiveCard,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppErrorHandler.friendlyMessage(e)),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
                icon: Icons.bolt_rounded,
                label: 'Cram',
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(Routes.cramModePath(deck.id));
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SecondaryButton(
                icon: Icons.swap_vert_rounded,
                label: 'Reverse',
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(Routes.srsReviewPath(deck.courseId, reverse: true));
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SecondaryButton(
                icon: Icons.keyboard_rounded,
                label: 'Typing',
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(Routes.flashcardTypingPath(deck.id));
                },
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
// Deck Statistics Section (#16)
// ═══════════════════════════════════════════════════════════════════════

class _DeckStatsSection extends ConsumerStatefulWidget {
  final String deckId;

  const _DeckStatsSection({required this.deckId});

  @override
  ConsumerState<_DeckStatsSection> createState() => _DeckStatsSectionState();
}

class _DeckStatsSectionState extends ConsumerState<_DeckStatsSection> {
  bool _isExpanded = false;

  /// Format a relative time string like "2h ago", "3d ago", etc.
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 30}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final allCardsAsync =
        ref.watch(allCardsForParentDeckProvider(widget.deckId));
    final studyStatsAsync =
        ref.watch(deckStudyStatsProvider(widget.deckId));

    return allCardsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (cards) {
        if (cards.isEmpty) return const SizedBox.shrink();

        // ── Compute mastery breakdown ──
        final newCount =
            cards.where((c) => c.srsState == 0).length;
        final learningCount = cards
            .where((c) => c.srsState == 1 || c.srsState == 3)
            .length;
        final reviewCount =
            cards.where((c) => c.srsState == 2).length;
        final total = cards.length;

        // ── Compute averages ──
        final avgStability = cards.fold<double>(
                0, (sum, c) => sum + c.stability) /
            cards.length;
        final avgDifficulty = cards.fold<double>(
                0, (sum, c) => sum + c.difficulty) /
            cards.length;

        // ── Study intensity ──
        final studyStats =
            studyStatsAsync.whenOrNull(data: (s) => s);
        final reviewsThisWeek =
            (studyStats?['count'] as int?) ?? 0;
        final lastReviewedAt =
            studyStats?['lastReviewedAt'] as DateTime?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header with expand/collapse ──
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isExpanded = !_isExpanded);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.immersiveCard,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.immersiveBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Statistics',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // ── Compact mastery summary (always visible) ──
                    _MiniMasteryDots(
                      newCount: newCount,
                      learningCount: learningCount,
                      reviewCount: reviewCount,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded content ──
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.immersiveCard,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.immersiveBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. Mastery Breakdown Bar ──
                      Text(
                        'MASTERY BREAKDOWN',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white38,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _MasteryBreakdownBar(
                        newCount: newCount,
                        learningCount: learningCount,
                        reviewCount: reviewCount,
                        total: total,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$newCount New  \u00b7  $learningCount Learning  \u00b7  $reviewCount Review',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── 2. Average Stats ──
                      Text(
                        'AVERAGES',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white38,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.shield_rounded,
                            label:
                                'Avg stability: ${avgStability.toStringAsFixed(1)}d',
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _StatChip(
                            icon: Icons.trending_up_rounded,
                            label:
                                'Avg difficulty: ${avgDifficulty.toStringAsFixed(1)}/10',
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── 3. Study Intensity ──
                      Text(
                        'STUDY ACTIVITY',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white38,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.local_fire_department_rounded,
                            label:
                                'Studied $reviewsThisWeek times this week',
                          ),
                          if (lastReviewedAt != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _StatChip(
                              icon: Icons.access_time_rounded,
                              label:
                                  'Last: ${_formatTimeAgo(lastReviewedAt)}',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        );
      },
    );
  }
}

/// Compact colored dots showing mastery proportions in the collapsed header.
class _MiniMasteryDots extends StatelessWidget {
  final int newCount;
  final int learningCount;
  final int reviewCount;

  const _MiniMasteryDots({
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(AppColors.info, newCount),
        const SizedBox(width: 3),
        _dot(AppColors.warning, learningCount),
        const SizedBox(width: 3),
        _dot(AppColors.success, reviewCount),
      ],
    );
  }

  Widget _dot(Color color, int count) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Segmented horizontal bar showing proportional mastery breakdown.
class _MasteryBreakdownBar extends StatelessWidget {
  final int newCount;
  final int learningCount;
  final int reviewCount;
  final int total;

  const _MasteryBreakdownBar({
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (newCount > 0)
              Expanded(
                flex: newCount,
                child: Container(color: AppColors.info),
              ),
            if (learningCount > 0)
              Expanded(
                flex: learningCount,
                child: Container(color: AppColors.warning),
              ),
            if (reviewCount > 0)
              Expanded(
                flex: reviewCount,
                child: Container(color: AppColors.success),
              ),
          ],
        ),
      ),
    );
  }
}

/// A compact stat chip with icon and label.
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.immersiveSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 13),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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

class _LegacyFlatDeckSection extends ConsumerStatefulWidget {
  final DeckModel deck;

  const _LegacyFlatDeckSection({required this.deck});

  @override
  ConsumerState<_LegacyFlatDeckSection> createState() =>
      _LegacyFlatDeckSectionState();
}

/// Filter chip identifiers for SRS state filtering.
enum _SrsFilter { all, newCard, learning, review, due, bookmarked }

class _LegacyFlatDeckSectionState
    extends ConsumerState<_LegacyFlatDeckSection> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  Set<_SrsFilter> _activeFilters = {_SrsFilter.all};

  // ── Bulk selection (#16) ──
  bool _isSelectionMode = false;
  final Set<String> _selectedCardIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  // ── Bulk selection helpers (#16) ──

  void _enterSelectionMode(String cardId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedCardIds.add(cardId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedCardIds.clear();
    });
  }

  void _toggleCardSelection(String cardId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedCardIds.contains(cardId)) {
        _selectedCardIds.remove(cardId);
        if (_selectedCardIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedCardIds.add(cardId);
      }
    });
  }

  void _selectAll(List<FlashcardModel> cards) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCardIds.addAll(cards.map((c) => c.id));
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedCardIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.immersiveCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text(
          'Delete $count Card${count == 1 ? '' : 's'}',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete $count selected card${count == 1 ? '' : 's'}? '
          'This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white60,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(flashcardRepositoryProvider)
          .deleteCardsByIds(_selectedCardIds.toList());
      HapticFeedback.mediumImpact();
      ref.invalidate(flashcardsProvider(widget.deck.id));
      ref.invalidate(allCardsForParentDeckProvider(widget.deck.id));
      ref.invalidate(deckProvider(widget.deck.id));
      _exitSelectionMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('$count card${count == 1 ? '' : 's'} deleted'),
              ],
            ),
            backgroundColor: AppColors.immersiveCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.friendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onFilterTap(_SrsFilter filter) {
    setState(() {
      if (filter == _SrsFilter.all) {
        // "All" deselects everything else
        _activeFilters = {_SrsFilter.all};
      } else {
        // Remove "All" if it was selected, toggle the tapped filter
        _activeFilters.remove(_SrsFilter.all);
        if (_activeFilters.contains(filter)) {
          _activeFilters.remove(filter);
        } else {
          _activeFilters.add(filter);
        }
        // If nothing is selected, revert to "All"
        if (_activeFilters.isEmpty) {
          _activeFilters = {_SrsFilter.all};
        }
      }
    });
  }

  /// Apply search query and SRS filter chips to produce filtered list.
  List<FlashcardModel> _applyFilters(List<FlashcardModel> cards) {
    var result = cards;

    // ── Search filter ──
    if (_searchQuery.isNotEmpty) {
      result = result.where((card) {
        final question =
            '${card.questionBefore}${card.keyword}${card.questionAfter}'
                .toLowerCase();
        final keyword = card.keyword.toLowerCase();
        final topic = card.topic.toLowerCase();
        return question.contains(_searchQuery) ||
            keyword.contains(_searchQuery) ||
            topic.contains(_searchQuery);
      }).toList();
    }

    // ── SRS filter chips ──
    if (!_activeFilters.contains(_SrsFilter.all)) {
      result = result.where((card) {
        for (final filter in _activeFilters) {
          switch (filter) {
            case _SrsFilter.newCard:
              if (card.srsState == 0) return true;
            case _SrsFilter.learning:
              if (card.srsState == 1 || card.srsState == 3) return true;
            case _SrsFilter.review:
              if (card.srsState == 2) return true;
            case _SrsFilter.due:
              if (card.isDue) return true;
            case _SrsFilter.bookmarked:
              if (card.isBookmarked) return true;
            case _SrsFilter.all:
              return true;
          }
        }
        return false;
      }).toList();
    }

    return result;
  }

  /// Count cards matching each filter (for chip badge counts).
  int _countForFilter(List<FlashcardModel> cards, _SrsFilter filter) {
    switch (filter) {
      case _SrsFilter.all:
        return cards.length;
      case _SrsFilter.newCard:
        return cards.where((c) => c.srsState == 0).length;
      case _SrsFilter.learning:
        return cards.where((c) => c.srsState == 1 || c.srsState == 3).length;
      case _SrsFilter.review:
        return cards.where((c) => c.srsState == 2).length;
      case _SrsFilter.due:
        return cards.where((c) => c.isDue).length;
      case _SrsFilter.bookmarked:
        return cards.where((c) => c.isBookmarked).length;
    }
  }

  String _filterLabel(_SrsFilter filter) {
    switch (filter) {
      case _SrsFilter.all:
        return 'All';
      case _SrsFilter.newCard:
        return 'New';
      case _SrsFilter.learning:
        return 'Learning';
      case _SrsFilter.review:
        return 'Review';
      case _SrsFilter.due:
        return 'Due';
      case _SrsFilter.bookmarked:
        return 'Bookmarked';
    }
  }

  IconData _filterIcon(_SrsFilter filter) {
    switch (filter) {
      case _SrsFilter.all:
        return Icons.select_all_rounded;
      case _SrsFilter.newCard:
        return Icons.fiber_new_rounded;
      case _SrsFilter.learning:
        return Icons.school_rounded;
      case _SrsFilter.review:
        return Icons.rate_review_rounded;
      case _SrsFilter.due:
        return Icons.schedule_rounded;
      case _SrsFilter.bookmarked:
        return Icons.bookmark_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(flashcardsProvider(widget.deck.id));

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

              final filteredCards = _applyFilters(cards);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Selection toolbar (#16) ──
                  if (_isSelectionMode)
                    _buildSelectionToolbar(filteredCards),

                  // ── Search bar ──
                  if (!_isSelectionMode)
                    _buildSearchBar(),
                  if (!_isSelectionMode)
                    const SizedBox(height: AppSpacing.sm),

                  // ── Filter chips ──
                  if (!_isSelectionMode)
                    _buildFilterChips(cards),
                  if (!_isSelectionMode)
                    const SizedBox(height: AppSpacing.sm),

                  // ── Result count ──
                  if (!_isSelectionMode &&
                      (_searchQuery.isNotEmpty ||
                          !_activeFilters.contains(_SrsFilter.all)))
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        '${filteredCards.length} card${filteredCards.length == 1 ? '' : 's'} found',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white38,
                        ),
                      ),
                    ),

                  // ── Card list ──
                  if (filteredCards.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.immersiveCard,
                        borderRadius:
                            BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                            color: AppColors.immersiveBorder),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              color: Colors.white38,
                              size: 32,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'No cards match your filters',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredCards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm),
                        child: _buildCardTile(card),
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.immersiveBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: AppTypography.bodySmall.copyWith(color: Colors.white),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: 'Search by question, keyword, or topic...',
          hintStyle: AppTypography.bodySmall.copyWith(
            color: Colors.white38,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.white38,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white60,
                    size: 18,
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<FlashcardModel> allCards) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _SrsFilter.values.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final filter = _SrsFilter.values[index];
          final isSelected = _activeFilters.contains(filter);
          final count = _countForFilter(allCards, filter);

          return ChoiceChip(
            label: Text(
              '${_filterLabel(filter)} ($count)',
              style: AppTypography.caption.copyWith(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
            ),
            avatar: Icon(
              _filterIcon(filter),
              size: 14,
              color: isSelected ? Colors.white : Colors.white38,
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.immersiveCard,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.immersiveBorder,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => _onFilterTap(filter),
          );
        },
      ),
    );
  }

  // ── Selection toolbar widget (#16) ──
  Widget _buildSelectionToolbar(List<FlashcardModel> filteredCards) {
    final count = _selectedCardIds.length;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$count selected',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Select All
          TapScale(
            onTap: () => _selectAll(filteredCards),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Select All',
                style: AppTypography.caption.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Delete Selected
          TapScale(
            onTap: count > 0 ? _deleteSelected : null,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text(
                    'Delete',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Cancel
          TapScale(
            onTap: _exitSelectionMode,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Cancel',
                style: AppTypography.caption.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(FlashcardModel card) {
    final isSelected = _selectedCardIds.contains(card.id);

    return TapScale(
      onTap: _isSelectionMode
          ? () => _toggleCardSelection(card.id)
          : () => _showEditCardSheet(context, card),
      onLongPress: _isSelectionMode
          ? null
          : () => _enterSelectionMode(card.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.immersiveBorder,
          ),
        ),
        child: Row(
          children: [
            // ── Checkbox (selection mode) ──
            if (_isSelectionMode) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white38,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],

            // ── Card content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${card.questionBefore}${card.keyword}${card.questionAfter}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (card.isBookmarked)
                        Padding(
                          padding:
                              const EdgeInsets.only(left: AppSpacing.xs),
                          child: Icon(
                            Icons.bookmark_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                      if (!_isSelectionMode)
                        // Edit icon hint
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: Icon(
                            Icons.edit_outlined,
                            color: Colors.white24,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.topic,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildSrsStateBadge(card),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCardSheet(BuildContext context, FlashcardModel card) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.immersiveCard,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusSheet,
      ),
      builder: (ctx) => _EditCardSheet(
        card: card,
        onSaved: () {
          ref.invalidate(flashcardsProvider(widget.deck.id));
          ref.invalidate(allCardsForParentDeckProvider(widget.deck.id));
        },
      ),
    );
  }

  Widget _buildSrsStateBadge(FlashcardModel card) {
    final String label;
    final Color color;
    switch (card.srsState) {
      case 0:
        label = 'New';
        color = AppColors.info;
      case 1:
        label = 'Learning';
        color = AppColors.warning;
      case 2:
        label = 'Review';
        color = AppColors.success;
      case 3:
        label = 'Relearning';
        color = AppColors.warning;
      default:
        label = 'New';
        color = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// #33: Deck Customize Sheet (Font Size + Theme Color)
// ═══════════════════════════════════════════════════════════════════════

class _DeckCustomizeSheet extends StatefulWidget {
  final String deckId;

  const _DeckCustomizeSheet({required this.deckId});

  @override
  State<_DeckCustomizeSheet> createState() => _DeckCustomizeSheetState();
}

class _DeckCustomizeSheetState extends State<_DeckCustomizeSheet> {
  double _currentFontSize = 14;
  int _selectedColorIndex = 0;

  // Font size options: Small / Normal / Large / XLarge
  static const _fontOptions = <String, double>{
    'Small': 12,
    'Normal': 14,
    'Large': 16,
    'Extra Large': 20,
  };

  // Theme color presets
  static const _themeColors = <_ThemeColorOption>[
    _ThemeColorOption('Primary', Color(0xFF6467F2)),
    _ThemeColorOption('Lime', Color(0xFF84CC16)),
    _ThemeColorOption('Blue', Color(0xFF3B82F6)),
    _ThemeColorOption('Purple', Color(0xFF8B5CF6)),
    _ThemeColorOption('Amber', Color(0xFFF59E0B)),
    _ThemeColorOption('Rose', Color(0xFFF43F5E)),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentFontSize =
            prefs.getDouble('deck_font_size_${widget.deckId}') ?? 14;
        _selectedColorIndex =
            prefs.getInt('deck_color_${widget.deckId}') ?? 0;
      });
    }
  }

  Future<void> _saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('deck_font_size_${widget.deckId}', size);
    setState(() => _currentFontSize = size);
  }

  Future<void> _saveColor(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('deck_color_${widget.deckId}', index);
    setState(() => _selectedColorIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Title ──
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Customize Deck',
                  style: AppTypography.h4.copyWith(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Personalize how this deck looks during review',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white38,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ════════════════════════════════════
            // Card Font Size
            // ════════════════════════════════════
            Text(
              'CARD FONT SIZE',
              style: AppTypography.caption.copyWith(
                color: Colors.white38,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            ..._fontOptions.entries.map((entry) {
              final isSelected = _currentFontSize == entry.value;
              return TapScale(
                onTap: () => _saveFontSize(entry.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: isSelected
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: entry.value,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? AppColors.primary : Colors.white60,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          '${entry.key} (${entry.value.toInt()})',
                          style: AppTypography.labelLarge.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle,
                            color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: AppSpacing.lg),

            // ════════════════════════════════════
            // Theme Color
            // ════════════════════════════════════
            Text(
              'THEME COLOR',
              style: AppTypography.caption.copyWith(
                color: Colors.white38,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_themeColors.length, (index) {
                final option = _themeColors[index];
                final isSelected = _selectedColorIndex == index;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _saveColor(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 2,
                            ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: option.color.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 22,
                          )
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Label for the selected color
            Center(
              child: Text(
                _themeColors[_selectedColorIndex].label,
                style: AppTypography.caption.copyWith(
                  color: _themeColors[_selectedColorIndex].color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Done button ──
            TapScale(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Text(
                    'Done',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Data class for theme color presets.
class _ThemeColorOption {
  final String label;
  final Color color;

  const _ThemeColorOption(this.label, this.color);
}

// ═══════════════════════════════════════════════════════════════════════
// Edit Card Bottom Sheet (#15)
// ═══════════════════════════════════════════════════════════════════════

class _EditCardSheet extends ConsumerStatefulWidget {
  final FlashcardModel card;
  final VoidCallback onSaved;

  const _EditCardSheet({required this.card, required this.onSaved});

  @override
  ConsumerState<_EditCardSheet> createState() => _EditCardSheetState();
}

class _EditCardSheetState extends ConsumerState<_EditCardSheet> {
  late final TextEditingController _questionBeforeCtrl;
  late final TextEditingController _keywordCtrl;
  late final TextEditingController _questionAfterCtrl;
  late final TextEditingController _answerCtrl;
  late final TextEditingController _topicCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _questionBeforeCtrl =
        TextEditingController(text: widget.card.questionBefore);
    _keywordCtrl = TextEditingController(text: widget.card.keyword);
    _questionAfterCtrl =
        TextEditingController(text: widget.card.questionAfter);
    _answerCtrl = TextEditingController(text: widget.card.answer);
    _topicCtrl = TextEditingController(text: widget.card.topic);
  }

  @override
  void dispose() {
    _questionBeforeCtrl.dispose();
    _keywordCtrl.dispose();
    _questionAfterCtrl.dispose();
    _answerCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_keywordCtrl.text.trim().isEmpty || _answerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Keyword and answer are required',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(flashcardRepositoryProvider).updateCard(
            cardId: widget.card.id,
            questionBefore: _questionBeforeCtrl.text.trim(),
            keyword: _keywordCtrl.text.trim(),
            questionAfter: _questionAfterCtrl.text.trim(),
            answer: _answerCtrl.text.trim(),
            topic: _topicCtrl.text.trim(),
          );
      HapticFeedback.mediumImpact();
      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Card updated \u2713',
                  style:
                      AppTypography.bodySmall.copyWith(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: AppColors.immersiveCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorHandler.friendlyMessage(e),
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle bar ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Title ──
              Text(
                'Edit Card',
                style: AppTypography.h4.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Question Before ──
              _buildLabel('Question (before keyword)'),
              const SizedBox(height: AppSpacing.xs),
              _buildTextField(_questionBeforeCtrl, 'e.g. What is the...'),
              const SizedBox(height: AppSpacing.md),

              // ── Keyword ──
              _buildLabel('Keyword'),
              const SizedBox(height: AppSpacing.xs),
              _buildTextField(_keywordCtrl, 'Main keyword'),
              const SizedBox(height: AppSpacing.md),

              // ── Question After ──
              _buildLabel('Question (after keyword)'),
              const SizedBox(height: AppSpacing.xs),
              _buildTextField(_questionAfterCtrl, 'e.g. ...used for?'),
              const SizedBox(height: AppSpacing.md),

              // ── Answer ──
              _buildLabel('Answer'),
              const SizedBox(height: AppSpacing.xs),
              _buildTextField(_answerCtrl, 'Answer text', maxLines: 3),
              const SizedBox(height: AppSpacing.md),

              // ── Topic ──
              _buildLabel('Topic'),
              const SizedBox(height: AppSpacing.xs),
              _buildTextField(_topicCtrl, 'e.g. Biology'),
              const SizedBox(height: AppSpacing.xl),

              // ── Save button ──
              TapScale(
                onTap: _isSaving ? null : _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.caption.copyWith(
        color: Colors.white38,
        letterSpacing: 1,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.immersiveSurface,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: AppColors.immersiveBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: AppTypography.bodySmall.copyWith(color: Colors.white),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodySmall.copyWith(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }
}
