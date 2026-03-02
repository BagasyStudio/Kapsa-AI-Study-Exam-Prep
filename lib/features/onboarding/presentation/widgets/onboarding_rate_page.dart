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
/// Premium-feeling page with gold stars, laurel wreath decoration,
/// overlapping avatar row, testimonial card, and CTA buttons.
/// Appears right before the paywall.
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

class _OnboardingRatePageState extends State<OnboardingRatePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    final imgSize = (screenH * 0.12).clamp(70.0, 100.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Staggered animation intervals
        final headerOpacity = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.2, curve: Curves.easeOut),
        ).value;

        final starsProgress = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.12, 0.45, curve: Curves.easeOut),
        ).value;

        final contentProgress = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
        ).value;

        final testimonialProgress = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
        ).value;

        final buttonsProgress = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
        ).value;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                SizedBox(height: screenH * 0.02),

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

                const SizedBox(height: AppSpacing.sm),

                // Title
                Opacity(
                  opacity: headerOpacity,
                  child: GradientText(
                    'Help us grow',
                    style: AppTypography.h1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                    gradient: AppGradients.primaryToIndigo,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Stars with laurel wreath
                Opacity(
                  opacity: starsProgress,
                  child: Transform.scale(
                    scale: 0.85 + 0.15 * starsProgress,
                    child: _buildStarsWithLaurel(),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Subtitle + description
                Opacity(
                  opacity: contentProgress,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - contentProgress)),
                    child: Column(
                      children: [
                        Text(
                          'Kapsa was built for students like you.',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.textPrimaryFor(brightness),
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
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

                // Overlapping avatar row
                Opacity(
                  opacity: contentProgress,
                  child: _buildAvatarRow(brightness),
                ),

                const SizedBox(height: AppSpacing.md),

                // Testimonial card
                Opacity(
                  opacity: testimonialProgress,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - testimonialProgress)),
                    child: _buildTestimonialCard(brightness, isDark),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Rate CTA button
                Opacity(
                  opacity: buttonsProgress,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - buttonsProgress)),
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
                              color: AppColors.primary.withValues(alpha: 0.3),
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
                                'Rate on App Store',
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
                  opacity: buttonsProgress,
                  child: TapScale(
                    onTap: widget.onSkip,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'I already rated',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMutedFor(brightness),
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textMutedFor(brightness),
                        ),
                      ),
                    ),
                  ),
                ),

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
              final starStart = (0.15 + i * 0.06).clamp(0.0, 1.0);
              final starEnd = (starStart + 0.2).clamp(0.0, 1.0);
              final starProgress = CurvedAnimation(
                parent: _controller,
                curve: Interval(starStart, starEnd,
                    curve: AppAnimations.curveBounce),
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
          // Header: avatar + name + stars
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
              // 5 stars
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
          // Quote
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
// Laurel wreath custom painter
// ─────────────────────────────────────────────────────────────

/// Paints two symmetrical branches of small leaf shapes on each
/// side of the child widget, evoking a laurel wreath.
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

    // Draw leaves along a curved arc on each side
    for (final side in [-1.0, 1.0]) {
      final branchPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = color.withValues(alpha: 0.25)
        ..strokeWidth = 1.2;

      // Draw thin branch stem
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

      // Draw leaves along the branch
      for (int i = 0; i < 7; i++) {
        final t = i / 6.0;
        final angle = -1.0 + t * 2.0;
        final radius = size.width * 0.42;
        final x = cx + side * (radius * cos(angle) * 0.55 + 10);
        final y = cy - radius * sin(angle) * 0.55;

        canvas.save();
        canvas.translate(x, y);
        // Rotate leaves to follow the arc direction
        canvas.rotate(side * (angle * 0.5 + 0.2));

        // Draw leaf: a pointed oval
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
