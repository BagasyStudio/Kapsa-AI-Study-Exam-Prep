import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Floating sparkle particles that drift around a region.
///
/// Used on the Welcome screen to add magic around the mascot.
class SparkleParticles extends StatefulWidget {
  final double width;
  final double height;
  final int count;

  const SparkleParticles({
    super.key,
    this.width = 300,
    this.height = 300,
    this.count = 15,
  });

  @override
  State<SparkleParticles> createState() => _SparkleParticlesState();
}

class _SparkleParticlesState extends State<SparkleParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Sparkle> _sparkles;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _sparkles = List.generate(widget.count, (_) => _Sparkle(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      phase: _rng.nextDouble() * 2 * pi,
      speed: 0.3 + _rng.nextDouble() * 0.7,
      size: 2 + _rng.nextDouble() * 4,
      alpha: 0.3 + _rng.nextDouble() * 0.5,
      isPrimary: _rng.nextDouble() < 0.25,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _SparklePainter(
              sparkles: _sparkles,
              t: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _Sparkle {
  final double x, y, phase, speed, size, alpha;
  final bool isPrimary;

  const _Sparkle({
    required this.x,
    required this.y,
    required this.phase,
    required this.speed,
    required this.size,
    required this.alpha,
    required this.isPrimary,
  });
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double t;

  _SparklePainter({required this.sparkles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final angle = t * 2 * pi * s.speed + s.phase;
      final dx = s.x * size.width + sin(angle) * 20;
      final dy = s.y * size.height + cos(angle * 0.7) * 15;

      // Twinkle: alpha oscillates
      final twinkle = (sin(angle * 3) + 1) / 2; // 0..1
      final a = s.alpha * (0.4 + twinkle * 0.6);

      final color = s.isPrimary
          ? AppColors.primary.withValues(alpha: a)
          : Colors.white.withValues(alpha: a);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Draw diamond shape
      final path = Path();
      final r = s.size * (0.7 + twinkle * 0.3);
      path.moveTo(dx, dy - r);
      path.lineTo(dx + r * 0.5, dy);
      path.lineTo(dx, dy + r);
      path.lineTo(dx - r * 0.5, dy);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.t != t;
}
