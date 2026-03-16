import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
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

  static List<({String emoji, String label, String subtitle, double hours})> _timeOptions(AppLocalizations l) => [
    (emoji: '\u23f0', label: l.studyTime30min, subtitle: l.studyTimeSub30, hours: 0.5),
    (emoji: '\ud83d\udcd6', label: l.studyTime1h, subtitle: l.studyTimeSub1, hours: 1.0),
    (emoji: '\u2615', label: l.studyTime2h, subtitle: l.studyTimeSub2, hours: 2.0),
    (emoji: '\ud83c\udfaf', label: l.studyTime3h, subtitle: l.studyTimeSub3, hours: 3.0),
    (emoji: '\ud83d\udd25', label: l.studyTime5h, subtitle: l.studyTimeSub5, hours: 5.0),
    (emoji: '\ud83d\ude80', label: l.studyTime8h, subtitle: l.studyTimeSub8, hours: 8.0),
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final timeOptions = _timeOptions(l);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final headerOpacity = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.25, curve: Curves.easeOut),
        ).value;
        final headerSlide = (1 - headerOpacity) * 20;

        final screenH = MediaQuery.of(context).size.height;
        final imgSize = (screenH * 0.15).clamp(90.0, 140.0);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),

                // Mascot
                Opacity(
                  opacity: headerOpacity,
                  child: Image.asset(
                    'assets/images/onboarding/onboarding_study_time.png',
                    width: imgSize,
                    height: imgSize,
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
                      l.studyTimeTitle,
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
                            l.studyTimePerDay(timeOptions[widget.selectedIndex!].label),
                            key: ValueKey(widget.selectedIndex),
                            style: AppTypography.h3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : Text(
                            l.studyTimeSubtitle,
                            key: const ValueKey('subtitle'),
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white60,
                              height: 1.55,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 2x3 grid
                _buildGrid(timeOptions),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<({String emoji, String label, String subtitle, double hours})> timeOptions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - AppSpacing.sm) / 2; // 2 columns
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: List.generate(timeOptions.length, (i) {
            // Stagger: scale from 0.7 to 1.0
            final start = (0.2 + i * 0.08).clamp(0.0, 1.0);
            final end = (start + 0.35).clamp(0.0, 1.0);
            final progress = CurvedAnimation(
              parent: _controller,
              curve: Interval(start, end, curve: AppAnimations.curveBounce),
            ).value;

            final opt = timeOptions[i];

            return SizedBox(
              width: cardWidth,
              height: 100,
              child: Transform.scale(
                scale: 0.7 + 0.3 * progress,
                child: Opacity(
                  opacity: progress.clamp(0.0, 1.0),
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
