import 'package:flutter/material.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/animated_counter.dart';
import '../../../../core/widgets/circular_progress_ring.dart';
import '../../../../core/widgets/confetti_overlay.dart';

/// Screen 4: Your plan is ready!
///
/// Confetti burst on entrance. Progress ring fills 0→100%.
/// Personalized stats stagger in from the left.
class OnboardingPlanReadyPage extends StatefulWidget {
  final bool isActive;
  final String? studyArea;
  final String? challenge;
  final String studyTime;

  const OnboardingPlanReadyPage({
    super.key,
    required this.isActive,
    this.studyArea,
    this.challenge,
    required this.studyTime,
  });

  @override
  State<OnboardingPlanReadyPage> createState() =>
      _OnboardingPlanReadyPageState();
}

class _OnboardingPlanReadyPageState extends State<OnboardingPlanReadyPage>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _statsController;
  bool _hasAnimated = false;
  bool _confettiFired = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (widget.isActive) _animate();
  }

  @override
  void didUpdateWidget(OnboardingPlanReadyPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_hasAnimated) _animate();
  }

  void _animate() {
    _hasAnimated = true;
    // Fire confetti after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_confettiFired) {
        _confettiFired = true;
        ConfettiOverlay.show(context);
      }
    });
    // Start ring fill after brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ringController.forward();
    });
    // Start stats stagger after ring is mostly done
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _statsController.forward();
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  List<(String, String)> get _stats => [
        ('📚', 'Study area: ${widget.studyArea ?? 'Not set'}'),
        ('⚡', 'Challenge: ${widget.challenge ?? 'Not set'}'),
        ('⏰', 'Time: ${widget.studyTime} per day'),
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

            // Title
            Text(
              'Your plan is\nready!',
              style: AppTypography.h1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Progress ring with counter
            AnimatedBuilder(
              animation: _ringController,
              builder: (context, _) {
                final ringProgress = CurvedAnimation(
                  parent: _ringController,
                  curve: AppAnimations.curveDecelerate,
                ).value;

                return CircularProgressRing(
                  progress: ringProgress,
                  size: 180,
                  strokeWidth: 14,
                  trackColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedCounter(
                        value: 100,
                        duration: const Duration(milliseconds: 1400),
                        suffix: '%',
                        style: AppTypography.h1.copyWith(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: ringProgress > 0.5 ? 1.0 : 0.0,
                        child: Text(
                          'Personalized',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Personalized stats
            AnimatedBuilder(
              animation: _statsController,
              builder: (context, _) {
                return Column(
                  children: List.generate(_stats.length, (i) {
                    final start = (i * 0.3).clamp(0.0, 1.0);
                    final end = (start + 0.5).clamp(0.0, 1.0);
                    final progress = CurvedAnimation(
                      parent: _statsController,
                      curve: Interval(start, end,
                          curve: AppAnimations.curveEntrance),
                    ).value;

                    final stat = _stats[i];

                    return Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(-40 * (1 - progress), 0),
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              borderRadius: AppRadius.borderRadiusMd,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(stat.$1,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    stat.$2,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Small mascot
            Image.asset(
              'assets/images/onboarding/onboarding_plan_ready.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
