import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/theme/app_gradients.dart';
import 'typewriter_text.dart';

/// Screen 6: Creating your study toolkit... (animated processing)
///
/// Premium multi-layered orb animation with rotating ring, floating particles,
/// shimmer progress bar, and bounce-in step cards with haptic feedback.
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
  late final AnimationController _pulseController;
  late final AnimationController _ringController;

  bool _hasStarted = false;
  int _currentStep = 0;
  bool _showContinue = false;
  Timer? _stepTimer;
  Timer? _autoAdvanceTimer;
  Timer? _particleTimer;

  // Particles state
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  static const _stepDuration = Duration(milliseconds: 2500);

  static const _stepIcons = [
    Icons.description_outlined,
    Icons.style_outlined,
    Icons.quiz_outlined,
    Icons.event_note_outlined,
  ];

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();

    _initParticles();

    if (widget.isActive) _start();
  }

  @override
  void didUpdateWidget(OnboardingProcessingPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_hasStarted) _start();
  }

  void _initParticles() {
    for (int i = 0; i < 10; i++) {
      _particles.add(_Particle.random(_random));
    }
    _particleTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        for (final p in _particles) {
          p.y -= p.speed;
          p.x += p.drift;
          p.alpha = (p.alpha - 0.005).clamp(0.0, 1.0);
          if (p.y < -0.1 || p.alpha <= 0) {
            p.reset(_random);
          }
        }
      });
    });
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
        HapticFeedback.mediumImpact();
      } else {
        timer.cancel();
        // Show continue button after last step settles
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            HapticFeedback.heavyImpact();
            setState(() => _showContinue = true);
            _fadeController.forward();
            HapticFeedback.lightImpact();
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
    _pulseController.dispose();
    _ringController.dispose();
    _stepTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _particleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final screenH = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            SizedBox(height: screenH * 0.03),

            // Title with typewriter
            TypewriterText(
              text: l.processingTitle,
              animate: _hasStarted,
              charDelay: const Duration(milliseconds: 35),
              showCursor: true,
              cursorColor: AppColors.primary,
              onCharTyped: () => HapticFeedback.selectionClick(),
              style: AppTypography.h1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),

            SizedBox(height: screenH * 0.03),

            // Neural orb multi-layer
            _buildOrb(),

            const SizedBox(height: AppSpacing.lg),

            // Shimmer progress bar
            _buildShimmerProgressBar(),

            SizedBox(height: screenH * 0.03),

            // Processing steps
            ..._buildSteps(l),

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
                        l.processingContinue,
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

  // ── Neural Orb ──

  Widget _buildOrb() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _ringController, _progressController]),
      builder: (context, _) {
        final pulse = _pulseController.value;
        final orbScale = 0.95 + pulse * 0.05;
        final glowAlpha = 0.15 + pulse * 0.15;

        return SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Layer 1: Ambient glow
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: glowAlpha),
                      blurRadius: 50 + pulse * 20,
                      spreadRadius: 8 + pulse * 12,
                    ),
                  ],
                ),
              ),

              // Layer 2: Rotating dashed ring
              SizedBox(
                width: 140,
                height: 140,
                child: Transform.rotate(
                  angle: _ringController.value * 2 * math.pi,
                  child: CustomPaint(
                    painter: _OnboardingRingPainter(
                      color: AppColors.primary.withValues(alpha: 0.25 + pulse * 0.1),
                    ),
                  ),
                ),
              ),

              // Layer 3: Floating particles
              SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _OnboardingParticlePainter(
                    particles: _particles,
                    color: AppColors.primary,
                  ),
                ),
              ),

              // Layer 4: Main orb body
              Transform.scale(
                scale: orbScale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.2, -0.3),
                      radius: 0.8,
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.7),
                        const Color(0xFF3538A0),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),

              // Layer 5: Step icon + percentage
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Icon(
                      _stepIcons[_currentStep.clamp(0, 3)],
                      key: ValueKey('orb_icon_$_currentStep'),
                      size: 28,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(_progressController.value * 100).round()}%',
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Shimmer Progress Bar ──

  Widget _buildShimmerProgressBar() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        final progress = _progressController.value;

        return Column(
          children: [
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Stack(
                  children: [
                    // Fill
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryLight,
                              AppColors.primary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Shimmer sweep
                    if (progress > 0.01)
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            final shimmerPos =
                                (DateTime.now().millisecondsSinceEpoch % 2000) / 2000;
                            return LinearGradient(
                              begin: Alignment(-1 + shimmerPos * 3, 0),
                              end: Alignment(-0.5 + shimmerPos * 3, 0),
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Step Cards ──

  List<Widget> _buildSteps(AppLocalizations l) {
    final steps = [
      (
        icon: Icons.description_outlined,
        loading: l.processingStepReading,
        done: l.processingStepReadingDone,
      ),
      (
        icon: Icons.style_outlined,
        loading: l.processingStepFlashcards,
        done: l.processingStepFlashcardsDone(widget.estimatedFlashcards),
      ),
      (
        icon: Icons.quiz_outlined,
        loading: l.processingStepQuiz,
        done: l.processingStepQuizDone(widget.estimatedQuizzes),
      ),
      (
        icon: Icons.event_note_outlined,
        loading: l.processingStepPlan,
        done: l.processingStepPlanDone,
      ),
    ];

    return List.generate(steps.length, (i) {
      final step = steps[i];
      final isCompleted = _currentStep > i;
      final isCurrent = _currentStep == i;

      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulse = _pulseController.value;
          final borderAlpha = isCurrent ? 0.15 + pulse * 0.15 : 0.0;

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
                gradient: isCompleted
                    ? LinearGradient(colors: [
                        AppColors.success.withValues(alpha: 0.10),
                        AppColors.success.withValues(alpha: 0.04),
                      ])
                    : null,
                color: isCompleted
                    ? null
                    : isCurrent
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success.withValues(alpha: 0.3)
                      : isCurrent
                          ? AppColors.primary.withValues(alpha: borderAlpha.clamp(0.0, 1.0))
                          : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  // Status icon with bounce animation
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutBack,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: isCompleted
                          ? const Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey('check'),
                              size: 22,
                              color: AppColors.success,
                            )
                          : isCurrent
                              ? SizedBox(
                                  key: const ValueKey('loading'),
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Icon(
                                  step.icon,
                                  key: ValueKey('pending_$i'),
                                  size: 20,
                                  color: Colors.white38
                                      .withValues(alpha: 0.5),
                                ),
                    ),
                  ),
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
                                  ? Colors.white
                                  : Colors.white38,
                          fontWeight:
                              isCompleted || isCurrent ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  // Trailing icon for completed/current
                  if (isCompleted)
                    Icon(
                      step.icon,
                      size: 16,
                      color: AppColors.success.withValues(alpha: 0.5),
                    )
                  else if (isCurrent)
                    Icon(
                      step.icon,
                      size: 16,
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Particle data
// ─────────────────────────────────────────────────────────────

class _Particle {
  double x;
  double y;
  double speed;
  double size;
  double alpha;
  double drift;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.alpha,
    required this.drift,
  });

  factory _Particle.random(math.Random rng) {
    return _Particle(
      x: rng.nextDouble(),
      y: 0.8 + rng.nextDouble() * 0.3,
      speed: 0.003 + rng.nextDouble() * 0.005,
      size: 1.5 + rng.nextDouble() * 2.0,
      alpha: 0.3 + rng.nextDouble() * 0.5,
      drift: (rng.nextDouble() - 0.5) * 0.002,
    );
  }

  void reset(math.Random rng) {
    x = 0.2 + rng.nextDouble() * 0.6;
    y = 1.0 + rng.nextDouble() * 0.2;
    speed = 0.003 + rng.nextDouble() * 0.005;
    size = 1.5 + rng.nextDouble() * 2.0;
    alpha = 0.3 + rng.nextDouble() * 0.5;
    drift = (rng.nextDouble() - 0.5) * 0.002;
  }
}

// ─────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────

class _OnboardingRingPainter extends CustomPainter {
  final Color color;

  _OnboardingRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw 6 dashed arcs
    const arcCount = 6;
    const sweepAngle = 0.65;
    const gapAngle = (2 * math.pi - arcCount * sweepAngle) / arcCount;

    for (int i = 0; i < arcCount; i++) {
      final startAngle = i * (sweepAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OnboardingRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _OnboardingParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;

  _OnboardingParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = color.withValues(alpha: p.alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OnboardingParticlePainter oldDelegate) => true;
}
