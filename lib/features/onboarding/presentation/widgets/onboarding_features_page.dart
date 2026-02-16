import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../../core/theme/app_gradients.dart';
import 'feature_carousel_card.dart';

/// Screen 5: What Kapsa can do.
///
/// Horizontal carousel of 4 feature cards with parallax + auto-advance.
class OnboardingFeaturesPage extends StatefulWidget {
  final bool isActive;

  const OnboardingFeaturesPage({super.key, required this.isActive});

  @override
  State<OnboardingFeaturesPage> createState() =>
      _OnboardingFeaturesPageState();
}

class _OnboardingFeaturesPageState extends State<OnboardingFeaturesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final PageController _carouselController;
  Timer? _autoAdvanceTimer;
  int _activeFeature = 0;
  bool _hasAnimated = false;

  static const _features = [
    (
      image: 'assets/images/onboarding/onboarding_capture.png',
      title: 'Capture Everything',
      description:
          'Scan photos, upload PDFs or record audio.\nKapsa turns it into study material.',
      icon: Icons.camera_alt_outlined,
    ),
    (
      image: 'assets/images/onboarding/onboarding_flashcards.png',
      title: 'AI Flashcards',
      description:
          'Generate flashcards automatically from any material.\nStudy the smart way.',
      icon: Icons.style_outlined,
    ),
    (
      image: 'assets/images/onboarding/onboarding_quiz.png',
      title: 'Smart Quizzes',
      description:
          'Test your knowledge with AI-generated quizzes.\nKnow exactly what to review.',
      icon: Icons.quiz_outlined,
    ),
    (
      image: 'assets/images/onboarding/onboarding_chat.png',
      title: 'Study Assistant',
      description:
          'Chat with AI about your materials.\nAsk anything you need.',
      icon: Icons.chat_bubble_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(viewportFraction: 0.78);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isActive) _animate();
  }

  @override
  void didUpdateWidget(OnboardingFeaturesPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_hasAnimated) _animate();
    if (!widget.isActive) _stopAutoAdvance();
  }

  void _animate() {
    _hasAnimated = true;
    _entranceController.forward();
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_activeFeature + 1) % _features.length;
      _carouselController.animateToPage(
        next,
        duration: AppAnimations.durationEntrance,
        curve: AppAnimations.curveStandard,
      );
    });
  }

  void _stopAutoAdvance() {
    _autoAdvanceTimer?.cancel();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _entranceController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        final headerOpacity = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0, 0.4, curve: Curves.easeOut),
        ).value;

        final carouselOpacity = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
        ).value;

        return Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),

            // Title
            Opacity(
              opacity: headerOpacity,
              child: GradientText(
                'What Kapsa can do',
                style: AppTypography.h1.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
                gradient: AppGradients.primaryToIndigo,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Carousel
            Opacity(
              opacity: carouselOpacity,
              child: SizedBox(
                height: 340,
                child: PageView.builder(
                  controller: _carouselController,
                  onPageChanged: (i) {
                    setState(() => _activeFeature = i);
                    // Reset auto-advance on manual swipe
                    _startAutoAdvance();
                  },
                  itemCount: _features.length,
                  itemBuilder: (context, index) {
                    final feature = _features[index];
                    return AnimatedBuilder(
                      animation: _carouselController,
                      builder: (context, child) {
                        double pageOffset = 0;
                        if (_carouselController.position.haveDimensions) {
                          pageOffset =
                              _carouselController.page! - index;
                        }
                        final parallax = pageOffset * 30;
                        final scale =
                            (1 - pageOffset.abs() * 0.08).clamp(0.92, 1.0);

                        return Transform.scale(
                          scale: scale,
                          child: FeatureCarouselCard(
                            imagePath: feature.image,
                            title: feature.title,
                            description: feature.description,
                            icon: feature.icon,
                            imageParallaxOffset: parallax,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Page indicators
            Opacity(
              opacity: carouselOpacity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_features.length, (i) {
                  final isActive = _activeFeature == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}
