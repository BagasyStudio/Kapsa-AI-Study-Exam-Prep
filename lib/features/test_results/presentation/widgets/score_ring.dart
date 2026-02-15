import 'package:flutter/material.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/circular_progress_ring.dart';

/// Animated score ring displaying percentage and grade (light mode).
///
/// On first build, the ring fills from 0 to [score] with a dramatic
/// deceleration curve, the percentage counts up, and the grade badge
/// bounces in after the ring finishes filling.
class ScoreRing extends StatefulWidget {
  final double score; // 0.0 to 1.0
  final String grade; // e.g., "B+"
  final int correctCount;
  final int totalCount;

  const ScoreRing({
    super.key,
    required this.score,
    required this.grade,
    required this.correctCount,
    required this.totalCount,
  });

  @override
  State<ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<ScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _gradeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.durationLong,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.score,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveDecelerate,
    ));

    // Percentage text fades in during first half
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Grade badge bounces in after ring is mostly filled
    _gradeScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
    ));

    // Start after a small delay so the screen transition completes first
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _scoreColor {
    if (widget.score >= 0.9) return AppColors.success;
    if (widget.score >= 0.7) return AppColors.primary;
    if (widget.score >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final animatedProgress = _progressAnimation.value;
        final percentage = (animatedProgress * 100).round();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ring with score inside
            CircularProgressRing(
              progress: animatedProgress,
              size: 180,
              strokeWidth: 14,
              progressColor: _scoreColor,
              trackColor: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated percentage counter
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Text(
                      '$percentage%',
                      style: AppTypography.h1.copyWith(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B), // slate-800
                      ),
                    ),
                  ),
                  // Grade badge scales in with bounce
                  Transform.scale(
                    scale: _gradeScaleAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _scoreColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.grade,
                        style: AppTypography.labelLarge.copyWith(
                          color: _scoreColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Count label with fade
            Opacity(
              opacity: _fadeAnimation.value,
              child: Text(
                '${widget.correctCount} of ${widget.totalCount} correct',
                style: AppTypography.bodyMedium.copyWith(
                  color: const Color(0xFF64748B), // slate-500
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
