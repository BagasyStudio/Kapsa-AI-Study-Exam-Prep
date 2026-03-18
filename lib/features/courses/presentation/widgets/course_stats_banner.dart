import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_counter.dart';
import '../providers/course_stats_provider.dart';

/// Dynamic course stats banner replacing the static AiInsightBanner.
///
/// Shows material count, flashcard count, quiz count, and a CTA.
class CourseStatsBanner extends ConsumerWidget {
  final String courseId;
  final VoidCallback? onGenerateTap;

  const CourseStatsBanner({
    super.key,
    required this.courseId,
    this.onGenerateTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(courseStatsProvider(courseId));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.immersiveBorder,
        ),
      ),
      child: Stack(
        children: [
          // Decorative glow
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'COURSE OVERVIEW',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Stats row with progress ring
              statsAsync.when(
                loading: () => const SizedBox(
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
                error: (_, __) => Text(
                  'Upload materials to see course stats',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white38,
                  ),
                ),
                data: (stats) => Row(
                  children: [
                    // Progress ring
                    _CompletionRing(
                      completionRate: stats.completionRate,
                      reviewed: stats.reviewedCount,
                      total: stats.materialCount,
                    ),
                    const SizedBox(width: 12),
                    // Stat chips
                    Expanded(
                      child: Row(
                        children: [
                          _StatChip(
                            icon: Icons.description_outlined,
                            value: '${stats.materialCount}',
                            label: 'Materials',
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.style_outlined,
                            value: '${stats.deckCount}',
                            label: 'Decks',
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.layers_outlined,
                            value: '${stats.totalCards}',
                            label: 'Cards',
                          ),
                          if (stats.dueCards > 0) ...[
                            const SizedBox(width: 10),
                            _StatChip(
                              icon: Icons.schedule,
                              value: '${stats.dueCards}',
                              label: 'Due',
                              isHighlighted: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // CTA
              GestureDetector(
                onTap: onGenerateTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.immersiveSurface,
                    borderRadius: AppRadius.borderRadiusMd,
                    border: Border.all(
                      color: AppColors.immersiveBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Generate Flashcards',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isHighlighted;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.isHighlighted = false,
  });

  @override
  State<_StatChip> createState() => _StatChipState();
}

class _StatChipState extends State<_StatChip>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.isHighlighted) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
        CurvedAnimation(
          parent: _pulseController!,
          curve: Curves.easeInOut,
        ),
      );
      _pulseController!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isHighlighted
        ? const Color(0xFFF59E0B)
        : Colors.white60;

    final parsedValue = int.tryParse(widget.value) ?? 0;

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(widget.icon, size: 16, color: color),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: parsedValue,
            style: AppTypography.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          Text(
            widget.label,
            style: AppTypography.caption.copyWith(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    if (widget.isHighlighted && _pulseAnimation != null) {
      chip = ScaleTransition(
        scale: _pulseAnimation!,
        child: chip,
      );
    }

    return Expanded(child: chip);
  }
}

/// Animated completion ring showing material review progress.
class _CompletionRing extends StatelessWidget {
  final double completionRate;
  final int reviewed;
  final int total;

  const _CompletionRing({
    required this.completionRate,
    required this.reviewed,
    required this.total,
  });

  Color get _progressColor {
    if (completionRate >= 0.7) return AppColors.success;
    if (completionRate >= 0.4) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: completionRate),
      duration: AppAnimations.durationLong,
      curve: AppAnimations.curveDecelerate,
      builder: (context, value, child) {
        final color = _progressColor;
        return SizedBox(
          width: 56,
          height: 56,
          child: CustomPaint(
            painter: _CompletionRingPainter(
              progress: value,
              color: color,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedCounter(
                    value: (completionRate * 100).round(),
                    duration: AppAnimations.durationLong,
                    suffix: '%',
                    style: AppTypography.labelLarge.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$reviewed/$total',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for the progress ring arc.
class _CompletionRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CompletionRingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 3;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CompletionRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
