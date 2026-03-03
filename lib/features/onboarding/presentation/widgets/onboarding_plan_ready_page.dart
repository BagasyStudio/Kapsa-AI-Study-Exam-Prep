import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/animated_counter.dart';
import '../../../../core/widgets/circular_progress_ring.dart';
import '../../../../core/widgets/confetti_overlay.dart';

/// Screen 8: Your plan is ready!
///
/// Confetti burst on entrance. Progress ring fills 0→100%.
/// Personalized stats stagger in. Shows urgency messaging if exam
/// is coming soon and material counts if material was uploaded.
class OnboardingPlanReadyPage extends StatefulWidget {
  final bool isActive;
  final String? studyArea;
  final String? challenge;
  final String studyTime;
  final int? examUrgency;
  final bool materialUploaded;
  final int flashcardCount;
  final int quizCount;

  const OnboardingPlanReadyPage({
    super.key,
    required this.isActive,
    this.studyArea,
    this.challenge,
    required this.studyTime,
    this.examUrgency,
    this.materialUploaded = false,
    this.flashcardCount = 0,
    this.quizCount = 0,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_confettiFired) {
        _confettiFired = true;
        ConfettiOverlay.show(context);
      }
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ringController.forward();
    });
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

  List<(String, String)> _stats(AppLocalizations l) {
    final items = <(String, String)>[
      ('\u{1F4DA}', l.planReadyStudyArea(widget.studyArea ?? l.planReadyNotSet)),
      ('\u{26A1}', l.planReadyFocus(widget.challenge ?? l.planReadyNotSet)),
      ('\u{23F0}', l.planReadyTime(widget.studyTime)),
      ('\u{1F3AF}', l.planReadyAiTools),
    ];

    if (widget.materialUploaded && widget.flashcardCount > 0) {
      items.add((
        '\u{1F0CF}',
        l.planReadyMaterial(widget.flashcardCount, widget.quizCount),
      ));
    }

    return items;
  }

  bool get _hasUrgency =>
      widget.examUrgency != null && widget.examUrgency! <= 1;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final screenH = MediaQuery.of(context).size.height;
    final ringSize = (screenH * 0.16).clamp(110.0, 150.0);
    final ringStroke = ringSize * 0.08;
    final isDark = brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              l.planReadyTitle,
              style: AppTypography.h1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
                color: AppColors.textPrimaryFor(brightness),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xl),

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
                  size: ringSize,
                  strokeWidth: ringStroke,
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
                          l.planReadyPersonalized,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMutedFor(brightness),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Urgency banner
            if (_hasUrgency)
              AnimatedBuilder(
                animation: _statsController,
                builder: (context, _) {
                  final progress = CurvedAnimation(
                    parent: _statsController,
                    curve: const Interval(0, 0.4,
                        curve: Curves.easeOutCubic),
                  ).value;
                  final isThisWeek = widget.examUrgency == 0;
                  final urgencyColor = isThisWeek
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B);

                  return Opacity(
                    opacity: progress,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - progress)),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: urgencyColor
                              .withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: AppRadius.borderRadiusMd,
                          border: Border.all(
                            color: urgencyColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              isThisWeek ? '\u{1F6A8}' : '\u{26A1}',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                widget.examUrgency == 0 ? l.planReadyUrgencyThisWeek : l.planReadyUrgencyThisMonth,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: urgencyColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Personalized stats
            AnimatedBuilder(
              animation: _statsController,
              builder: (context, _) {
                final stats = _stats(l);
                return Column(
                  children: List.generate(stats.length, (i) {
                    final start = (i * 0.25).clamp(0.0, 1.0);
                    final end = (start + 0.45).clamp(0.0, 1.0);
                    final progress = CurvedAnimation(
                      parent: _statsController,
                      curve: Interval(start, end,
                          curve: AppAnimations.curveEntrance),
                    ).value;

                    final stat = stats[i];

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
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.55),
                              borderRadius: AppRadius.borderRadiusMd,
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.2),
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
                                    style:
                                        AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textPrimaryFor(
                                          brightness),
                                      fontWeight: FontWeight.w600,
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

            const SizedBox(height: AppSpacing.md),

            // Small mascot
            Image.asset(
              'assets/images/onboarding/onboarding_plan_ready.png',
              width: (screenH * 0.08).clamp(50.0, 75.0),
              height: (screenH * 0.08).clamp(50.0, 75.0),
              fit: BoxFit.contain,
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
