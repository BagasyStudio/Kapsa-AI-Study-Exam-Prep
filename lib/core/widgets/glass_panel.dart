import 'package:flutter/material.dart';
import '../theme/app_radius.dart';

/// Defines the intensity tier of the glass effect.
enum GlassTier { subtle, medium, strong }

/// A reusable glassmorphism-styled container.
///
/// Uses a semi-transparent fill with border and subtle shadow to achieve
/// a glass look **without** [BackdropFilter], which is GPU-expensive
/// especially on scrollable surfaces and mid-range devices.
///
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

    final baseTint = tintColor ?? Colors.white;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: baseTint.withValues(alpha: config.fillOpacity),
        borderRadius: radius,
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: config.borderOpacity),
              width: 1.0,
            ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  _GlassConfig _configFor(GlassTier tier, bool isDark) {
    if (isDark) {
      return switch (tier) {
        GlassTier.subtle => (
            fillOpacity: 0.10,
            borderOpacity: 0.08
          ),
        GlassTier.medium => (
            fillOpacity: 0.12,
            borderOpacity: 0.10
          ),
        GlassTier.strong => (
            fillOpacity: 0.18,
            borderOpacity: 0.14
          ),
      };
    }
    return switch (tier) {
      GlassTier.subtle => (
          fillOpacity: 0.55,
          borderOpacity: 0.12
        ),
      GlassTier.medium => (
          fillOpacity: 0.78,
          borderOpacity: 0.18
        ),
      GlassTier.strong => (
          fillOpacity: 0.88,
          borderOpacity: 0.25
        ),
    };
  }
}

typedef _GlassConfig = ({
  double fillOpacity,
  double borderOpacity,
});
