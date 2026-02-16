import 'package:flutter/material.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Screen 1: What do you study?
///
/// Chips stagger in alternating from left/right. Selected chip scales up and glows.
class OnboardingStudyAreaPage extends StatefulWidget {
  final bool isActive;
  final int? selectedArea;
  final ValueChanged<int> onSelect;

  const OnboardingStudyAreaPage({
    super.key,
    required this.isActive,
    required this.selectedArea,
    required this.onSelect,
  });

  @override
  State<OnboardingStudyAreaPage> createState() =>
      _OnboardingStudyAreaPageState();
}

class _OnboardingStudyAreaPageState extends State<OnboardingStudyAreaPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasAnimated = false;

  static const _areas = [
    '🔬 Sciences',
    '📐 Engineering',
    '⚖️ Law',
    '💊 Medicine',
    '📊 Economics',
    '🎨 Arts',
    '💻 Computer Science',
    '📚 Other',
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
  void didUpdateWidget(OnboardingStudyAreaPage old) {
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

  double _chipInterval(int i) => (0.3 + i * 0.07).clamp(0.0, 1.0);
  double _chipEnd(int i) => (_chipInterval(i) + 0.35).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Header animations
        final headerOpacity = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.3, curve: Curves.easeOut),
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
                    'assets/images/onboarding/onboarding_study_area.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Title
                Opacity(
                  opacity: headerOpacity,
                  child: Transform.translate(
                    offset: Offset(0, headerSlide),
                    child: Text(
                      'What do you\nstudy?',
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
                    'Customize your experience by choosing\nyour study area.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Study area chips
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.center,
                  children: List.generate(_areas.length, _buildChip),
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(int i) {
    final interval = _chipInterval(i);
    final end = _chipEnd(i);
    final progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(interval, end, curve: AppAnimations.curveBounce),
    ).value;

    // Alternate direction: even from left, odd from right
    final slideX = (i.isEven ? -30.0 : 30.0) * (1 - progress);
    final isSelected = widget.selectedArea == i;

    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(slideX, 0),
        child: TapScale(
          onTap: () => widget.onSelect(i),
          child: AnimatedScale(
            scale: isSelected ? 1.05 : 1.0,
            duration: AppAnimations.durationMedium,
            curve: AppAnimations.curveBounce,
            child: AnimatedContainer(
              duration: AppAnimations.durationMedium,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _areas[i],
                style: AppTypography.labelMedium.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
