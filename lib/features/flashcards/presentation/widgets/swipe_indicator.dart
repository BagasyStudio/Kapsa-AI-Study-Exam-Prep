import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

/// Swipe direction indicator (left = Study Again / red, right = Mastered / green).
///
/// Opacity is driven by swipe progress from [CardStack].
class SwipeIndicator extends StatelessWidget {
  final bool isRight;
  final double opacity;

  const SwipeIndicator({
    super.key,
    required this.isRight,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRight ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final icon = isRight ? Icons.check : Icons.close;
    final label = isRight ? 'MASTERED' : 'STUDY';

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
