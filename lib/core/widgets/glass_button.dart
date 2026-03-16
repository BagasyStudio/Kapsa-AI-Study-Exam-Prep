import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'tap_scale.dart';

/// A glassmorphism-styled button used in Capture Hub action tiles.
///
/// Uses a semi-transparent gradient fill instead of BackdropFilter
/// for better performance on scrollable surfaces.
/// Always renders in immersive dark style.
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
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: radius,
          border: Border.all(
            color: AppColors.immersiveBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: Offset.zero,
              blurStyle: BlurStyle.inner,
            ),
            BoxShadow(
              color: const Color(0xFF6467F2).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
