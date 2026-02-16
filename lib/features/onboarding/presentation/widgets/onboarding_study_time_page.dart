import 'package:flutter/material.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'study_time_card.dart';

/// Screen 3: How much do you study per day?
///
/// Creative 2x3 grid of tappable glass cards with emoji icons.
/// Selected card lifts, glows, emoji scales up.
/// AnimatedSwitcher for the "X hours per day" text.
class OnboardingStudyTimePage extends StatefulWidget {
  final bool isActive;
  final int? selectedIndex;
  final void Function(int index, double hours, String label) onSelect;

  const OnboardingStudyTimePage({
    super.key,
    required this.isActive,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<OnboardingStudyTimePage> createState() =>
      _OnboardingStudyTimePageState();
}

class _OnboardingStudyTimePageState extends State<OnboardingStudyTimePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasAnimated = false;

  static const _timeOptions = [
    (emoji: '⏰', label: '30 min', subtitle: 'Quick sessions', hours: 0.5),
    (emoji: '📖', label: '1 hour', subtitle: 'Steady pace', hours: 1.0),
    (emoji: '☕', label: '2 hours', subtitle: 'Focused study', hours: 2.0),
    (emoji: '🎯', label: '3 hours', subtitle: 'Dedicated learner', hours: 3.0),
    (emoji: '🔥', label: '5 hours', subtitle: 'Power student', hours: 5.0),
    (emoji: '🚀', label: '8 hours', subtitle: 'Full commitment', hours: 8.0),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isActive) _animate();
  }

  @override
  void didUpdateWidget(OnboardingStudyTimePage old) {
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

  String get _selectedLabel {
    if (widget.selectedIndex == null) return '';
    return _timeOptions[widget.selectedIndex!].label;
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
                    'assets/images/onboarding/onboarding_study_time.png',
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
                      'How much do you\nstudy per day?',
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

                // Animated time label
                SizedBox(
                  height: 32,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: widget.selectedIndex != null
                        ? Text(
                            '$_selectedLabel per day',
                            key: ValueKey(widget.selectedIndex),
                            style: AppTypography.h3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : Text(
                            "We'll adapt your plan to your routine.",
                            key: const ValueKey('subtitle'),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.55,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 2x3 grid
                _buildGrid(),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - AppSpacing.sm) / 2; // 2 columns
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: List.generate(_timeOptions.length, (i) {
            // Stagger: scale from 0.7 to 1.0
            final start = (0.2 + i * 0.08).clamp(0.0, 1.0);
            final end = (start + 0.35).clamp(0.0, 1.0);
            final progress = CurvedAnimation(
              parent: _controller,
              curve: Interval(start, end, curve: AppAnimations.curveBounce),
            ).value;

            final opt = _timeOptions[i];

            return SizedBox(
              width: cardWidth,
              height: 100,
              child: Transform.scale(
                scale: 0.7 + 0.3 * progress,
                child: Opacity(
                  opacity: progress,
                  child: StudyTimeCard(
                    emoji: opt.emoji,
                    label: opt.label,
                    subtitle: opt.subtitle,
                    isSelected: widget.selectedIndex == i,
                    hasSelection: widget.selectedIndex != null,
                    onTap: () =>
                        widget.onSelect(i, opt.hours, opt.label),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
