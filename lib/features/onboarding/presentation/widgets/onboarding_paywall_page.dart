import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
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

  static Widget _paywallAvatar(int index, String filename) {
    return Positioned(
      left: index * 18.0,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF1A1A2E),
            width: 2,
          ),
          image: DecorationImage(
            image: AssetImage('assets/images/avatars/$filename'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  static List<({IconData icon, String text})> _proFeatures(AppLocalizations l) => [
    (icon: Icons.chat_bubble_outline, text: l.paywallFeature1),
    (icon: Icons.style_outlined, text: l.paywallFeature2),
    (icon: Icons.calendar_today_outlined, text: l.paywallFeature3),
    (icon: Icons.insights_outlined, text: l.paywallFeature4),
    (icon: Icons.headset_outlined, text: l.paywallFeature5),
    (icon: Icons.groups_outlined, text: l.paywallFeature6),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final screenH = MediaQuery.of(context).size.height;
    final imgSize = (screenH * 0.14).clamp(80.0, 120.0);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Mascot
            Image.asset(
              'assets/images/onboarding/onboarding_paywall.png',
              width: imgSize,
              height: imgSize,
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
                    l.paywallKapsaPro,
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
              l.paywallTitle,
              style: AppTypography.h1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Feature rows
            ..._proFeatures(l).map((feat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        feat.icon,
                        size: 18,
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

            const SizedBox(height: AppSpacing.md),

            // Social proof bar with real avatars
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  // Overlapping avatars
                  SizedBox(
                    width: 88,
                    height: 28,
                    child: Stack(
                      children: [
                        _paywallAvatar(0, 'avatar_social_04_female.png'),
                        _paywallAvatar(1, 'avatar_social_04_male.png'),
                        _paywallAvatar(2, 'avatar_social_01_female.png'),
                        _paywallAvatar(3, 'avatar_social_02_female.png'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.paywallStudents,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (_) => const Icon(Icons.star_rounded,
                                  size: 10, color: Color(0xFFFBBF24)),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l.paywallRating,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // CTA
            PulseGlow(
              child: TapScale(
                onTap: onTryPro,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryToIndigo,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Text(
                      l.paywallStartTrial,
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
                  l.paywallSkip,
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
              l.paywallDisclaimer,
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
