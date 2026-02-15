import 'package:flutter/material.dart';
import '../theme/app_animations.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import 'tap_scale.dart';

/// Standard primary CTA button with shadow glow.
///
/// Used for "Continue Review", "Practice Weak Areas", etc.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool expanded;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailingIcon,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = TapScale(
      onTap: onPressed,
      scaleDown: 0.96,
      child: AnimatedContainer(
        duration: AppAnimations.durationFast,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.borderRadiusPill,
          boxShadow: AppShadows.primaryGlow,
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTypography.button),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: AppColors.textOnPrimary, size: 18),
            ],
          ],
        ),
      ),
    );

    return button;
  }
}
