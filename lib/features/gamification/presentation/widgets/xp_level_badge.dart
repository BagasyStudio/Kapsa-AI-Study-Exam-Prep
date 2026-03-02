import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/xp_config.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/xp_provider.dart';

/// Compact badge showing "Lvl X | 1,240 XP" with a circular progress ring
/// around the bolt icon indicating progress towards the next level.
class XpLevelBadge extends ConsumerWidget {
  const XpLevelBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(xpTotalProvider).whenOrNull(data: (v) => v) ?? 0;
    final level = ref.watch(xpLevelProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final progress = XpConfig.progressToNextLevel(xp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B)
                .withValues(alpha: isDark ? 0.3 : 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular progress ring around the bolt icon
          SizedBox(
            width: 18,
            height: 18,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background track
                CustomPaint(
                  size: const Size(18, 18),
                  painter: _RingPainter(
                    progress: 1.0,
                    color: Colors.white.withValues(alpha: 0.3),
                    strokeWidth: 2,
                  ),
                ),
                // Progress arc
                CustomPaint(
                  size: const Size(18, 18),
                  painter: _RingPainter(
                    progress: progress,
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                // Bolt icon centered inside the ring
                const Icon(Icons.bolt, color: Colors.white, size: 11),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Lvl $level',
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          Container(
            width: 1,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            color: Colors.white.withValues(alpha: 0.4),
          ),
          Text(
            _formatXp(xp),
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) {
      final k = xp / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k XP';
    }
    return '$xp XP';
  }
}

/// Paints a circular arc (progress ring) used around the bolt icon.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Start from the top (-pi/2) and sweep clockwise
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
