import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import 'tap_scale.dart';

/// A glassmorphism-styled button used in Capture Hub action tiles.
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.borderRadiusCard;

    return TapScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xCCFFFFFF), // 80%
                  Color(0x66FFFFFF), // 40%
                ],
              ),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 20,
                  offset: Offset.zero,
                  blurStyle: BlurStyle.inner,
                ),
                BoxShadow(
                  color: const Color(0xFF6467F2).withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
