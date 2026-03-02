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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TapScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E1E2E).withValues(alpha: 0.85),
                        const Color(0xFF1A1B2E).withValues(alpha: 0.70),
                      ]
                    : [
                        const Color(0xCCFFFFFF), // 80%
                        const Color(0x66FFFFFF), // 40%
                      ],
              ),
              borderRadius: radius,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.9),
                  blurRadius: 20,
                  offset: Offset.zero,
                  blurStyle: BlurStyle.inner,
                ),
                BoxShadow(
                  color: const Color(0xFF6467F2).withValues(alpha: isDark ? 0.15 : 0.1),
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
