import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A feature row for the paywall screen.
///
/// Shows a gradient glass icon container with a feature label.
/// Designed for dark immersive background.
class FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const FeatureRow({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Gradient glass icon container
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.9),
            size: 22,
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        // Feature label
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),

        // Check mark
        Icon(
          Icons.check_circle,
          size: 20,
          color: const Color(0xFF34D399).withValues(alpha: 0.7), // emerald-400
        ),
      ],
    );
  }
}
