import 'package:flutter/material.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'animated_checkmark.dart';

/// Screen 2: What's your biggest challenge?
///
/// Cards stagger in from the right. Selected card gets an animated checkmark.
/// Unselected cards dim when a selection is made.
class OnboardingChallengePage extends StatefulWidget {
  final bool isActive;
  final int? selectedChallenge;
  final ValueChanged<int> onSelect;

  const OnboardingChallengePage({
    super.key,
    required this.isActive,
    required this.selectedChallenge,
    required this.onSelect,
  });

  @override
  State<OnboardingChallengePage> createState() =>
      _OnboardingChallengePageState();
}

class _OnboardingChallengePageState extends State<OnboardingChallengePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasAnimated = false;

  static const _challenges = [
    '😵 I struggle to memorize',
    '📅 I don\'t have time',
    '😴 I get bored studying',
    '📝 I can\'t organize my notes',
    '😰 I stress during exams',
    '🤷 I don\'t know where to start',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isActive) _animate();
  }

  @override
  void didUpdateWidget(OnboardingChallengePage old) {
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
          curve: const Interval(0, 0.25, curve: Curves.easeOut),
        ).value;
        final headerSlide = (1 - headerOpacity) * 20;

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
                    'assets/images/onboarding/onboarding_challenge.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Title
                Opacity(
                  opacity: headerOpacity,
                  child: Transform.translate(
                    offset: Offset(0, headerSlide),
                    child: Text(
                      "What's your\nbiggest challenge?",
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
                ),

                const SizedBox(height: AppSpacing.xs),

                Opacity(
                  opacity: headerOpacity,
                  child: Text(
                    "We'll figure out how to help you best.",
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Challenge cards
                ...List.generate(_challenges.length, _buildCard),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(int i) {
    final start = (0.25 + i * 0.08).clamp(0.0, 1.0);
    final end = (start + 0.35).clamp(0.0, 1.0);
    final progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: AppAnimations.curveEntrance),
    ).value;

    final slideX = 60.0 * (1 - progress);
    final isSelected = widget.selectedChallenge == i;
    final hasSelection = widget.selectedChallenge != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(slideX, 0),
          child: TapScale(
            onTap: () => widget.onSelect(i),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: hasSelection && !isSelected ? 0.5 : 1.0,
              child: AnimatedContainer(
                duration: AppAnimations.durationMedium,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.12),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _challenges[i],
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    AnimatedCheckmark(isVisible: isSelected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
