import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../providers/assistant_provider.dart';

/// AI insight card shown on the home screen.
///
/// Displays a personalized study tip from The Oracle,
/// with a gradient border, subtle sparkle particles, and tap to open the global chat.
class OracleSmartCard extends ConsumerStatefulWidget {
  const OracleSmartCard({super.key});

  @override
  ConsumerState<OracleSmartCard> createState() => _OracleSmartCardState();
}

class _OracleSmartCardState extends ConsumerState<OracleSmartCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'exam_prep':
        return Icons.school;
      case 'weak_area':
        return Icons.trending_up;
      case 'streak':
        return Icons.local_fire_department;
      case 'review':
        return Icons.refresh;
      case 'progress':
      default:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final insightAsync = ref.watch(assistantInsightProvider);

    return insightAsync.when(
      loading: () => _buildShimmer(context),
      error: (_, __) => const SizedBox.shrink(),
      data: (insight) {
        if (insight == null) return _buildWaitingState(context);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: TapScale(
            onTap: () => context.push(Routes.oracle),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6467F2),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.5),
                child: Container(
                  margin: const EdgeInsets.all(1.5), // gradient border thickness
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.5),
                    color: const Color(0xFF1A1B3A),
                  ),
                  child: Stack(
                    children: [
                      // Sparkle particles layer
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _sparkleController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _SparklesPainter(
                                animationValue: _sparkleController.value,
                              ),
                            );
                          },
                        ),
                      ),
                      // Content layer
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.3),
                                    const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                              child: Icon(
                                _iconForType(insight.type),
                                color: const Color(0xFFA5A7FA),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Text content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome,
                                        size: 12,
                                        color: Color(0xFFA5A7FA),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'THE ORACLE',
                                        style: AppTypography.caption.copyWith(
                                          color: const Color(0xFFA5A7FA),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    insight.title,
                                    style: AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    insight.body,
                                    style: AppTypography.bodySmall.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            // Arrow
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaitingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: TapScale(
        onTap: () => context.push(Routes.oracle),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6467F2).withValues(alpha: 0.5),
                const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                const Color(0xFFEC4899).withValues(alpha: 0.5),
              ],
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(1.5),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.5),
              color: const Color(0xFF1A1B3A),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFA5A7FA),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The Oracle is analyzing...',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload materials to get personalized study tips',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1A1B3A).withValues(alpha: 0.5),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'The Oracle is thinking...',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedFor(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single sparkle particle definition.
class _Sparkle {
  final double x; // 0.0 - 1.0, relative horizontal position
  final double y; // 0.0 - 1.0, relative vertical position
  final double radius;
  final double phaseOffset; // offsets the twinkle cycle per particle
  final double speed; // vertical drift speed multiplier

  const _Sparkle({
    required this.x,
    required this.y,
    required this.radius,
    required this.phaseOffset,
    required this.speed,
  });
}

/// CustomPainter that draws subtle floating sparkle dots.
///
/// Each sparkle twinkles by varying its alpha over time and drifts
/// slowly upward to give a gentle floating feel.
class _SparklesPainter extends CustomPainter {
  final double animationValue;

  _SparklesPainter({required this.animationValue});

  // Pre-defined sparkle positions so they stay stable across frames.
  static const List<_Sparkle> _sparkles = [
    _Sparkle(x: 0.12, y: 0.25, radius: 2.0, phaseOffset: 0.0, speed: 0.6),
    _Sparkle(x: 0.85, y: 0.15, radius: 2.5, phaseOffset: 0.3, speed: 0.8),
    _Sparkle(x: 0.55, y: 0.70, radius: 1.8, phaseOffset: 0.55, speed: 0.5),
    _Sparkle(x: 0.30, y: 0.80, radius: 3.0, phaseOffset: 0.75, speed: 0.7),
    _Sparkle(x: 0.72, y: 0.50, radius: 2.2, phaseOffset: 0.15, speed: 0.9),
    _Sparkle(x: 0.92, y: 0.75, radius: 2.8, phaseOffset: 0.45, speed: 0.55),
    _Sparkle(x: 0.08, y: 0.60, radius: 2.0, phaseOffset: 0.85, speed: 0.65),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final sparkle in _sparkles) {
      // Twinkle: sinusoidal alpha based on animation + per-particle phase offset
      final twinkle =
          math.sin((animationValue + sparkle.phaseOffset) * 2 * math.pi);
      // Map sin output (-1..1) to alpha range (0.1..0.4)
      final alpha = 0.1 + (twinkle + 1.0) / 2.0 * 0.3;

      // Gentle vertical drift: the particle floats upward by a small amount
      final driftY = sparkle.speed * 6.0; // max drift in logical pixels
      final yOffset = -driftY * ((animationValue + sparkle.phaseOffset) % 1.0);

      final dx = sparkle.x * size.width;
      final dy = (sparkle.y * size.height) + yOffset;

      // Only draw if within bounds
      if (dy < 0 || dy > size.height) continue;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

      canvas.drawCircle(Offset(dx, dy), sparkle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
