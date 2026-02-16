import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/floating_orbs.dart';
import '../../../../core/widgets/pulse_glow.dart';
import '../widgets/onboarding_welcome_page.dart';
import '../widgets/onboarding_study_area_page.dart';
import '../widgets/onboarding_challenge_page.dart';
import '../widgets/onboarding_study_time_page.dart';
import '../widgets/onboarding_plan_ready_page.dart';
import '../widgets/onboarding_features_page.dart';
import '../widgets/onboarding_social_proof_page.dart';
import '../widgets/onboarding_paywall_page.dart';

// ─────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────

const _totalPages = 8;

const _studyAreas = [
  'Sciences',
  'Engineering',
  'Law',
  'Medicine',
  'Economics',
  'Arts',
  'Computer Science',
  'Other',
];

const _challenges = [
  'Memorizing',
  'Time management',
  'Staying focused',
  'Organizing notes',
  'Exam stress',
  'Getting started',
];

// ─────────────────────────────────────────────────────────────
// Main onboarding orchestrator
// ─────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // User selections
  int? _selectedArea;
  int? _selectedChallenge;
  int? _selectedTimeIndex;
  String _studyTimeLabel = '2 hours';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Navigation ──

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
    if (_currentPage < _totalPages - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final isPaywallPage = _currentPage == _totalPages - 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background orbs (hidden on dark paywall page)
          if (!isPaywallPage)
            const Positioned.fill(
              child: FloatingOrbs(orbCount: 3),
            ),
          // Dark gradient background for paywall page
          if (isPaywallPage)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B0D1E),
                      Color(0xFF111338),
                      Color(0xFF0F1029),
                      Color(0xFF0B0D1E),
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar: progress + skip
                if (!isPaywallPage)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: AppAnimations.curveStandard,
                        height: 4,
                        child: LinearProgressIndicator(
                          value: (_currentPage + 1) / _totalPages,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    children: [
                      // 0 — Welcome
                      OnboardingWelcomePage(
                        isActive: _currentPage == 0,
                      ),

                      // 1 — Study Area
                      OnboardingStudyAreaPage(
                        isActive: _currentPage == 1,
                        selectedArea: _selectedArea,
                        onSelect: (i) =>
                            setState(() => _selectedArea = i),
                      ),

                      // 2 — Challenge
                      OnboardingChallengePage(
                        isActive: _currentPage == 2,
                        selectedChallenge: _selectedChallenge,
                        onSelect: (i) =>
                            setState(() => _selectedChallenge = i),
                      ),

                      // 3 — Study Time
                      OnboardingStudyTimePage(
                        isActive: _currentPage == 3,
                        selectedIndex: _selectedTimeIndex,
                        onSelect: (index, hours, label) => setState(() {
                          _selectedTimeIndex = index;
                          _studyTimeLabel = label;
                        }),
                      ),

                      // 4 — Plan Ready
                      OnboardingPlanReadyPage(
                        isActive: _currentPage == 4,
                        studyArea: _selectedArea != null
                            ? _studyAreas[_selectedArea!]
                            : null,
                        challenge: _selectedChallenge != null
                            ? _challenges[_selectedChallenge!]
                            : null,
                        studyTime: _studyTimeLabel,
                      ),

                      // 5 — Features
                      OnboardingFeaturesPage(
                        isActive: _currentPage == 5,
                      ),

                      // 6 — Social Proof
                      OnboardingSocialProofPage(
                        isActive: _currentPage == 6,
                      ),

                      // 7 — Paywall
                      OnboardingPaywallPage(
                        isActive: _currentPage == 7,
                        onTryPro: _goToPaywall,
                        onSkip: _completeOnboarding,
                      ),
                    ],
                  ),
                ),

                // Page indicators + CTA (hidden on paywall page which has its own)
                if (!isPaywallPage) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildPageIndicators(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl,
                    ),
                    child: _buildCTAButton(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Page indicators ──

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (i) {
        final isActive = _currentPage == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: isActive ? 24 : 6,
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

  // ── CTA button ──

  Widget _buildCTAButton() {
    final String buttonText;
    final bool showPulse;

    switch (_currentPage) {
      case 0:
        buttonText = 'Get Started';
        showPulse = true;
      case 6:
        buttonText = 'Almost There';
        showPulse = false;
      default:
        buttonText = 'Continue';
        showPulse = false;
    }

    final button = TapScale(
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
    );

    return showPulse ? PulseGlow(child: button) : button;
  }
}
