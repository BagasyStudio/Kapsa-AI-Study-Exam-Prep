import 'package:flutter/material.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/animated_counter.dart';
import 'typewriter_text.dart';

/// Screen 6: Students love Kapsa.
///
/// AnimatedCounter for "10,000+", stars stagger in, typewriter testimonial,
/// animated stat card for "In 30 days: +40% grades".
class OnboardingSocialProofPage extends StatefulWidget {
  final bool isActive;

  const OnboardingSocialProofPage({super.key, required this.isActive});

  @override
  State<OnboardingSocialProofPage> createState() =>
      _OnboardingSocialProofPageState();
}

class _OnboardingSocialProofPageState extends State<OnboardingSocialProofPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.isActive) _animate();
  }

  @override
  void didUpdateWidget(OnboardingSocialProofPage old) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final headerOpacity = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.15, curve: Curves.easeOut),
        ).value;

        final counterReady = _controller.value > 0.15;
        final starsStart = 0.35;
        final typewriterReady = _controller.value > 0.55;
        final statCardProgress = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.7, 0.95, curve: Curves.easeOutQuart),
        ).value;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),

                // Mascot
                Opacity(
                  opacity: headerOpacity,
                  child: Image.asset(
                    'assets/images/onboarding/onboarding_social_proof.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Title
                Opacity(
                  opacity: headerOpacity,
                  child: Text(
                    'Students love Kapsa',
                    style: AppTypography.h1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Animated counter
                if (counterReady)
                  AnimatedCounter(
                    value: 10000,
                    duration: const Duration(milliseconds: 1200),
                    suffix: '+',
                    style: AppTypography.h1.copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                if (counterReady)
                  Text(
                    'active students',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                const SizedBox(height: AppSpacing.md),

                // Star rating — stagger in one by one
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starStart = starsStart + i * 0.05;
                    final starEnd = (starStart + 0.1).clamp(0.0, 1.0);
                    final starProgress = CurvedAnimation(
                      parent: _controller,
                      curve: Interval(starStart, starEnd,
                          curve: AppAnimations.curveBounce),
                    ).value;

                    return AnimatedScale(
                      scale: starProgress,
                      duration: Duration.zero, // Driven by controller
                      child: Opacity(
                        opacity: starProgress,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFCC00),
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Testimonial with typewriter
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: AppRadius.borderRadiusLg,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      TypewriterText(
                        text:
                            '"Kapsa changed the way I study. My grades improved so much in just one month."',
                        animate: typewriterReady,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '— Sofia, Med Student',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Stat card: "In 30 days"
                Opacity(
                  opacity: statCardProgress,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - statCardProgress)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.primary.withValues(alpha: 0.03),
                          ],
                        ),
                        borderRadius: AppRadius.borderRadiusMd,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('📈',
                              style: TextStyle(fontSize: 28)),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'In 30 days',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Average +40% grade improvement',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
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
}
