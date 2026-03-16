import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/animated_counter.dart';
import 'typewriter_text.dart';

/// Screen 7: Students love Kapsa.
///
/// AnimatedCounter for "50,000+", stars stagger in, 3-testimonial carousel,
/// animated stat card for "In 30 days: +40% grades".
/// If user uploaded material, shows personalized "Your X flashcards are ready!".
///
/// Testimonial quotes are typed out character-by-character with haptic feedback.
class OnboardingSocialProofPage extends StatefulWidget {
  final bool isActive;
  final bool materialUploaded;
  final int flashcardCount;

  const OnboardingSocialProofPage({
    super.key,
    required this.isActive,
    this.materialUploaded = false,
    this.flashcardCount = 0,
  });

  @override
  State<OnboardingSocialProofPage> createState() =>
      _OnboardingSocialProofPageState();
}

class _OnboardingSocialProofPageState extends State<OnboardingSocialProofPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final PageController _testimonialController;
  Timer? _autoScrollTimer;
  bool _hasAnimated = false;
  int _currentTestimonial = 0;
  bool _counterFired = false;
  final Set<int> _starHapticFired = {};

  static List<({String name, String role, String avatar, String quote})>
      _testimonials(AppLocalizations l) => [
    (
      name: l.testimonialSofiaName,
      role: l.testimonialSofiaRole,
      avatar: 'assets/images/avatars/avatar_social_03_female.png',
      quote: l.testimonialSofiaQuote,
    ),
    (
      name: l.testimonialMarcoName,
      role: l.testimonialMarcoRole,
      avatar: 'assets/images/avatars/avatar_social_04_male.png',
      quote: l.testimonialMarcoQuote,
    ),
    (
      name: l.testimonialLuciaName,
      role: l.testimonialLuciaRole,
      avatar: 'assets/images/avatars/avatar_social_01_female.png',
      quote: l.testimonialLuciaQuote,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _testimonialController = PageController();
    if (widget.isActive) _animate();
  }

  @override
  void didUpdateWidget(OnboardingSocialProofPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_hasAnimated) _animate();
  }

  void _animate() {
    _hasAnimated = true;
    _controller.forward();

    // Haptic when counter finishes (~1.2s after controller starts at 0.15)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_counterFired) {
        _counterFired = true;
        HapticFeedback.mediumImpact();
      }
    });

    // Start auto-scroll after testimonial is visible
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = (_currentTestimonial + 1) % 3;
      _testimonialController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _testimonialController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final testimonials = _testimonials(l);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final headerOpacity = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.15, curve: Curves.easeOut),
        ).value;

        final counterReady = _controller.value > 0.15;
        const starsStart = 0.35;
        final testimonialProgress = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.50, 0.75, curve: Curves.easeOutCubic),
        ).value;
        final statCardProgress = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.7, 0.95, curve: Curves.easeOutQuart),
        ).value;

        final screenH = MediaQuery.of(context).size.height;
        final imgSize = (screenH * 0.13).clamp(75.0, 110.0);

        // Testimonials should start typing after they become visible
        final canType = testimonialProgress > 0.5;

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
                    'assets/images/onboarding/onboarding_social_proof.png',
                    width: imgSize,
                    height: imgSize,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Title
                Opacity(
                  opacity: headerOpacity,
                  child: Text(
                    l.socialProofTitle,
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

                const SizedBox(height: AppSpacing.lg),

                // Animated counter
                if (counterReady)
                  AnimatedCounter(
                    value: 50000,
                    duration: const Duration(milliseconds: 1200),
                    suffix: '+',
                    style: AppTypography.h1.copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                if (counterReady)
                  Text(
                    widget.materialUploaded && widget.flashcardCount > 0
                        ? l.socialProofFlashcardsReady(widget.flashcardCount)
                        : l.socialProofActiveStudents,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white38,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: AppSpacing.md),

                // Star rating — stagger in one by one with haptic
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starStart = starsStart + i * 0.05;
                    final starEnd = (starStart + 0.1).clamp(0.0, 1.0);
                    final starProgress = CurvedAnimation(
                      parent: _controller,
                      curve: Interval(starStart, starEnd,
                          curve: AppAnimations.curveBounce),
                    ).value;

                    // Haptic when star pops in (fire once per star)
                    if (starProgress > 0.8 && !_starHapticFired.contains(i)) {
                      _starHapticFired.add(i);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) HapticFeedback.lightImpact();
                      });
                    }

                    return AnimatedScale(
                      scale: starProgress,
                      duration: Duration.zero,
                      child: Opacity(
                        opacity: starProgress,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFCC00),
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Testimonial carousel with typing effect
                Opacity(
                  opacity: testimonialProgress,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - testimonialProgress)),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 155,
                          child: PageView.builder(
                            controller: _testimonialController,
                            onPageChanged: (i) =>
                                setState(() => _currentTestimonial = i),
                            itemCount: testimonials.length,
                            itemBuilder: (context, i) {
                              final t = testimonials[i];
                              return _TestimonialCard(
                                key: ValueKey('testimonial_${i}_$_currentTestimonial'),
                                name: t.name,
                                role: t.role,
                                avatar: t.avatar,
                                quote: t.quote,
                                shouldType: canType && i == _currentTestimonial,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(testimonials.length, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentTestimonial == i ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentTestimonial == i
                                    ? AppColors.primary
                                    : AppColors.primary
                                        .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Stat card: "In 30 days"
                Opacity(
                  opacity: statCardProgress,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - statCardProgress)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.primary.withValues(alpha: 0.03),
                          ],
                        ),
                        borderRadius: AppRadius.borderRadiusMd,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('\u{1F4C8}',
                              style: TextStyle(fontSize: 28)),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.socialProofIn30Days,
                                style: AppTypography.labelLarge.copyWith(
                                  color:
                                      Colors.white,
                                ),
                              ),
                              Text(
                                l.socialProofGradeImprovement,
                                style: AppTypography.bodySmall.copyWith(
                                  color:
                                      Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}

class _TestimonialCard extends StatelessWidget {
  final String name;
  final String role;
  final String avatar;
  final String quote;
  final bool shouldType;

  const _TestimonialCard({
    super.key,
    required this.name,
    required this.role,
    required this.avatar,
    required this.quote,
    required this.shouldType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote with typewriter effect
          Expanded(
            child: shouldType
                ? TypewriterText(
                    text: quote,
                    animate: true,
                    charDelay: const Duration(milliseconds: 25),
                    showCursor: true,
                    cursorColor: AppColors.primary,
                    onCharTyped: () {
                      HapticFeedback.selectionClick();
                    },
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.left,
                  )
                : Text(
                    quote,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(avatar),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    role,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (_) => const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFCC00),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
