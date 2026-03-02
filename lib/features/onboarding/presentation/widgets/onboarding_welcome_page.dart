import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gradient_text.dart';
import 'sparkle_particles.dart';

/// Screen 0: Welcome to Kapsa.
///
/// Mascot bounces in with elastic curve, title staggers word-by-word,
/// sparkle particles float around the mascot area.
class OnboardingWelcomePage extends StatefulWidget {
  final bool isActive;

  const OnboardingWelcomePage({super.key, required this.isActive});

  @override
  State<OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<OnboardingWelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _mascotSlide;
  late final Animation<double> _mascotScale;
  late final Animation<double> _mascotOpacity;
  // Staggered word animations
  late final Animation<double> _word0;
  late final Animation<double> _word1;
  late final Animation<double> _word2;
  late final Animation<double> _subtitleOpacity;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Mascot: 0-800ms, elasticOut
    _mascotSlide = Tween(begin: 120.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.67, curve: Curves.elasticOut),
      ),
    );
    _mascotScale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.67, curve: Curves.elasticOut),
      ),
    );
    _mascotOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.25, curve: Curves.easeOut),
      ),
    );

    // Words stagger: "Welcome" at 33%, "to" at 43%, "Kapsa" at 53%
    _word0 = _wordAnim(0.33, 0.6);
    _word1 = _wordAnim(0.43, 0.7);
    _word2 = _wordAnim(0.53, 0.8);

    // Subtitle: 58-83%
    _subtitleOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.83, curve: Curves.easeOut),
      ),
    );

    if (widget.isActive) _animate();
  }

  @override
  void didUpdateWidget(OnboardingWelcomePage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_hasAnimated) _animate();
  }

  void _animate() {
    _hasAnimated = true;
    _controller.forward();
  }

  Animation<double> _wordAnim(double begin, double end) {
    return Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: Curves.easeOutQuart),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final screenH = MediaQuery.of(context).size.height;
        final mascotBox = (screenH * 0.28).clamp(160.0, 260.0);
        final mascotImg = mascotBox * 0.78;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),

                // Mascot + sparkles
                SizedBox(
                  width: mascotBox,
                  height: mascotBox,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sparkles behind mascot
                      SparkleParticles(width: mascotBox, height: mascotBox),
                      // Mascot bouncing in
                      Transform.translate(
                        offset: Offset(0, _mascotSlide.value),
                        child: Transform.scale(
                          scale: _mascotScale.value,
                          child: Opacity(
                            opacity: _mascotOpacity.value,
                            child: Image.asset(
                              'assets/images/onboarding/onboarding_welcome.png',
                              width: mascotImg,
                              height: mascotImg,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Title — staggered words
                _buildTitle(brightness),

                const SizedBox(height: AppSpacing.sm),

                // Subtitle
                Opacity(
                  opacity: _subtitleOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _subtitleOpacity.value) * 10),
                    child: Text(
                      'Your smart study companion.\nAI-powered tools to ace exams\nand boost your GPA.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                        height: 1.55,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(Brightness brightness) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _animatedWord('Welcome ', _word0, brightness),
        _animatedWord('to ', _word1, brightness),
        // "Kapsa" uses gradient text
        Opacity(
          opacity: _word2.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _word2.value) * 15),
            child: GradientText(
              'Kapsa',
              style: AppTypography.h1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
              ),
              gradient: AppGradients.primaryToIndigo,
            ),
          ),
        ),
      ],
    );
  }

  Widget _animatedWord(String word, Animation<double> anim, Brightness brightness) {
    return Opacity(
      opacity: anim.value,
      child: Transform.translate(
        offset: Offset(0, (1 - anim.value) * 15),
        child: Text(
          word,
          style: AppTypography.h1.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.5,
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
      ),
    );
  }
}
