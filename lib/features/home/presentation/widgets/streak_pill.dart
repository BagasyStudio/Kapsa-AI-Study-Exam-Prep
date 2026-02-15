import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';

/// Glass pill showing the user's study streak.
class StreakPill extends StatelessWidget {
  final int days;

  const StreakPill({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderRadiusPill,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: AppRadius.borderRadiusPill,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$days Days',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              const Text('🔥', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
