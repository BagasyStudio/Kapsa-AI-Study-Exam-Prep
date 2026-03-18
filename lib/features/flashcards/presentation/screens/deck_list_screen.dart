import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/kapsa_refresh_indicator.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../providers/flashcard_provider.dart';
import '../../data/models/deck_model.dart';
import '../widgets/deck_cover_gradient.dart';

/// Sort modes for the deck list.
enum _SortMode { recent, nameAz, dueDesc }

/// Screen showing all flashcard decks for a course.
///
/// Users can review past decks or start a new session.
class DeckListScreen extends ConsumerStatefulWidget {
  final String courseId;

  const DeckListScreen({super.key, required this.courseId});

  @override
  ConsumerState<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends ConsumerState<DeckListScreen> {
  _SortMode _sortMode = _SortMode.recent;

  /// Returns a sorted copy of the deck list based on the current sort mode.
  List<DeckModel> _sortedDecks(List<DeckModel> decks) {
    final sorted = List<DeckModel>.from(decks);
    switch (_sortMode) {
      case _SortMode.recent:
        // Default order: by created_at descending (newest first).
        sorted.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(2000);
          final bDate = b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
      case _SortMode.nameAz:
        sorted.sort((a, b) =>
            a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()));
      case _SortMode.dueDesc:
        // Use cardCount as proxy for pending workload.
        sorted.sort((a, b) => b.cardCount.compareTo(a.cardCount));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final decksAsync = ref.watch(parentDecksProvider(widget.courseId));

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
              ),
              child: Row(
                children: [
                  TapScale(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Icon(Icons.arrow_back,
                          color: Colors.white60),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Flashcard Decks',
                      style: AppTypography.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TapScale(
                    onTap: () =>
                        context.push(Routes.importDeckPath(widget.courseId)),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Icon(Icons.download_rounded,
                          color: Colors.white60,
                          size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Sort chip bar
            _buildSortChips(),

            const SizedBox(height: AppSpacing.md),

            // Deck list
            Expanded(
              child: decksAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: ShimmerList(count: 4, itemHeight: 80),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      AppErrorHandler.friendlyMessage(e),
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white38,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (decks) {
                  if (decks.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  final sortedDecks = _sortedDecks(decks);
                  return KapsaRefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(parentDecksProvider(widget.courseId));
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        0,
                        AppSpacing.xl,
                        MediaQuery.of(context).padding.bottom + 24,
                      ),
                      child: StaggeredColumn(
                        children: sortedDecks.map((deck) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.md),
                            child: _DeckCard(deck: deck),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChips() {
    const chipData = <_SortMode, String>{
      _SortMode.recent: 'Recientes',
      _SortMode.nameAz: 'A-Z',
      _SortMode.dueDesc: 'Pendientes \u2193',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: chipData.entries.map((entry) {
          final isSelected = _sortMode == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(
                entry.value,
                style: AppTypography.caption.copyWith(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _sortMode = entry.key);
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.immersiveCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.style,
                size: 36,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No decks yet',
              style: AppTypography.h3.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Generate flashcards from your course materials to start studying.',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckCard extends ConsumerWidget {
  final DeckModel deck;

  const _DeckCard({required this.deck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeAgo = _formatTimeAgo(deck.createdAt);
    final dueCount = ref
        .watch(dueCardsCountForDeckProvider(deck.id))
        .whenOrNull(data: (c) => c) ?? 0;

    return TapScale(
      onTap: () => context.push(Routes.deckDetailPath(deck.id)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            // Icon with optional due badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: DeckCoverGradient.forIndex(deck.coverGradientIndex),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.style, color: Colors.white, size: 22),
                ),
                // Due count badge
                if (dueCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$dueCount',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.displayTitle,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.layers,
                          size: 13,
                          color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        '${deck.cardCount} cards',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 13,
                          color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white38,
                        ),
                      ),
                      // Due indicator text
                      if (dueCount > 0) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.schedule,
                            size: 13,
                            color: const Color(0xFFFBBF24)),
                        const SizedBox(width: 4),
                        Text(
                          '$dueCount due',
                          style: AppTypography.caption.copyWith(
                            color: const Color(0xFFFBBF24),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.play_arrow_rounded,
                color: Colors.white38, size: 24),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
