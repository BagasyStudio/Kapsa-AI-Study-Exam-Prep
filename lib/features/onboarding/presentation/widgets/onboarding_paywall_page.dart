import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/pulse_glow.dart';
import '../../../../core/theme/app_gradients.dart';

/// Screen 7: Unlock everything (paywall teaser).
///
/// Dark immersive background (provided by parent).
/// Features list with checkmarks. PulseGlow on CTA.
/// Links to actual paywall or continues without Pro.
class OnboardingPaywallPage extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTryPro;
  final VoidCallback onSkip;

  const OnboardingPaywallPage({
    super.key,
    required this.isActive,
    required this.onTryPro,
    required this.onSkip,
  });

  static const _proFeatures = [
    (icon: Icons.chat_bubble_outline, text: 'Unlimited AI Oracle Chat'),
    (icon: Icons.style_outlined, text: 'Unlimited Flashcards & Quizzes'),
    (icon: Icons.calendar_today_outlined, text: 'Smart Study Plans'),
    (icon: Icons.insights_outlined, text: 'Advanced Analytics & Insights'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),

            // Mascot
            Image.asset(
              'assets/images/onboarding/onboarding_paywall.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: AppSpacing.md),

            // Badge
            Container(
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

            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
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

            const SizedBox(height: AppSpacing.xxl),

            // Feature rows
            ...List.generate(_proFeatures.length, (i) {
              final feat = _proFeatures[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        feat.icon,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        feat.text,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF34D399),
                      size: 20,
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppSpacing.xl),

            // CTA
            PulseGlow(
              child: TapScale(
                onTap: onTryPro,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
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

            const SizedBox(height: AppSpacing.sm),

            // Skip
            TapScale(
              onTap: onSkip,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Continue without Pro',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Trial note
            Text(
              '7-day free trial · Cancel anytime',
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
