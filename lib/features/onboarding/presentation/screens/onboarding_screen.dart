import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../widgets/onboarding_exam_urgency_page.dart';
import '../widgets/onboarding_study_area_page.dart';
import '../widgets/onboarding_challenge_page.dart';
import '../widgets/onboarding_study_time_page.dart';
import '../widgets/onboarding_upload_material_page.dart';
import '../widgets/onboarding_processing_page.dart';
import '../widgets/onboarding_social_proof_page.dart';
import '../widgets/onboarding_plan_ready_page.dart';
import '../widgets/onboarding_rate_page.dart';

// ─────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────

const _totalPages = 10;

List<String> _localizedStudyAreas(AppLocalizations l) => [
  l.studyAreaSciences,
  l.studyAreaEngineering,
  l.studyAreaLaw,
  l.studyAreaMedicine,
  l.studyAreaEconomics,
  l.studyAreaArts,
  l.studyAreaCS,
  l.studyAreaOther,
];

List<String> _localizedChallenges(AppLocalizations l) => [
  l.challengeMemorizing,
  l.challengeTime,
  l.challengeBored,
  l.challengeNotes,
  l.challengeExams,
  l.challengeStart,
];

// Page indices
const _pageWelcome = 0;
const _pageExamUrgency = 1;
const _pageStudyArea = 2;
const _pageChallenge = 3;
const _pageStudyTime = 4;
const _pageUploadMaterial = 5;
const _pageProcessing = 6;
const _pageSocialProof = 7;
const _pagePlanReady = 8;
const _pageRateUs = 9;

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
  int? _selectedExamUrgency;
  int? _selectedArea;
  int? _selectedChallenge;
  int? _selectedTimeIndex;
  String _studyTimeLabel = '2 hours';

  // Material upload
  String? _materialPath;
  String? _materialType;
  int _estimatedFlashcards = 0;
  int _estimatedQuizzes = 0;
  bool get _materialUploaded => _materialPath != null;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Can continue (disabled button logic) ──

  bool get _canContinue {
    switch (_currentPage) {
      case _pageExamUrgency:
        return _selectedExamUrgency != null;
      case _pageStudyArea:
        return _selectedArea != null;
      case _pageChallenge:
        return _selectedChallenge != null;
      case _pageStudyTime:
        return _selectedTimeIndex != null;
      default:
        return true;
    }
  }

  // ── Navigation ──

  /// Persist onboarding selections to SharedPreferences.
  Future<void> _saveOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    await prefs.setInt(
        'onboarding_exam_urgency', _selectedExamUrgency ?? -1);
    if (_materialPath != null) {
      await prefs.setString('onboarding_material_path', _materialPath!);
      await prefs.setString('onboarding_material_type', _materialType!);
      await prefs.setInt(
          'onboarding_flashcard_count', _estimatedFlashcards);
      await prefs.setInt('onboarding_quiz_count', _estimatedQuizzes);
    }
  }

  /// After rate page → navigate directly to the REAL paywall.
  /// RevenueCat works anonymously — no login needed to purchase.
  /// After paywall (dismiss or purchase) → user lands on /login.
  Future<void> _goToPaywall() async {
    await _saveOnboardingData();
    if (mounted) {
      // Navigate FIRST, then mark as seen.
      // Setting the provider triggers a GoRouter rebuild — if we do it
      // before navigating, the redirect fires while still on /onboarding
      // and sends the user to /login, swallowing the paywall route.
      context.go(Routes.paywall);
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      HapticFeedback.mediumImpact();
      _goToPage(_currentPage + 1);
    }
  }

  void _handleMaterialPicked(String path, String type, int fileSize) {
    setState(() {
      _materialPath = path;
      _materialType = type;
      // Estimate counts based on file type and size
      if (type == 'pdf') {
        _estimatedFlashcards = (fileSize / 50000).round().clamp(5, 50);
        _estimatedQuizzes = (fileSize / 80000).round().clamp(3, 30);
      } else {
        // Camera/OCR — fixed estimates
        _estimatedFlashcards = 8;
        _estimatedQuizzes = 5;
      }
    });
    _nextPage(); // Go to Processing page
  }

  void _handleMaterialSkip() {
    // Skip Processing page, go directly to Social Proof
    _goToPage(_pageSocialProof);
  }

  void _handleProcessingComplete() {
    _nextPage(); // Go to Social Proof
  }

  Future<void> _handleRate() async {
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      }
    } catch (_) {
      // Silently fail — store review may not be available
    }
    // After rating → go to real paywall (last step before login)
    _goToPaywall();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final isRatePage = _currentPage == _pageRateUs;
    final hideBottomBar = isRatePage;
    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: Stack(
        children: [
          // Background orbs
          const Positioned.fill(
            child: FloatingOrbs(orbCount: 3),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar: progress (always in tree to prevent layout thrashing)
                IgnorePointer(
                  ignoring: hideBottomBar,
                  child: AnimatedOpacity(
                    opacity: hideBottomBar ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
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
                        isActive: _currentPage == _pageWelcome,
                      ),

                      // 1 — Exam Urgency
                      OnboardingExamUrgencyPage(
                        isActive: _currentPage == _pageExamUrgency,
                        selectedUrgency: _selectedExamUrgency,
                        onSelect: (i) =>
                            setState(() => _selectedExamUrgency = i),
                      ),

                      // 2 — Study Area
                      OnboardingStudyAreaPage(
                        isActive: _currentPage == _pageStudyArea,
                        selectedArea: _selectedArea,
                        onSelect: (i) =>
                            setState(() => _selectedArea = i),
                      ),

                      // 3 — Challenge
                      OnboardingChallengePage(
                        isActive: _currentPage == _pageChallenge,
                        selectedChallenge: _selectedChallenge,
                        onSelect: (i) =>
                            setState(() => _selectedChallenge = i),
                      ),

                      // 4 — Study Time
                      OnboardingStudyTimePage(
                        isActive: _currentPage == _pageStudyTime,
                        selectedIndex: _selectedTimeIndex,
                        onSelect: (index, hours, label) => setState(() {
                          _selectedTimeIndex = index;
                          _studyTimeLabel = label;
                        }),
                      ),

                      // 5 — Upload Material
                      OnboardingUploadMaterialPage(
                        isActive: _currentPage == _pageUploadMaterial,
                        onMaterialPicked: _handleMaterialPicked,
                        onSkip: _handleMaterialSkip,
                      ),

                      // 6 — Processing (conditional — only meaningful if material uploaded)
                      OnboardingProcessingPage(
                        isActive: _currentPage == _pageProcessing,
                        estimatedFlashcards: _estimatedFlashcards,
                        estimatedQuizzes: _estimatedQuizzes,
                        onComplete: _handleProcessingComplete,
                      ),

                      // 7 — Social Proof
                      OnboardingSocialProofPage(
                        isActive: _currentPage == _pageSocialProof,
                        materialUploaded: _materialUploaded,
                        flashcardCount: _estimatedFlashcards,
                      ),

                      // 8 — Plan Ready
                      OnboardingPlanReadyPage(
                        isActive: _currentPage == _pagePlanReady,
                        studyArea: _selectedArea != null
                            ? _localizedStudyAreas(AppLocalizations.of(context)!)[_selectedArea!]
                            : null,
                        challenge: _selectedChallenge != null
                            ? _localizedChallenges(AppLocalizations.of(context)!)[_selectedChallenge!]
                            : null,
                        studyTime: _studyTimeLabel,
                        examUrgency: _selectedExamUrgency,
                        materialUploaded: _materialUploaded,
                        flashcardCount: _estimatedFlashcards,
                        quizCount: _estimatedQuizzes,
                      ),

                      // 9 — Rate Us (last page — after rate → real paywall)
                      OnboardingRatePage(
                        isActive: _currentPage == _pageRateUs,
                        onRate: _handleRate,
                        onSkip: _goToPaywall,
                      ),
                    ],
                  ),
                ),

                // CTA (always in tree to prevent layout thrashing)
                IgnorePointer(
                  ignoring: hideBottomBar,
                  child: AnimatedOpacity(
                    opacity: hideBottomBar ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl,
                      ),
                      child: _buildCTAButton(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CTA button ──

  Widget _buildCTAButton() {
    final l = AppLocalizations.of(context)!;
    final String buttonText;
    final bool showPulse;

    switch (_currentPage) {
      case _pageWelcome:
        buttonText = l.onboardingGetStarted;
        showPulse = true;
      case _pageSocialProof:
        buttonText = l.onboardingAlmostThere;
        showPulse = false;
      case _pagePlanReady:
        buttonText = l.onboardingStartStudying;
        showPulse = true;
      default:
        buttonText = l.commonContinue;
        showPulse = false;
    }

    final button = AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _canContinue ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !_canContinue,
        child: TapScale(
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
      ),
    );

    return showPulse && _canContinue ? PulseGlow(child: button) : button;
  }
}
