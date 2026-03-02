import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../providers/flashcard_provider.dart';
import '../../data/models/deck_model.dart';

/// Screen showing all flashcard decks for a course.
///
/// Users can review past decks or start a new session.
class DeckListScreen extends ConsumerWidget {
  final String courseId;

  const DeckListScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(flashcardDecksProvider(courseId));
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
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
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.45),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Icon(Icons.arrow_back,
                          color: AppColors.textSecondaryFor(brightness)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Flashcard Decks',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TapScale(
                    onTap: () =>
                        context.push(Routes.importDeckPath(courseId)),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.45),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Icon(Icons.download_rounded,
                          color: AppColors.textSecondaryFor(brightness),
                          size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

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
                        color: AppColors.textMutedFor(brightness),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (decks) {
                  if (decks.isEmpty) {
                    return _buildEmptyState(context, brightness);
                  }
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      MediaQuery.of(context).padding.bottom + 24,
                    ),
                    child: StaggeredColumn(
                      children: decks.map((deck) {
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.md),
                          child: _DeckCard(deck: deck),
                        );
                      }).toList(),
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

  Widget _buildEmptyState(BuildContext context, Brightness brightness) {
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
                color: AppColors.textPrimaryFor(brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Generate flashcards from your course materials to start studying.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedFor(brightness),
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final timeAgo = _formatTimeAgo(deck.createdAt);
    final dueCount = ref
        .watch(dueCardsCountForDeckProvider(deck.id))
        .whenOrNull(data: (c) => c) ?? 0;

    return TapScale(
      onTap: () => context.push(Routes.flashcardSessionPath(deck.id)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.6),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
                    ),
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
                    deck.title,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimaryFor(brightness),
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
                          color: AppColors.textMutedFor(brightness)),
                      const SizedBox(width: 4),
                      Text(
                        '${deck.cardCount} cards',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMutedFor(brightness),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 13,
                          color: AppColors.textMutedFor(brightness)),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMutedFor(brightness),
                        ),
                      ),
                      // Due indicator text
                      if (dueCount > 0) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.schedule,
                            size: 13,
                            color: isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Text(
                          '$dueCount due',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD97706),
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
                color: AppColors.textMutedFor(brightness), size: 24),
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
