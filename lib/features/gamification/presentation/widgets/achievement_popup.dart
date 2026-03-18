import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/achievement_model.dart';

/// Animated popup that appears when a badge is newly unlocked.
///
/// Features a spring-scale entrance, gold glow pulse, confetti burst,
/// and a rotating badge icon.
class AchievementPopup {
  AchievementPopup._();

  static void show(BuildContext context, {required BadgeDefinition badge}) {
    HapticFeedback.heavyImpact();
    SoundService.playAchievementUnlock();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _AchievementPopupWidget(
        badge: badge,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

// ── Confetti dot data ──────────────────────────────────────────────────────

class _ConfettiDot {
  final Color color;
  final double angle; // radians
  final double speed; // px per second
  final double size;
  final double gravityFactor;

  _ConfettiDot({
    required this.color,
    required this.angle,
    required this.speed,
    required this.size,
    required this.gravityFactor,
  });
}

// ── Main widget ────────────────────────────────────────────────────────────

class _AchievementPopupWidget extends StatefulWidget {
  final BadgeDefinition badge;
  final VoidCallback onDismiss;

  const _AchievementPopupWidget({
    required this.badge,
    required this.onDismiss,
  });

  @override
  State<_AchievementPopupWidget> createState() =>
      _AchievementPopupWidgetState();
}

class _AchievementPopupWidgetState extends State<_AchievementPopupWidget>
    with TickerProviderStateMixin {
  // Main timeline controller (entrance → hold → exit)
  late AnimationController _mainController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  // Gold glow pulse
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Badge icon rotation + scale
  late AnimationController _badgeController;
  late Animation<double> _badgeRotation;
  late Animation<double> _badgeScale;

  // Confetti
  late AnimationController _confettiController;
  late List<_ConfettiDot> _confettiDots;

  static const _confettiColors = [
    Color(0xFFFFD700), // gold
    AppColors.primary,
    Colors.white,
    AppColors.ctaLime,
  ];

  @override
  void initState() {
    super.initState();
    _initMainAnimation();
    _initGlowAnimation();
    _initBadgeAnimation();
    _initConfetti();

    // Start all animations
    _mainController.forward().then((_) => widget.onDismiss());
    _glowController.forward();
    _badgeController.forward();
    _confettiController.forward();
  }

  void _initMainAnimation() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(0, -1.5),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: Offset.zero,
          end: const Offset(0, -1.5),
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_mainController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_mainController);

    // Spring scale: 0.0 → overshoot 1.15 → settle 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.8),
        weight: 20,
      ),
    ]).animate(_mainController);
  }

  void _initGlowAnimation() {
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Pulse once: 0 → 1 → 0
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_glowController);
  }

  void _initBadgeAnimation() {
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Full 360 rotation
    _badgeRotation = Tween<double>(begin: 0.0, end: 2 * pi)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_badgeController);

    // Badge icon scales up with slight overshoot
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_badgeController);
  }

  void _initConfetti() {
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    final rng = Random();
    final dotCount = 8 + rng.nextInt(5); // 8-12 dots
    _confettiDots = List.generate(dotCount, (_) {
      return _ConfettiDot(
        color: _confettiColors[rng.nextInt(_confettiColors.length)],
        angle: rng.nextDouble() * 2 * pi,
        speed: 80.0 + rng.nextDouble() * 120.0, // 80-200 px
        size: 4.0 + rng.nextDouble() * 5.0, // 4-9 px
        gravityFactor: 0.3 + rng.nextDouble() * 0.7,
      );
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    _badgeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 12,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Gold glow + card ──
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      final glowIntensity = _glowAnimation.value;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.badge.gradient.first,
                              widget.badge.gradient.last,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            // Base shadow
                            BoxShadow(
                              color: widget.badge.gradient.first
                                  .withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            // Animated gold glow
                            BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.6 * glowIntensity),
                              blurRadius: 30 + 20 * glowIntensity,
                              spreadRadius: 4 * glowIntensity,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Badge icon with rotation + scale
                            AnimatedBuilder(
                              animation: _badgeController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _badgeScale.value,
                                  child: Transform.rotate(
                                    angle: _badgeRotation.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      Colors.white.withValues(alpha: 0.2),
                                ),
                                child: Icon(
                                  widget.badge.icon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '\u{1F3C6} Achievement Unlocked!',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.white
                                          .withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.badge.title,
                                    style:
                                        AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // ── Confetti dots ──
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _confettiController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _ConfettiPainter(
                              dots: _confettiDots,
                              progress: _confettiController.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Confetti painter ───────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiDot> dots;
  final double progress;

  _ConfettiPainter({required this.dots, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Ease out for explosion, then fade
    final explosionProgress = Curves.easeOutCubic.transform(
      (progress * 2.0).clamp(0.0, 1.0),
    );
    final fadeProgress = progress > 0.5
        ? Curves.easeIn.transform(((progress - 0.5) * 2.0).clamp(0.0, 1.0))
        : 0.0;
    final opacity = (1.0 - fadeProgress).clamp(0.0, 1.0);

    for (final dot in dots) {
      final distance = dot.speed * explosionProgress;
      // Apply gravity: dots drift downward over time
      final gravityOffset = 60.0 * dot.gravityFactor * progress * progress;

      final dx = centerX + cos(dot.angle) * distance;
      final dy = centerY + sin(dot.angle) * distance + gravityOffset;

      final paint = Paint()
        ..color = dot.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Dots shrink as they fade
      final currentSize = dot.size * (1.0 - fadeProgress * 0.5);
      canvas.drawCircle(Offset(dx, dy), currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
