import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// End-of-session summary shown after completing an SRS review.
class ReviewSummary extends StatelessWidget {
  final int totalReviewed;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;
  final int xpEarned;
  final Duration? sessionDuration;
  final VoidCallback onDone;
  final VoidCallback? onShare;

  // ── UX-25: Enhanced insights ──
  final int? bestStreak;
  final double? cardsPerMinute;
  final bool? isImproving;
  final String? hardestCardKeyword;

  const ReviewSummary({
    super.key,
    required this.totalReviewed,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    this.xpEarned = 0,
    this.sessionDuration,
    required this.onDone,
    this.onShare,
    this.bestStreak,
    this.cardsPerMinute,
    this.isImproving,
    this.hardestCardKeyword,
  });

  bool get _hasInsights =>
      cardsPerMinute != null ||
      (bestStreak != null && bestStreak! > 1) ||
      isImproving == true ||
      hardestCardKeyword != null;

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) {
      return 'Session: ${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return 'Session: ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final retention = totalReviewed > 0
        ? ((goodCount + easyCount) / totalReviewed * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Trophy icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.immersiveSurface,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.immersiveSurface,
                ],
              ),
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 40,
              color: Color(0xFFFBBF24),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Session Complete!',
            style: AppTypography.h2.copyWith(
              color: Colors.white,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            '$totalReviewed cards reviewed',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white60,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                label: 'Again',
                count: againCount,
                color: const Color(0xFFEF4444),
              ),
              _StatChip(
                label: 'Hard',
                count: hardCount,
                color: const Color(0xFFF97316),
              ),
              _StatChip(
                label: 'Good',
                count: goodCount,
                color: const Color(0xFF22C55E),
              ),
              _StatChip(
                label: 'Easy',
                count: easyCount,
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),

          // ── #25: Visual rating distribution bar ──
          if (totalReviewed > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            _RatingDistributionBar(
              againCount: againCount,
              hardCount: hardCount,
              goodCount: goodCount,
              easyCount: easyCount,
              total: totalReviewed,
            ),
          ],

          // ── UX-25: Enhanced insight chips ──
          if (_hasInsights) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.center,
              children: [
                if (cardsPerMinute != null)
                  _InsightChip(
                    icon: Icons.speed_rounded,
                    label: '${cardsPerMinute!.toStringAsFixed(1)} cards/min',
                    color: const Color(0xFF3B82F6),
                  ),
                if (bestStreak != null && bestStreak! > 1)
                  _InsightChip(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Best streak: $bestStreak cards',
                    color: const Color(0xFFF97316),
                  ),
                if (isImproving == true)
                  _InsightChip(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Improving!',
                    color: const Color(0xFF22C55E),
                  ),
                if (hardestCardKeyword != null)
                  _InsightChip(
                    icon: Icons.psychology_outlined,
                    label: 'Hardest: $hardestCardKeyword',
                    color: const Color(0xFFEF4444),
                  ),
              ],
            ),
          ],

          // ── #25: Session quality message ──
          if (totalReviewed > 0 && retention >= 80) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                'Great session! \u{1F389}',
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF22C55E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Retention indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.immersiveSurface,
              border: Border.all(
                color: AppColors.immersiveBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: retention >= 80
                      ? const Color(0xFF22C55E)
                      : retention >= 60
                          ? const Color(0xFFF97316)
                          : const Color(0xFFEF4444),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$retention% retention',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // XP earned
          if (xpEarned > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '+$xpEarned XP earned',
                    style: AppTypography.labelLarge.copyWith(
                      color: const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── UX-18: Session duration ──
          if (sessionDuration != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: AppColors.primary.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _formatDuration(sessionDuration!),
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),

          // Done button
          TapScale(
            onTap: onDone,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'Done',
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Share button
          if (onShare != null) ...[
            const SizedBox(height: AppSpacing.md),
            TapScale(
              onTap: onShare,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.immersiveSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.immersiveBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.ios_share,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share Results',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Text(
              '$count',
              style: AppTypography.h4.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// ── UX-25: Compact insight chip for speed / streak / improvement ──
class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InsightChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: color.withValues(alpha: 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// ── #25: Colored rating distribution bar ──
/// Shows proportions of Again/Hard/Good/Easy as colored segments.
class _RatingDistributionBar extends StatelessWidget {
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;
  final int total;

  const _RatingDistributionBar({
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    const againColor = Color(0xFFEF4444);
    const hardColor = Color(0xFFF97316);
    const goodColor = Color(0xFF22C55E);
    const easyColor = Color(0xFF3B82F6);

    return Column(
      children: [
        // The distribution bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                if (againCount > 0)
                  Expanded(
                    flex: againCount,
                    child: Container(color: againColor),
                  ),
                if (hardCount > 0)
                  Expanded(
                    flex: hardCount,
                    child: Container(color: hardColor),
                  ),
                if (goodCount > 0)
                  Expanded(
                    flex: goodCount,
                    child: Container(color: goodColor),
                  ),
                if (easyCount > 0)
                  Expanded(
                    flex: easyCount,
                    child: Container(color: easyColor),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Legend row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (againCount > 0)
              _legendDot(againColor, '${(againCount / total * 100).round()}%'),
            if (hardCount > 0)
              _legendDot(hardColor, '${(hardCount / total * 100).round()}%'),
            if (goodCount > 0)
              _legendDot(goodColor, '${(goodCount / total * 100).round()}%'),
            if (easyCount > 0)
              _legendDot(easyColor, '${(easyCount / total * 100).round()}%'),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
