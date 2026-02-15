import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Wraps a child widget with a pulsing glow effect.
///
/// Great for CTAs, important buttons, and attention-grabbing elements.
/// The glow smoothly breathes in and out.
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxBlurRadius;
  final Duration duration;

  const PulseGlow({
    super.key,
    required this.child,
    this.glowColor = AppColors.primary,
    this.maxBlurRadius = 24,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: _glowAnimation.value),
                blurRadius: widget.maxBlurRadius,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
