import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Contextual soft paywall prompt for inline upgrade nudges.
///
/// Shows a compact, non-blocking card with a contextual message
/// and upgrade CTA. Use in lists, empty states, or after actions.
class SoftPaywallPrompt extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accentColor;

  const SoftPaywallPrompt({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.auto_awesome,
    this.accentColor,
  });

  /// After quiz — nudge to unlock unlimited quizzes.
  factory SoftPaywallPrompt.afterQuiz() => const SoftPaywallPrompt(
        title: 'Want unlimited quizzes?',
        subtitle: 'Upgrade to Pro for unlimited AI-generated tests.',
        icon: Icons.quiz_rounded,
        accentColor: Color(0xFF10B981),
      );

  /// After flashcard generation — nudge to unlock more.
  factory SoftPaywallPrompt.afterFlashcards() => const SoftPaywallPrompt(
        title: 'Love the flashcards?',
        subtitle: 'Go Pro for unlimited decks and smart SRS review.',
        icon: Icons.style_rounded,
        accentColor: Color(0xFF3B82F6),
      );

  /// Oracle chat limit — nudge to unlock unlimited chat.
  factory SoftPaywallPrompt.oracleLimit() => const SoftPaywallPrompt(
        title: 'Need more AI help?',
        subtitle: 'Upgrade for unlimited Oracle conversations.',
        icon: Icons.psychology_alt,
        accentColor: Color(0xFF8B5CF6),
      );

  /// Generic feature unlock.
  factory SoftPaywallPrompt.generic() => const SoftPaywallPrompt(
        title: 'Unlock full potential',
        subtitle: 'Get unlimited access to all Kapsa features.',
        icon: Icons.auto_awesome,
      );

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = accentColor ?? AppColors.primary;

    return TapScale(
      onTap: () => context.push(Routes.paywall),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.06),
              color.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimaryFor(brightness),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Arrow
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
