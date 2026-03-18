import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';

/// Animated streak badge with warm gradient, pulse effect, and progress ring.
///
/// 3 visual tiers based on streak length:
/// - 0 days: grey, no animation
/// - 1-6 days: orange gradient, subtle pulse
/// - 7-29 days: orange→red gradient, medium pulse
/// - 30+ days: purple→blue gradient, glow pulse
///
/// A mini progress ring around the fire icon shows progress toward the
/// next milestone (7, 30, 100, 365 days).
class StreakPill extends StatefulWidget {
  final int days;
  final VoidCallback? onTap;
  final bool hasFreezeProtection;

  const StreakPill({
    super.key,
    required this.days,
    this.onTap,
    this.hasFreezeProtection = false,
  });

  @override
  State<StreakPill> createState() => _StreakPillState();
}

class _StreakPillState extends State<StreakPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  /// Milestone thresholds in days.
  static const _milestones = [7, 30, 100, 365];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.days > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Tier-based gradient colors
  List<Color> get _gradientColors {
    if (widget.days == 0) {
      return [Colors.grey.shade600, Colors.grey.shade500];
    } else if (widget.days < 7) {
      return [const Color(0xFFF97316), const Color(0xFFFB923C)];
    } else if (widget.days < 30) {
      return [const Color(0xFFEF4444), const Color(0xFFF97316)];
    } else {
      return [const Color(0xFF8B5CF6), const Color(0xFF6366F1)];
    }
  }

  Color get _glowColor {
    if (widget.days == 0) return Colors.transparent;
    if (widget.days < 7) return const Color(0xFFF97316);
    if (widget.days < 30) return const Color(0xFFEF4444);
    return const Color(0xFF8B5CF6);
  }

  /// Computes progress (0.0 - 1.0) toward the next milestone.
  ///
  /// Returns the fraction of days completed between the previous milestone
  /// (or 0) and the next milestone. If the streak exceeds all milestones,
  /// returns 1.0.
  double get _milestoneProgress {
    if (widget.days <= 0) return 0.0;

    // Find the next milestone the user hasn't reached yet
    int prevMilestone = 0;
    for (final milestone in _milestones) {
      if (widget.days < milestone) {
        final range = milestone - prevMilestone;
        final progress = (widget.days - prevMilestone) / range;
        return progress.clamp(0.0, 1.0);
      }
      prevMilestone = milestone;
    }

    // Past all milestones
    return 1.0;
  }

  static const _lottieFireUrl =
      'https://lottie.host/2a51faa4-aa5e-4ece-b298-e5a0169e1054/pkLwtR42J3.json';

  Widget get _fireIcon {
    if (widget.days >= 30) {
      // Purple tier keeps the emoji
      return const Text('\u{1F49C}', style: TextStyle(fontSize: 16));
    }
    return Lottie.network(
      _lottieFireUrl,
      width: 22,
      height: 22,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.local_fire_department,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  /// Fire icon wrapped with a mini progress ring showing milestone progress.
  Widget get _fireIconWithRing {
    const double ringSize = 28;
    const double strokeWidth = 2.5;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: CustomPaint(
        painter: _StreakRingPainter(
          progress: _milestoneProgress,
          gradientColors: _gradientColors,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: SizedBox(
            width: ringSize - strokeWidth * 2 - 2,
            height: ringSize - strokeWidth * 2 - 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _fireIcon,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.days > 0 ? _pulseAnim.value : 1.0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.borderRadiusPill,
                boxShadow: widget.days > 0
                    ? [
                        BoxShadow(
                          color: _glowColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _fireIconWithRing,
                  const SizedBox(width: 6),
                  Text(
                    '${widget.days} ${widget.days == 1 ? 'Day' : 'Days'}',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (widget.hasFreezeProtection) ...[
                    const SizedBox(width: 4),
                    const Text('\u2744\uFE0F',
                        style: TextStyle(fontSize: 11)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// CustomPainter that draws a circular progress ring with a gradient stroke.
///
/// The background track is drawn as a semi-transparent white circle,
/// and the progress arc uses the streak tier gradient colors.
class _StreakRingPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;
  final double strokeWidth;

  _StreakRingPainter({
    required this.progress,
    required this.gradientColors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * progress;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
        colors: [
          gradientColors.first,
          gradientColors.last,
          gradientColors.first,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StreakRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.gradientColors != gradientColors ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
