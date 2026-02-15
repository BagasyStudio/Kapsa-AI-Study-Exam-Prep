import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_spacing.dart';

/// Shimmer loading card placeholder.
///
/// Displays a rectangular shimmer effect matching the app's
/// glassmorphism card style for seamless loading transitions.
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.4),
      highlightColor: Colors.white.withValues(alpha: 0.8),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: borderRadius ?? BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// List of shimmer cards as a loading placeholder.
///
/// Use as a drop-in replacement for content lists while loading.
class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final double spacing;

  const ShimmerList({
    super.key,
    this.count = 3,
    this.itemHeight = 80,
    this.spacing = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < count - 1 ? spacing : 0),
          child: ShimmerCard(height: itemHeight),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for profile stats section.
class ShimmerStats extends StatelessWidget {
  const ShimmerStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.4),
      highlightColor: Colors.white.withValues(alpha: 0.8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
