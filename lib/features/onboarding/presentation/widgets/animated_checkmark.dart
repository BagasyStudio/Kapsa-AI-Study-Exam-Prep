import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// An animated checkmark that draws itself in when [isVisible] is true.
///
/// Uses Path + PathMetric for a satisfying draw-in effect.
class AnimatedCheckmark extends StatelessWidget {
  final bool isVisible;
  final double size;
  final Color color;
  final Duration duration;

  const AnimatedCheckmark({
    super.key,
    required this.isVisible,
    this.size = 22,
    this.color = AppColors.success,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isVisible ? 1.0 : 0.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return value == 0
            ? SizedBox(width: size, height: size)
            : CustomPaint(
                size: Size(size, size),
                painter: _CheckPainter(progress: value, color: color),
              );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Checkmark proportions relative to size
    path.moveTo(size.width * 0.18, size.height * 0.5);
    path.lineTo(size.width * 0.42, size.height * 0.72);
    path.lineTo(size.width * 0.82, size.height * 0.28);

    // Extract partial path based on progress
    final metrics = path.computeMetrics().first;
    final partial = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(partial, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) =>
      old.progress != progress || old.color != color;
}
