import 'dart:math' show cos, sin;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Screen 7: Rate us on the App Store.
///
/// Two-phase conversion-optimised flow:
///   Phase 0 — "Are you enjoying Kapsa?" with ❤️ / 🤔 buttons.
///   Phase 1 (loves it) — Stars + laurel + testimonial + CTA.
///   Phase 2 (not yet) — Thank-you + feedback nudge + skip.
///
/// This "review gating" pattern ensures only happy users reach
/// the App Store rating, dramatically improving star averages.
class OnboardingRatePage extends StatefulWidget {
  final bool isActive;
  final VoidCallback onRate;
  final VoidCallback onSkip;

  const OnboardingRatePage({
    super.key,
    required this.isActive,
    required this.onRate,
    required this.onSkip,
  });

  @override
  State<OnboardingRatePage> createState() => _OnboardingRatePageState();
}

// 0 = gate question, 1 = rate (happy), 2 = feedback (unhappy)
enum _Phase { gate, rate, feedback }

class _OnboardingRatePageState extends State<OnboardingRatePage>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _phaseController;
  bool _hasAnimated = false;
  _Phase _phase = _Phase.gate;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isActive) _animate();
  }

  @override
  void didUpdateWidget(OnboardingRatePage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_hasAnimated) _animate();
  }

  void _animate() {
    _hasAnimated = true;
    _entranceController.forward();
  }

  void _onLoveIt() {
    setState(() => _phase = _Phase.rate);
    _phaseController.forward(from: 0);
  }

  void _onCouldBeBetter() {
    setState(() => _phase = _Phase.feedback);
    _phaseController.forward(from: 0);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _phaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    final imgSize = (screenH * 0.13).clamp(75.0, 110.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _phaseController]),
      builder: (context, _) {
        final headerOpacity = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0, 0.25, curve: Curves.easeOut),
        ).value;

        final gateProgress = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
        ).value;

        final phaseAnim = CurvedAnimation(
          parent: _phaseController,
          curve: Curves.easeOutCubic,
        ).value;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                SizedBox(height: screenH * 0.03),

                // Mascot
                Opacity(
                  opacity: headerOpacity,
                  child: Image.asset(
                    'assets/images/onboarding/onboarding_social_proof.png',
                    width: imgSize,
                    height: imgSize,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Title — changes per phase
                Opacity(
                  opacity: headerOpacity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _phase == _Phase.gate
                        ? GradientText(
                            'Are you enjoying\nKapsa?',
                            key: const ValueKey('gate'),
                            style: AppTypography.h1.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                            gradient: AppGradients.primaryToIndigo,
                            textAlign: TextAlign.center,
                          )
                        : _phase == _Phase.rate
                            ? GradientText(
                                'Help us grow',
                                key: const ValueKey('rate'),
                                style: AppTypography.h1.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                                gradient: AppGradients.primaryToIndigo,
                                textAlign: TextAlign.center,
                              )
                            : Text(
                                'Thank you for\nyour honesty',
                                key: const ValueKey('feedback'),
                                style: AppTypography.h1.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                  color: AppColors.textPrimaryFor(brightness),
                                ),
                                textAlign: TextAlign.center,
                              ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Phase 0: Gate question ──
                if (_phase == _Phase.gate) ...[
                  Opacity(
                    opacity: gateProgress,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - gateProgress)),
                      child: Text(
                        'Your feedback helps us build a better\nstudy experience for everyone.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryFor(brightness),
                          height: 1.55,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  SizedBox(height: screenH * 0.04),

                  // Two big emoji buttons
                  Opacity(
                    opacity: gateProgress,
                    child: Transform.scale(
                      scale: 0.85 + 0.15 * gateProgress,
                      child: Row(
                        children: [
                          // Love it
                          Expanded(
                            child: _GateButton(
                              emoji: '❤️',
                              label: 'Love it!',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6467F2), Color(0xFF818CF8)],
                              ),
                              isDark: isDark,
                              onTap: _onLoveIt,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Could be better
                          Expanded(
                            child: _GateButton(
                              emoji: '🤔',
                              label: 'Not yet',
                              gradient: null,
                              isDark: isDark,
                              onTap: _onCouldBeBetter,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: screenH * 0.04),

                  // Social proof below the buttons
                  Opacity(
                    opacity: gateProgress,
                    child: _buildAvatarRow(brightness),
                  ),
                ],

                // ── Phase 1: Rate (happy path) ──
                if (_phase == _Phase.rate) ...[
                  // Stars with laurel
                  Opacity(
                    opacity: phaseAnim,
                    child: Transform.scale(
                      scale: 0.85 + 0.15 * phaseAnim,
                      child: _buildStarsWithLaurel(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Subtitle
                  Opacity(
                    opacity: phaseAnim,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - phaseAnim)),
                      child: Column(
                        children: [
                          Text(
                            'Awesome! 🎉',
                            style: AppTypography.h3.copyWith(
                              color: AppColors.textPrimaryFor(brightness),
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'A 5-star rating helps us keep building\nAI tools that make studying easier.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondaryFor(brightness),
                              height: 1.55,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Testimonial
                  Opacity(
                    opacity: phaseAnim,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - phaseAnim)),
                      child: _buildTestimonialCard(brightness, isDark),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Rate CTA
                  Opacity(
                    opacity: phaseAnim,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - phaseAnim)),
                      child: TapScale(
                        onTap: widget.onRate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryToIndigo,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Rate 5 Stars ⭐',
                                  style: AppTypography.button.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Skip
                  Opacity(
                    opacity: phaseAnim,
                    child: TapScale(
                      onTap: widget.onSkip,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Maybe later',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMutedFor(brightness),
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                AppColors.textMutedFor(brightness),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Phase 2: Feedback (unhappy path) ──
                if (_phase == _Phase.feedback) ...[
                  Opacity(
                    opacity: phaseAnim,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - phaseAnim)),
                      child: Column(
                        children: [
                          // Feedback message
                          Text(
                            'We appreciate your honesty. 🙏',
                            style: AppTypography.h3.copyWith(
                              color: AppColors.textPrimaryFor(brightness),
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'We\'re always improving Kapsa.\nYour feedback helps us build the study\ntools you actually need.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondaryFor(brightness),
                              height: 1.55,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: screenH * 0.04),

                          // Improvement highlight card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.55),
                              borderRadius: AppRadius.borderRadiusLg,
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text('💡',
                                    style: TextStyle(fontSize: 32)),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'We ship updates every week',
                                  style: AppTypography.labelLarge.copyWith(
                                    color:
                                        AppColors.textPrimaryFor(brightness),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  'Kapsa gets better with every\nstudent\'s feedback.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color:
                                        AppColors.textSecondaryFor(brightness),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: screenH * 0.04),

                          // Continue button (not asking for rating)
                          TapScale(
                            onTap: widget.onSkip,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: AppGradients.primaryToIndigo,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Continue',
                                  style: AppTypography.button.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Stars with laurel wreath ──

  Widget _buildStarsWithLaurel() {
    return SizedBox(
      width: 260,
      height: 80,
      child: CustomPaint(
        painter: _LaurelPainter(
          color: const Color(0xFFD4A826).withValues(alpha: 0.45),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final delay = i * 0.08;
              final starProgress = CurvedAnimation(
                parent: _phaseController,
                curve: Interval(
                  (0.1 + delay).clamp(0.0, 1.0),
                  (0.5 + delay).clamp(0.0, 1.0),
                  curve: AppAnimations.curveBounce,
                ),
              ).value;

              return AnimatedScale(
                scale: starProgress,
                duration: Duration.zero,
                child: Opacity(
                  opacity: starProgress,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFCC00),
                      size: 36,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Overlapping avatars ──

  Widget _buildAvatarRow(Brightness brightness) {
    const avatars = [
      (initial: 'S', color1: Color(0xFF8B5CF6), color2: Color(0xFF6366F1)),
      (initial: 'M', color1: Color(0xFF3B82F6), color2: Color(0xFF06B6D4)),
      (initial: 'L', color1: Color(0xFFEC4899), color2: Color(0xFFF43F5E)),
      (initial: 'A', color1: Color(0xFF10B981), color2: Color(0xFF059669)),
    ];

    final bgColor = brightness == Brightness.dark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Column(
      children: [
        SizedBox(
          width: 124,
          height: 38,
          child: Stack(
            children: List.generate(avatars.length, (i) {
              final a = avatars[i];
              return Positioned(
                left: i * 24.0,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [a.color1, a.color2],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: bgColor, width: 2.5),
                  ),
                  child: Center(
                    child: Text(
                      a.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '+50,000 students',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMutedFor(brightness),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Testimonial card ──

  Widget _buildTestimonialCard(Brightness brightness, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.55),
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'S',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sofia M.',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Med Student',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedFor(brightness),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (_) => const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFCC00),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '"Kapsa changed how I study. My grades improved so much in just one month!"',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimaryFor(brightness),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Gate button (❤️ Love it / 🤔 Not yet)
// ─────────────────────────────────────────────────────────────

class _GateButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Gradient? gradient; // null = glass/outline style
  final bool isDark;
  final VoidCallback onTap;

  const _GateButton({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = gradient != null;
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: isPrimary ? gradient : null,
          color: isPrimary
              ? null
              : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: isPrimary
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.3),
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: isPrimary
                    ? Colors.white
                    : AppColors.textPrimaryFor(
                        Theme.of(context).brightness,
                      ),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Laurel wreath custom painter
// ─────────────────────────────────────────────────────────────

class _LaurelPainter extends CustomPainter {
  final Color color;

  const _LaurelPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final side in [-1.0, 1.0]) {
      final branchPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = color.withValues(alpha: 0.25)
        ..strokeWidth = 1.2;

      // Thin branch stem
      final branchPath = Path();
      for (int i = 0; i <= 20; i++) {
        final t = i / 20.0;
        final angle = -1.0 + t * 2.0;
        final radius = size.width * 0.42;
        final x = cx + side * (radius * cos(angle) * 0.55 + 10);
        final y = cy - radius * sin(angle) * 0.55;
        if (i == 0) {
          branchPath.moveTo(x, y);
        } else {
          branchPath.lineTo(x, y);
        }
      }
      canvas.drawPath(branchPath, branchPaint);

      // Leaves along the branch
      for (int i = 0; i < 7; i++) {
        final t = i / 6.0;
        final angle = -1.0 + t * 2.0;
        final radius = size.width * 0.42;
        final x = cx + side * (radius * cos(angle) * 0.55 + 10);
        final y = cy - radius * sin(angle) * 0.55;

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(side * (angle * 0.5 + 0.2));

        final leafPath = Path()
          ..moveTo(0, -7)
          ..quadraticBezierTo(side * 4, -2, 0, 7)
          ..quadraticBezierTo(side * -4, -2, 0, -7);

        canvas.drawPath(leafPath, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
