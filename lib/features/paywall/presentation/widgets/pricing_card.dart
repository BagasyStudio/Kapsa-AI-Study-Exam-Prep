import 'package:flutter/material.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A pricing plan card for the paywall.
///
/// Dark immersive glass card with gradient borders when selected.
/// Badge floats above the card with amber/gold accent.
class PricingCard extends StatelessWidget {
  final String planName;
  final String price;
  final String period;
  final String? subtitle;
  final String? badgeText;
  final bool isSelected;
  final VoidCallback? onTap;

  const PricingCard({
    super.key,
    required this.planName,
    required this.price,
    required this.period,
    this.subtitle,
    this.badgeText,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card
          AnimatedContainer(
            duration: AppAnimations.durationMedium,
            curve: AppAnimations.curveStandard,
            height: isSelected ? 192 : 176,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6467F2).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.08),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6467F2).withValues(alpha: 0.15),
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Subtle inner gradient for selected
                if (isSelected)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6467F2).withValues(alpha: 0.08),
                            Colors.transparent,
                            const Color(0xFF4338CA).withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Plan name
                      Text(
                        planName,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            price,
                            style: AppTypography.h1.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.7),
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            period,
                            style: AppTypography.bodyLarge.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),

                      // Subtitle
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle!,
                          style: AppTypography.caption.copyWith(
                            color: const Color(0xFF34D399).withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Badge
          if (badgeText != null)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFBBF24), // amber-400
                        Color(0xFFF59E0B), // amber-500
                      ],
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeText!,
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF1C1917), // stone-900
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
