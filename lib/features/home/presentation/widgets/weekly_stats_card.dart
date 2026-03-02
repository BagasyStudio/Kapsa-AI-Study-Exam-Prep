import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../gamification/presentation/providers/heatmap_provider.dart';

/// Compact weekly stats card showing study activity this week vs last week.
class WeeklyStatsCard extends ConsumerWidget {
  const WeeklyStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(heatmapDataProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = context.isDark;

    return heatmapAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final now = DateTime.now();

        // Calculate this week's XP
        int thisWeekXp = 0;
        int lastWeekXp = 0;
        int thisWeekDays = 0;

        for (int i = 0; i < 7; i++) {
          final date = now.subtract(Duration(days: i));
          final key =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final xp = data[key] ?? 0;
          thisWeekXp += xp;
          if (xp > 0) thisWeekDays++;
        }

        for (int i = 7; i < 14; i++) {
          final date = now.subtract(Duration(days: i));
          final key =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          lastWeekXp += data[key] ?? 0;
        }

        // Percentage change
        final change = lastWeekXp > 0
            ? ((thisWeekXp - lastWeekXp) / lastWeekXp * 100).round()
            : (thisWeekXp > 0 ? 100 : 0);
        final isUp = change >= 0;
        final isFirstWeek = lastWeekXp == 0 && thisWeekXp > 0;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'This Week',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textPrimaryFor(brightness),
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (isFirstWeek)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.celebration,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            'First week!',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (lastWeekXp > 0 || thisWeekXp > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isUp
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUp
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 14,
                            color: isUp
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${isUp ? '+' : ''}$change%',
                            style: AppTypography.caption.copyWith(
                              color: isUp
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _StatItem(
                    value: '$thisWeekXp',
                    label: 'XP earned',
                    icon: Icons.bolt,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _StatItem(
                    value: '$thisWeekDays',
                    label: 'days active',
                    icon: Icons.local_fire_department,
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimaryFor(brightness),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMutedFor(brightness),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
