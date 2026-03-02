import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_radius.dart';

/// Defines the intensity tier of the glass effect.
enum GlassTier { subtle, medium, strong }

/// A reusable glassmorphism container.
///
/// Uses [BackdropFilter] with [ClipRRect] for performance.
/// Three tiers: subtle (backgrounds), medium (cards/nav), strong (active buttons).
///
/// Automatically adapts to dark mode — uses lighter tints in light mode
/// and slightly transparent fills in dark mode.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _configFor(tier, isDark);
    final radius = borderRadius ?? AppRadius.borderRadiusXl;

    final baseTint = tintColor ?? (isDark ? Colors.white : Colors.white);

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
            color: baseTint.withValues(alpha: config.fillOpacity),
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

  _GlassConfig _configFor(GlassTier tier, bool isDark) {
    if (isDark) {
      return switch (tier) {
        GlassTier.subtle => (
            fillOpacity: 0.10,
            blurSigma: 8.0,
            borderOpacity: 0.08
          ),
        GlassTier.medium => (
            fillOpacity: 0.12,
            blurSigma: 12.0,
            borderOpacity: 0.10
          ),
        GlassTier.strong => (
            fillOpacity: 0.18,
            blurSigma: 16.0,
            borderOpacity: 0.14
          ),
      };
    }
    return switch (tier) {
      GlassTier.subtle => (
          fillOpacity: 0.50,
          blurSigma: 8.0,
          borderOpacity: 0.12
        ),
      GlassTier.medium => (
          fillOpacity: 0.72,
          blurSigma: 12.0,
          borderOpacity: 0.18
        ),
      GlassTier.strong => (
          fillOpacity: 0.82,
          blurSigma: 16.0,
          borderOpacity: 0.25
        ),
    };
  }
}

typedef _GlassConfig = ({
  double fillOpacity,
  double blurSigma,
  double borderOpacity,
});
