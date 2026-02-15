import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A confetti/celebration overlay that bursts colorful particles.
///
/// Call [ConfettiOverlay.show(context)] to trigger a celebration.
/// Particles fall with gravity and fade out naturally.
class ConfettiOverlay extends StatefulWidget {
  final VoidCallback? onComplete;

  const ConfettiOverlay({super.key, this.onComplete});

  /// Shows a confetti burst overlay on top of the current screen.
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ConfettiOverlay(
        onComplete: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final _random = Random();

  static const _colors = [
    AppColors.primary,
    AppColors.primaryLight,
    AppColors.success,
    Color(0xFFFFCC00),
    Color(0xFFFF6B6B),
    Color(0xFF48DBFB),
    AppColors.auroraPink,
    AppColors.auroraLavender,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _particles = List.generate(50, (_) => _Particle(
      x: _random.nextDouble(),
      y: -0.1 - _random.nextDouble() * 0.3,
      vx: (_random.nextDouble() - 0.5) * 0.4,
      vy: _random.nextDouble() * 0.3 + 0.2,
      rotation: _random.nextDouble() * 2 * pi,
      rotationSpeed: (_random.nextDouble() - 0.5) * 8,
      size: _random.nextDouble() * 8 + 4,
      color: _colors[_random.nextInt(_colors.length)],
      isCircle: _random.nextBool(),
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, rotation, rotationSpeed, size;
  Color color;
  bool isCircle;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Simulate physics
      final t = progress;
      final gravity = 0.5;
      final x = (p.x + p.vx * t) * size.width;
      final y = (p.y + p.vy * t + gravity * t * t) * size.height;
      final rotation = p.rotation + p.rotationSpeed * t;

      // Fade out in last 30%
      final opacity = t > 0.7 ? (1.0 - (t - 0.7) / 0.3) : 1.0;
      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
