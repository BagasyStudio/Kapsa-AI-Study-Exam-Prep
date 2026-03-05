import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../flashcards/data/models/deck_model.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';

/// Individual flashcard deck card for the home quick-access section.
///
/// Shows deck title, course name, card count, and a due-cards badge.
/// Glass-morphism style matching FocusFlowCard.
class FlashcardQuickAccessCard extends ConsumerWidget {
  final DeckModel deck;
  final String courseName;

  const FlashcardQuickAccessCard({
    super.key,
    required this.deck,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = Theme.of(context).brightness;
    final dueCount = ref
        .watch(dueCardsCountForDeckProvider(deck.id))
        .whenOrNull(data: (c) => c) ?? 0;

    return TapScale(
      onTap: () => context.push(Routes.flashcardSessionPath(deck.id)),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.55),
          borderRadius: AppRadius.borderRadiusXl,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deck icon with gradient + due badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.style_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (dueCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$dueCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Deck title (max 2 lines)
            Text(
              deck.title,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryFor(brightness),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Course name (1 line)
            Text(
              courseName,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMutedFor(brightness),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Footer: card count + due chip
            Row(
              children: [
                Icon(
                  Icons.layers_rounded,
                  size: 12,
                  color: AppColors.textMutedFor(brightness),
                ),
                const SizedBox(width: 4),
                Text(
                  '${deck.cardCount}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedFor(brightness),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (dueCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7)
                          .withValues(alpha: isDark ? 0.15 : 0.6),
                      borderRadius: AppRadius.borderRadiusPill,
                    ),
                    child: Text(
                      '$dueCount due',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFD97706),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
