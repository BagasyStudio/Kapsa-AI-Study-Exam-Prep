import 'package:flutter/material.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/pulse_glow.dart';
import '../../../../core/theme/app_gradients.dart';
import 'animated_checkmark.dart';

/// Screen 7: Unlock everything (paywall teaser).
///
/// Dark immersive background. Features stagger with checkmarks.
/// PulseGlow on CTA. Links to actual paywall or continues without Pro.
class OnboardingPaywallPage extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTryPro;
  final VoidCallback onSkip;

  const OnboardingPaywallPage({
    super.key,
    required this.isActive,
    required this.onTryPro,
    required this.onSkip,
  });

  @override
  State<OnboardingPaywallPage> createState() => _OnboardingPaywallPageState();
}

class _OnboardingPaywallPageState extends State<OnboardingPaywallPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasAnimated = false;

  static const _proFeatures = [
    (icon: Icons.chat_bubble_outline, text: 'Unlimited AI Oracle Chat'),
    (icon: Icons.style_outlined, text: 'Unlimited Flashcards & Quizzes'),
    (icon: Icons.calendar_today_outlined, text: 'Smart Study Plans'),
    (icon: Icons.insights_outlined, text: 'Advanced Analytics & Insights'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isActive) _animate();
  }

  @override
  void didUpdateWidget(OnboardingPaywallPage old) {
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
        final badgeOpacity = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.15, 0.35, curve: Curves.easeOut),
        ).value;

        final titleOpacity = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.2, 0.45, curve: Curves.easeOut),
        ).value;

        final ctaOpacity = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.7, 0.9, curve: Curves.easeOut),
        ).value;

        final skipOpacity = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
        ).value;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B0D1E),
                Color(0xFF111338),
                Color(0xFF0F1029),
                Color(0xFF0B0D1E),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xxl),

                      // Mascot
                      Opacity(
                        opacity: badgeOpacity,
                        child: Image.asset(
                          'assets/images/onboarding/onboarding_paywall.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Badge
                      Opacity(
                        opacity: badgeOpacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xxs + 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'KAPSA PRO',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Title
                      Opacity(
                        opacity: titleOpacity,
                        child: Text(
                          'Unlock your\nfull potential',
                          style: AppTypography.h1.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Feature rows
                      ...List.generate(_proFeatures.length, (i) {
                        final start = (0.35 + i * 0.08).clamp(0.0, 1.0);
                        final end = (start + 0.25).clamp(0.0, 1.0);
                        final progress = CurvedAnimation(
                          parent: _controller,
                          curve: Interval(start, end,
                              curve: AppAnimations.curveEntrance),
                        ).value;
                        final feat = _proFeatures[i];

                        return Opacity(
                          opacity: progress,
                          child: Transform.translate(
                            offset: Offset(30 * (1 - progress), 0),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      feat.icon,
                                      size: 20,
                                      color: Colors.white
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      feat.text,
                                      style:
                                          AppTypography.bodyMedium.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ),
                                  AnimatedCheckmark(
                                    isVisible: progress > 0.8,
                                    color: const Color(0xFF34D399),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: AppSpacing.xl),

                      // CTA
                      Opacity(
                        opacity: ctaOpacity,
                        child: PulseGlow(
                          child: TapScale(
                            onTap: widget.onTryPro,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: AppGradients.primaryToIndigo,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Center(
                                child: Text(
                                  'Try Pro Free',
                                  style: AppTypography.button.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Skip
                      Opacity(
                        opacity: skipOpacity,
                        child: TapScale(
                          onTap: widget.onSkip,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'Continue without Pro',
                              style: AppTypography.bodySmall.copyWith(
                                color:
                                    Colors.white.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Trial note
                      Opacity(
                        opacity: skipOpacity,
                        child: Text(
                          '7-day free trial · Cancel anytime',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
