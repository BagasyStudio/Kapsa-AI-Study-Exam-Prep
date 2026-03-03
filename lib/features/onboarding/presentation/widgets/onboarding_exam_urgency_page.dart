import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'animated_checkmark.dart';

/// Screen 1: Do you have an exam coming up?
///
/// Establishes urgency early. Cards stagger in from the right.
/// Selected card gets animated checkmark + haptic feedback.
class OnboardingExamUrgencyPage extends StatefulWidget {
  final bool isActive;
  final int? selectedUrgency;
  final ValueChanged<int> onSelect;

  const OnboardingExamUrgencyPage({
    super.key,
    required this.isActive,
    required this.selectedUrgency,
    required this.onSelect,
  });

  @override
  State<OnboardingExamUrgencyPage> createState() =>
      _OnboardingExamUrgencyPageState();
}

class _OnboardingExamUrgencyPageState extends State<OnboardingExamUrgencyPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasAnimated = false;

  static List<({String emoji, String label})> _options(AppLocalizations l) => [
    (emoji: '\u{1F6A8}', label: l.examUrgencyThisWeek),
    (emoji: '\u{1F4C5}', label: l.examUrgencyThisMonth),
    (emoji: '\u{1F4C6}', label: l.examUrgencyFewMonths),
    (emoji: '\u{1F60C}', label: l.examUrgencyNoExams),
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
  void didUpdateWidget(OnboardingExamUrgencyPage old) {
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
    final options = _options(l);
    final brightness = Theme.of(context).brightness;
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
                    'assets/images/onboarding/onboarding_challenge.png',
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
                      l.examUrgencyTitle,
                      style: AppTypography.h1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimaryFor(brightness),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Opacity(
                  opacity: headerOpacity,
                  child: Text(
                    l.examUrgencySubtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                      height: 1.55,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Option cards
                ...List.generate(
                    options.length, (i) => _buildCard(i, options, brightness)),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(int i, List<({String emoji, String label})> options, Brightness brightness) {
    final start = (0.25 + i * 0.10).clamp(0.0, 1.0);
    final end = (start + 0.35).clamp(0.0, 1.0);
    final progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: AppAnimations.curveEntrance),
    ).value;

    final slideX = 60.0 * (1 - progress);
    final isSelected = widget.selectedUrgency == i;
    final hasSelection = widget.selectedUrgency != null;
    final option = options[i];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(slideX, 0),
          child: TapScale(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onSelect(i);
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: hasSelection && !isSelected ? 0.5 : 1.0,
              child: AnimatedContainer(
                duration: AppAnimations.durationMedium,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.12),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      option.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        option.label,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondaryFor(brightness),
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
