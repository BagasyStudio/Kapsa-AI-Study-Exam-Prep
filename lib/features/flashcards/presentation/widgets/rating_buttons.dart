import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/fsrs.dart';

/// Four-button SRS rating widget: Again / Hard / Good / Easy.
///
/// Each button shows the interval preview (e.g. "1d", "4d").
class RatingButtons extends StatelessWidget {
  final Map<Rating, String> intervals;
  final ValueChanged<Rating> onRating;
  final bool enabled;

  const RatingButtons({
    super.key,
    required this.intervals,
    required this.onRating,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RatingButton(
            label: 'Again',
            interval: intervals[Rating.again] ?? '',
            color: const Color(0xFFEF4444),
            onTap: enabled ? () => onRating(Rating.again) : null,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _RatingButton(
            label: 'Hard',
            interval: intervals[Rating.hard] ?? '',
            color: const Color(0xFFF97316),
            onTap: enabled ? () => onRating(Rating.hard) : null,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _RatingButton(
            label: 'Good',
            interval: intervals[Rating.good] ?? '',
            color: const Color(0xFF22C55E),
            onTap: enabled ? () => onRating(Rating.good) : null,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _RatingButton(
            label: 'Easy',
            interval: intervals[Rating.easy] ?? '',
            color: const Color(0xFF3B82F6),
            onTap: enabled ? () => onRating(Rating.easy) : null,
          ),
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String interval;
  final Color color;
  final VoidCallback? onTap;

  const _RatingButton({
    required this.label,
    required this.interval,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              interval,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMutedFor(Theme.of(context).brightness),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
