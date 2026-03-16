import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../gamification/presentation/widgets/xp_level_badge.dart';
import 'streak_pill.dart';

/// Header row with greeting text, streak counter pill, and XP badge.
class GreetingHeader extends StatelessWidget {
  final String userName;
  final int streakDays;

  const GreetingHeader({
    super.key,
    required this.userName,
    required this.streakDays,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showStreakModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _StreakDetailSheet(
        streakDays: streakDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '$_greeting,\n$userName',
            style: AppTypography.h1.copyWith(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 26,
              height: 1.2,
              color: AppColors.textPrimaryDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StreakPill(
              days: streakDays,
              onTap: () => _showStreakModal(context),
            ),
            const SizedBox(height: 6),
            const XpLevelBadge(),
          ],
        ),
      ],
    );
  }
}

/// Glass-morphism bottom sheet showing streak details.
class _StreakDetailSheet extends StatelessWidget {
  final int streakDays;

  const _StreakDetailSheet({
    required this.streakDays,
  });

  /// Next milestone and how many days remain.
  ({int milestone, int remaining}) get _nextMilestone {
    const milestones = [7, 30, 100, 365];
    for (final m in milestones) {
      if (streakDays < m) {
        return (milestone: m, remaining: m - streakDays);
      }
    }
    // Already past 365 -- aim for the next 365 multiple
    final next = ((streakDays ~/ 365) + 1) * 365;
    return (milestone: next, remaining: next - streakDays);
  }

  String get _milestoneLabel {
    final ms = _nextMilestone;
    if (ms.milestone <= 7) return '7-day';
    if (ms.milestone <= 30) return '30-day';
    if (ms.milestone <= 100) return '100-day';
    return '${ms.milestone}-day';
  }

  /// Tier gradient matching StreakPill tiers.
  List<Color> get _gradientColors {
    if (streakDays == 0) {
      return [Colors.grey.shade600, Colors.grey.shade500];
    } else if (streakDays < 7) {
      return [const Color(0xFFF97316), const Color(0xFFFB923C)];
    } else if (streakDays < 30) {
      return [const Color(0xFFEF4444), const Color(0xFFF97316)];
    } else {
      return [const Color(0xFF8B5CF6), const Color(0xFF6366F1)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final ms = _nextMilestone;

    return Container(
          decoration: BoxDecoration(
            color: AppColors.immersiveSurface.withValues(alpha: 0.95),
            borderRadius: AppRadius.borderRadiusSheet,
            border: Border.all(
              color: AppColors.immersiveBorder,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderRadiusPill,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Big streak number with fire emoji
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _gradientColors.first.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$streakDays',
                      style: AppTypography.h1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.network(
                      'https://lottie.host/2a51faa4-aa5e-4ece-b298-e5a0169e1054/pkLwtR42J3.json',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                        Icons.local_fire_department,
                        color: Color(0xFFF97316),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${streakDays == 1 ? '1 Day' : '$streakDays Days'} Streak',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Longest streak
                _InfoRow(
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  text: 'Longest streak: $streakDays days',
                ),

                const SizedBox(height: AppSpacing.sm),

                // Motivational message
                _InfoRow(
                  icon: Icons.rocket_launch_rounded,
                  iconColor: AppColors.primary,
                  text: streakDays == 0
                      ? 'Start studying today to begin your streak!'
                      : 'Keep going! ${ms.remaining} more ${ms.remaining == 1 ? 'day' : 'days'} to your $_milestoneLabel badge!',
                ),

                const SizedBox(height: AppSpacing.sm),

                // Heatmap reference
                _InfoRow(
                  icon: Icons.grid_view_rounded,
                  iconColor: const Color(0xFF10B981),
                  text: 'Check your Study Heatmap on the home screen',
                ),

                const SizedBox(height: AppSpacing.xl),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderRadiusMd,
                      ),
                    ),
                    child: Text(
                      'Got it',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

/// Helper row with icon + text for the streak modal.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: AppRadius.borderRadiusSm,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
