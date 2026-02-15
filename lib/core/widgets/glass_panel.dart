import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_radius.dart';

/// Defines the intensity tier of the glass effect.
enum GlassTier { subtle, medium, strong }

/// A reusable glassmorphism container.
///
/// Uses [BackdropFilter] with [ClipRRect] for performance.
/// Three tiers: subtle (backgrounds), medium (cards/nav), strong (active buttons).
class GlassPanel extends StatelessWidget {
  final Widget child;
  final GlassTier tier;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tintColor;
  final BoxBorder? border;

  const GlassPanel({
    super.key,
    required this.child,
    this.tier = GlassTier.medium,
    this.borderRadius,
    this.padding,
    this.tintColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configFor(tier);
    final radius = borderRadius ?? AppRadius.borderRadiusXl;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: config.blurSigma,
          sigmaY: config.blurSigma,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color:
                (tintColor ?? Colors.white).withValues(alpha: config.fillOpacity),
            borderRadius: radius,
            border: border ??
                Border.all(
                  color: Colors.white.withValues(alpha: config.borderOpacity),
                  width: 1.0,
                ),
          ),
          child: child,
        ),
      ),
    );
  }

  _GlassConfig _configFor(GlassTier tier) => switch (tier) {
        GlassTier.subtle => (
            fillOpacity: 0.35,
            blurSigma: 8.0,
            borderOpacity: 0.10
          ),
        GlassTier.medium => (
            fillOpacity: 0.50,
            blurSigma: 12.0,
            borderOpacity: 0.15
          ),
        GlassTier.strong => (
            fillOpacity: 0.65,
            blurSigma: 16.0,
            borderOpacity: 0.20
          ),
      };
}

typedef _GlassConfig = ({
  double fillOpacity,
  double blurSigma,
  double borderOpacity,
});
