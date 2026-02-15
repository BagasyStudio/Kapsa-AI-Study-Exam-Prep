import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/floating_orbs.dart';

// ─────────────────────────────────────────────────────────────
// Data model for each onboarding slide
// ─────────────────────────────────────────────────────────────

class _OnboardingSlide {
  final String image;
  final String title;
  final String subtitle;

  /// Optional: whether this slide has interactive input (screens 3-5).
  final _SlideType type;

  const _OnboardingSlide({
    required this.image,
    required this.title,
    required this.subtitle,
    this.type = _SlideType.info,
  });
}

enum _SlideType { info, selection, challenge, studyTime }

// ─────────────────────────────────────────────────────────────
// Slide definitions — 14 screens
// ─────────────────────────────────────────────────────────────

const _slides = <_OnboardingSlide>[
  // 0 — Welcome
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_welcome.png',
    title: 'Bienvenido a\nKapsa',
    subtitle: 'Tu compañero de estudio inteligente.\nHerramientas potenciadas con IA para\nalcanzar la excelencia académica.',
  ),

  // 1 — Social Proof
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_social_proof.png',
    title: 'Miles de\nestudiantes',
    subtitle: 'Ya usan Kapsa para estudiar más\ninteligente, no más duro.\nÚnete a la comunidad.',
  ),

  // 2 — ¿Qué estudias?
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_study_area.png',
    title: '¿Qué estudias?',
    subtitle: 'Personaliza tu experiencia eligiendo\ntu área de estudio.',
    type: _SlideType.selection,
  ),

  // 3 — ¿Cuál es tu mayor desafío?
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_challenge.png',
    title: '¿Cuál es tu\nmayor desafío?',
    subtitle: 'Identificamos cómo ayudarte mejor.',
    type: _SlideType.challenge,
  ),

  // 4 — ¿Cuánto tiempo estudias?
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_study_time.png',
    title: '¿Cuánto tiempo\nestudias por día?',
    subtitle: 'Adaptamos tu plan a tu rutina.',
    type: _SlideType.studyTime,
  ),

  // 5 — Plan personalizado
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_plan_ready.png',
    title: '¡Tu plan está\nlisto!',
    subtitle: 'Diseñamos una experiencia\npersonalizada para vos.',
  ),

  // 6 — Feature: Captura
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_capture.png',
    title: 'Captura todo',
    subtitle: 'Escaneá fotos, subí PDFs o grabá\naudio. Kapsa lo transforma en\nmaterial de estudio.',
  ),

  // 7 — Feature: Flashcards
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_flashcards.png',
    title: 'Flashcards\ncon IA',
    subtitle: 'Generá flashcards automáticamente\nde cualquier material.\nEstudiá de forma inteligente.',
  ),

  // 8 — Feature: Quiz
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_quiz.png',
    title: 'Quizzes\ninteligentes',
    subtitle: 'Evaluá tu conocimiento con\nquizzes generados por IA.\nSabé exactamente qué repasar.',
  ),

  // 9 — Feature: Chat IA
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_chat.png',
    title: 'Tu asistente\nde estudio',
    subtitle: 'Chateá con la IA sobre tus\nmateriales. Preguntá lo que\nnecesites, cuando lo necesites.',
  ),

  // 10 — Progreso
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_progress.png',
    title: 'En 30 días\npodrías...',
    subtitle: 'Mejorar tus notas significativamente.\nEstudiar el doble en la mitad\ndel tiempo.',
  ),

  // 11 — Testimonios
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_testimonials.png',
    title: 'Lo que dicen\nnuestros usuarios',
    subtitle: '"Kapsa me cambió la forma de\nestudiar. Mis notas mejoraron\nmuchísimo." ⭐⭐⭐⭐⭐',
  ),

  // 12 — Free vs Pro
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_free_vs_pro.png',
    title: 'Gratis vs Pro',
    subtitle: 'Desbloquea todo el poder de Kapsa\ncon el plan Pro. Sin límites,\nsin interrupciones.',
  ),

  // 13 — Paywall
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_paywall.png',
    title: 'Desbloquea tu\npotencial completo',
    subtitle: 'Probá Pro gratis por 7 días.\nCancelá cuando quieras.',
  ),
];

// ─────────────────────────────────────────────────────────────
// Main onboarding screen
// ─────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  // Interactive state for screens 3-5
  int? _selectedArea;
  int? _selectedChallenge;
  double _studyHours = 2.0;

  // Animation controllers per page for entrance animations
  late final List<AnimationController> _entranceControllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  static const _studyAreas = [
    '🔬 Ciencias',
    '📐 Ingeniería',
    '⚖️ Derecho',
    '💊 Medicina',
    '📊 Economía',
    '🎨 Artes',
    '💻 Informática',
    '📚 Otros',
  ];

  static const _challenges = [
    '😵 Me cuesta memorizar',
    '📅 No tengo tiempo',
    '😴 Me aburro estudiando',
    '📝 No sé organizar apuntes',
    '😰 Me estreso en exámenes',
    '🤷 No sé por dónde empezar',
  ];

  @override
  void initState() {
    super.initState();
    _entranceControllers = List.generate(
      _slides.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _fadeAnimations = _entranceControllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.easeOut)
          .drive(Tween<double>(begin: 0.0, end: 1.0));
    }).toList();
    _slideAnimations = _entranceControllers.map((c) {
      return CurvedAnimation(parent: c, curve: AppAnimations.curveEntrance)
          .drive(Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero));
    }).toList();

    // Animate first page immediately
    _entranceControllers[0].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _entranceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      ref.read(hasSeenOnboardingProvider.notifier).state = true;
      context.go(Routes.login);
    }
  }

  void _goToPaywall() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      ref.read(hasSeenOnboardingProvider.notifier).state = true;
      context.go(Routes.paywall);
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: AppAnimations.curveStandard,
      );
    } else {
      // Last slide → go to paywall
      _goToPaywall();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    // Trigger entrance animation for new page
    if (!_entranceControllers[index].isCompleted) {
      _entranceControllers[index].forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;
    final isSecondToLast = _currentPage == _slides.length - 2;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // ── Animated floating background orbs ──
          const Positioned.fill(
            child: FloatingOrbs(orbCount: 3),
          ),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // ── Top bar: progress + skip ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sm, AppSpacing.lg, 0,
                  ),
                  child: Row(
                    children: [
                      // Progress bar
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: AppAnimations.curveStandard,
                            height: 4,
                            child: LinearProgressIndicator(
                              value: (_currentPage + 1) / _slides.length,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Skip button
                      TapScale(
                        onTap: _completeOnboarding,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Saltar',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Page view ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return SlideTransition(
                        position: _slideAnimations[index],
                        child: FadeTransition(
                          opacity: _fadeAnimations[index],
                          child: _buildSlideContent(slide, index),
                        ),
                      );
                    },
                  ),
                ),

                // ── Page indicators ──
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildPageIndicators(),
                ),

                // ── CTA Button ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl,
                  ),
                  child: _buildCTAButton(isLastPage, isSecondToLast),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Slide content builder
  // ─────────────────────────────────────────────────────────────

  Widget _buildSlideContent(_OnboardingSlide slide, int index) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),

            // ── Mascot illustration ──
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: Image.asset(
                slide.image,
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Title ──
            Text(
              slide.title,
              style: AppTypography.h1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Subtitle ──
            Text(
              slide.subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),

            // ── Interactive sections ──
            if (slide.type == _SlideType.selection) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildStudyAreaGrid(),
            ],
            if (slide.type == _SlideType.challenge) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildChallengeList(),
            ],
            if (slide.type == _SlideType.studyTime) ...[
              const SizedBox(height: AppSpacing.xl),
              _buildStudyTimeSlider(),
            ],

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Interactive widgets for screens 3-5
  // ─────────────────────────────────────────────────────────────

  Widget _buildStudyAreaGrid() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: List.generate(_studyAreas.length, (i) {
        final isSelected = _selectedArea == i;
        return TapScale(
          onTap: () => setState(() => _selectedArea = i),
          child: AnimatedContainer(
            duration: AppAnimations.durationFast,
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
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              _studyAreas[i],
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildChallengeList() {
    return Column(
      children: List.generate(_challenges.length, (i) {
        final isSelected = _selectedChallenge == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: TapScale(
            onTap: () => setState(() => _selectedChallenge = i),
            child: AnimatedContainer(
              duration: AppAnimations.durationFast,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.12),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                _challenges[i],
                style: AppTypography.bodyMedium.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStudyTimeSlider() {
    return Column(
      children: [
        Text(
          '${_studyHours.round()} ${_studyHours.round() == 1 ? 'hora' : 'horas'} por día',
          style: AppTypography.h3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
          ),
          child: Slider(
            value: _studyHours,
            min: 0.5,
            max: 8,
            divisions: 15,
            onChanged: (v) => setState(() => _studyHours = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30 min',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted)),
              Text('8 hs',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Page indicators (compact dots for 14 pages)
  // ─────────────────────────────────────────────────────────────

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (i) {
        final isActive = _currentPage == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CTA button
  // ─────────────────────────────────────────────────────────────

  Widget _buildCTAButton(bool isLastPage, bool isSecondToLast) {
    final String buttonText;
    if (isLastPage) {
      buttonText = 'Probar Pro gratis';
    } else if (_currentPage == 0) {
      buttonText = 'Empezar';
    } else {
      buttonText = 'Continuar';
    }

    return Column(
      children: [
        TapScale(
          onTap: _nextPage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
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
                buttonText,
                style: AppTypography.button.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),

        // On paywall slide, show "skip trial" link
        if (isLastPage) ...[
          const SizedBox(height: AppSpacing.sm),
          TapScale(
            onTap: _completeOnboarding,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Continuar sin Pro',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
