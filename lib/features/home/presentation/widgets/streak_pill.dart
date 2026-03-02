import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';

/// Animated streak badge with warm gradient and pulse effect.
///
/// 3 visual tiers based on streak length:
/// - 0 days: grey, no animation
/// - 1-6 days: orange gradient, subtle pulse
/// - 7-29 days: orange→red gradient, medium pulse
/// - 30+ days: purple→blue gradient, glow pulse
class StreakPill extends StatefulWidget {
  final int days;
  final VoidCallback? onTap;

  const StreakPill({super.key, required this.days, this.onTap});

  @override
  State<StreakPill> createState() => _StreakPillState();
}

class _StreakPillState extends State<StreakPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

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

  static const _lottieFireUrl =
      'https://lottie.host/2a51faa4-aa5e-4ece-b298-e5a0169e1054/pkLwtR42J3.json';

  Widget get _fireIcon {
    if (widget.days >= 30) {
      // Purple tier keeps the emoji
      return const Text('💜', style: TextStyle(fontSize: 16));
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
                  _fireIcon,
                  const SizedBox(width: 6),
                  Text(
                    '${widget.days} ${widget.days == 1 ? 'Day' : 'Days'}',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
