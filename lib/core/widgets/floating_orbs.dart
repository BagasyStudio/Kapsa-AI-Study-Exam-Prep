import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ambient floating orbs that drift and breathe in the background.
///
/// Creates a subtle sense of life and depth. Used in onboarding,
/// home screen, and other immersive layouts.
class FloatingOrbs extends StatefulWidget {
  final int orbCount;

  const FloatingOrbs({super.key, this.orbCount = 3});

  @override
  State<FloatingOrbs> createState() => _FloatingOrbsState();
}

class _FloatingOrbsState extends State<FloatingOrbs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Stack(
          children: [
            // Orb 1: top-right, indigo
            Positioned(
              top: -80 + sin(t * pi * 2) * 20,
              right: -60 + cos(t * pi * 2) * 15,
              child: _Orb(
                size: 280,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            // Orb 2: bottom-left, blue
            Positioned(
              bottom: -40 + cos(t * pi * 2 + 1) * 25,
              left: -70 + sin(t * pi * 2 + 1) * 20,
              child: _Orb(
                size: 240,
                color: const Color(0xFF60A5FA).withValues(alpha: 0.10),
              ),
            ),
            // Orb 3: center-left, pink/aurora
            if (widget.orbCount >= 3)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.35 +
                    sin(t * pi * 2 + 2) * 30,
                left: -30 + cos(t * pi * 2 + 2) * 20,
                child: _Orb(
                  size: 160,
                  color: AppColors.auroraPink.withValues(alpha: 0.18),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
