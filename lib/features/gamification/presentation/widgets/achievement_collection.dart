import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/achievement_model.dart';
import '../providers/achievement_provider.dart';
import 'achievement_badge_widget.dart';

/// Grid display of all achievement badges, showing unlocked and locked states.
///
/// Used on the profile screen — forced immersive dark styling.
class AchievementCollection extends ConsumerWidget {
  const AchievementCollection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(unlockedAchievementsProvider);

    return achievementsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (unlocked) {
        final unlockedMap = {
          for (final a in unlocked) a.badgeKey: a,
        };
        final unlockedCount = unlocked.length;
        final totalCount = Badges.all.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ACHIEVEMENTS',
                    style: AppTypography.sectionHeader.copyWith(
                      color: Colors.white38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$unlockedCount/$totalCount',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white38,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Badge grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.lg,
                children: Badges.all.map((badge) {
                  final achievement = unlockedMap[badge.key];
                  return AchievementBadgeWidget(
                    badge: badge,
                    isUnlocked: achievement != null,
                    unlockedAt: achievement?.unlockedAt,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
