import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/circular_progress_ring.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/theme/app_gradients.dart';

/// Screen 6: Creating your study toolkit... (animated processing)
///
/// Shows a convincing processing animation with estimated counts.
/// Only appears if the user uploaded material in the previous step.
/// Auto-advances after the animation completes.
class OnboardingProcessingPage extends StatefulWidget {
  final bool isActive;
  final int estimatedFlashcards;
  final int estimatedQuizzes;
  final VoidCallback onComplete;

  const OnboardingProcessingPage({
    super.key,
    required this.isActive,
    required this.estimatedFlashcards,
    required this.estimatedQuizzes,
    required this.onComplete,
  });

  @override
  State<OnboardingProcessingPage> createState() =>
      _OnboardingProcessingPageState();
}

class _OnboardingProcessingPageState extends State<OnboardingProcessingPage>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _fadeController;
  bool _hasStarted = false;
  int _currentStep = 0;
  bool _showContinue = false;
  Timer? _stepTimer;
  Timer? _autoAdvanceTimer;

  static const _stepDuration = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.isActive) _start();
  }

  @override
  void didUpdateWidget(OnboardingProcessingPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_hasStarted) _start();
  }

  void _start() {
    _hasStarted = true;
    _progressController.forward();
    _advanceSteps();
  }

  void _advanceSteps() {
    _stepTimer = Timer.periodic(_stepDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentStep < 3) {
        setState(() => _currentStep++);
      } else {
        timer.cancel();
        // Show continue button after last step settles
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() => _showContinue = true);
            _fadeController.forward();
            // Auto-advance after 2 more seconds
            _autoAdvanceTimer = Timer(const Duration(seconds: 2), () {
              if (mounted) widget.onComplete();
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    _stepTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    final imgSize = (screenH * 0.12).clamp(70.0, 100.0);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            SizedBox(height: screenH * 0.04),

            // Mascot
            Image.asset(
              'assets/images/onboarding/onboarding_flashcards.png',
              width: imgSize,
              height: imgSize,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              'Creating your\nstudy toolkit...',
              style: AppTypography.h1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
                color: AppColors.textPrimaryFor(brightness),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: screenH * 0.04),

            // Progress ring
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, _) {
                return CircularProgressRing(
                  progress: _progressController.value,
                  size: 100,
                  strokeWidth: 8,
                  trackColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    '${(_progressController.value * 100).round()}%',
                    style: AppTypography.h2.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: screenH * 0.04),

            // Processing steps
            ..._buildSteps(brightness, isDark),

            const SizedBox(height: AppSpacing.xl),

            // Continue button (appears after processing)
            AnimatedOpacity(
              opacity: _showContinue ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: AnimatedSlide(
                offset: Offset(0, _showContinue ? 0 : 0.3),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                child: TapScale(
                  onTap: () {
                    _autoAdvanceTimer?.cancel();
                    widget.onComplete();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryToIndigo,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Continue',
                        style: AppTypography.button.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSteps(Brightness brightness, bool isDark) {
    final steps = [
      (
        icon: '\u{1F4C4}',
        loading: 'Reading your material...',
        done: '\u{2713} Material analyzed',
      ),
      (
        icon: '\u{1F0CF}',
        loading: 'Generating flashcards...',
        done: '\u{2713} ${widget.estimatedFlashcards} flashcards created',
      ),
      (
        icon: '\u{1F4DD}',
        loading: 'Creating quiz questions...',
        done: '\u{2713} ${widget.estimatedQuizzes} quiz questions ready',
      ),
      (
        icon: '\u{1F4C5}',
        loading: 'Building your study plan...',
        done: '\u{2713} Study plan ready!',
      ),
    ];

    return List.generate(steps.length, (i) {
      final step = steps[i];
      final isCompleted = _currentStep > i;
      final isCurrent = _currentStep == i;

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success.withValues(alpha: isDark ? 0.12 : 0.08)
                : isCurrent
                    ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.3)
                  : isCurrent
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              if (isCompleted)
                const Icon(Icons.check_circle, size: 20, color: AppColors.success)
              else if (isCurrent)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                Text(step.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isCompleted ? step.done : step.loading,
                    key: ValueKey('step_${i}_$isCompleted'),
                    style: AppTypography.bodyMedium.copyWith(
                      color: isCompleted
                          ? AppColors.success
                          : isCurrent
                              ? AppColors.textPrimaryFor(brightness)
                              : AppColors.textMutedFor(brightness),
                      fontWeight:
                          isCompleted || isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
