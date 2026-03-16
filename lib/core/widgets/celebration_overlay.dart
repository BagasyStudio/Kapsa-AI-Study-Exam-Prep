import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shows a celebration overlay with confetti and an animated message.
///
/// Call [CelebrationOverlay.show] for quick usage (e.g., quiz 100%, mastery).
class CelebrationOverlay extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Duration displayDuration;
  final VoidCallback? onDismiss;

  const CelebrationOverlay({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.emoji_events,
    this.color = const Color(0xFFF59E0B),
    this.displayDuration = const Duration(seconds: 3),
    this.onDismiss,
  });

  /// Convenience method to show celebration as an overlay.
  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData icon = Icons.emoji_events,
    Color color = const Color(0xFFF59E0B),
  }) {
    final overlay = OverlayEntry(
      builder: (_) => CelebrationOverlay(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
      ),
    );

    Overlay.of(context).insert(overlay);

    // Auto-remove after 3s
    Future.delayed(const Duration(seconds: 3), () {
      overlay.remove();
    });
  }

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Fire haptic + confetti
    HapticFeedback.heavyImpact();
    _confettiController.play();
    _scaleController.forward();

    // Auto-dismiss
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _scaleController.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 8,
              gravity: 0.2,
              colors: const [
                Color(0xFFF59E0B),
                Color(0xFF10B981),
                Color(0xFF3B82F6),
                Color(0xFFEC4899),
                Color(0xFF8B5CF6),
                Color(0xFFEF4444),
              ],
            ),
          ),

          // Card
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with glow
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: 0.12),
                    ),
                    child: Icon(widget.icon, size: 40, color: widget.color),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: AppTypography.h2.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white60,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating "+X XP" animation that flies upward and fades.
class FloatingXpAnimation extends StatefulWidget {
  final int xp;
  final Offset startPosition;

  const FloatingXpAnimation({
    super.key,
    required this.xp,
    required this.startPosition,
  });

  @override
  State<FloatingXpAnimation> createState() => _FloatingXpAnimationState();
}

class _FloatingXpAnimationState extends State<FloatingXpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _yAnim = Tween<double>(begin: 0, end: -80).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.startPosition.dx,
          top: widget.startPosition.dy + _yAnim.value,
          child: Opacity(
            opacity: _opacityAnim.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                '+${widget.xp} XP',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
