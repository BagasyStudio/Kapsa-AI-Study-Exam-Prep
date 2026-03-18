import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/math_text.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../providers/test_provider.dart';
import '../../data/models/test_question_model.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../widgets/exam_timer_widget.dart';
import '../widgets/quiz_combo_indicator.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../../gamification/presentation/widgets/xp_popup.dart';
import '../../../../core/constants/xp_config.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../../core/services/review_service.dart';
import '../../../home/presentation/providers/resume_quiz_provider.dart';
import '../../../home/data/models/journey_node_model.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Full-screen quiz session where users answer AI-generated questions.
///
/// Displays one question at a time with a text input field.
/// After answering all questions, submits to the AI for evaluation
/// and navigates to the results screen.
///
/// Auto-saves progress as the user navigates between questions.
/// If the user exits, they can resume from the home screen banner.
///
/// Supports optional [timeLimitMinutes] for practice exam mode.
class QuizSessionScreen extends ConsumerStatefulWidget {
  final String testId;
  final int? timeLimitMinutes;
  final bool isPracticeExam;

  /// Exam mode string from the practice exam setup (e.g. "standard", "review", "challenge").
  /// Stored as a nullable String so the quiz session can adapt its behaviour.
  final String? examMode;

  const QuizSessionScreen({
    super.key,
    required this.testId,
    this.timeLimitMinutes,
    this.isPracticeExam = false,
    this.examMode,
  });

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  final _answerController = TextEditingController();
  final _answerFocusNode = FocusNode();
  bool _isSubmitting = false;
  bool _hasLoadedSavedAnswers = false;
  List<TestQuestionModel>? _questions; // cached for exit dialog
  int _comboCount = 0; // consecutive answered questions streak
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // ── Instant feedback overlay ──
  late AnimationController _feedbackController;
  late Animation<double> _feedbackScaleAnimation;
  bool _showFeedbackOverlay = false;
  bool _lastAnswerCorrect = false;

  // ── Hint system ──
  final Set<int> _hintsUsed = {}; // question indices where hint was used

  // ── UX-18: Session timer ──
  final Stopwatch _sessionStopwatch = Stopwatch();

  // ── #70: Session stats ticker ──
  Timer? _statsTimer;
  Duration _displayedElapsed = Duration.zero;

  // ── #69: Smart answer validation ──
  String? _fuzzyHintText;
  Timer? _fuzzyHintTimer;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    ));

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _feedbackScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _feedbackController,
        curve: Curves.elasticOut,
      ),
    );

    // #70: Tick every second to update session stats display
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionStopwatch.isRunning && mounted) {
        setState(() {
          _displayedElapsed = _sessionStopwatch.elapsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _fuzzyHintTimer?.cancel();
    _answerController.dispose();
    _answerFocusNode.dispose();
    _slideController.dispose();
    _feedbackController.dispose();
    _sessionStopwatch.stop();
    super.dispose();
  }

  // ── Resume from saved progress ──────────────────────────────────────

  /// Load saved answers from the database (runs once).
  void _initFromSavedProgress(List<TestQuestionModel> questions) {
    if (_hasLoadedSavedAnswers) return;
    _hasLoadedSavedAnswers = true;

    bool hasSavedProgress = false;
    for (final q in questions) {
      if (q.userAnswer != null && q.userAnswer!.isNotEmpty) {
        _answers[q.questionNumber - 1] = q.userAnswer!;
        hasSavedProgress = true;
      }
    }

    if (hasSavedProgress) {
      // Jump to first unanswered question
      int firstUnanswered = questions.length - 1;
      for (int i = 0; i < questions.length; i++) {
        if (!_answers.containsKey(i)) {
          firstUnanswered = i;
          break;
        }
      }

      // Initialize combo from saved streak (count consecutive from start)
      int savedCombo = 0;
      for (int i = 0; i < questions.length; i++) {
        if (_answers.containsKey(i)) {
          savedCombo++;
        } else {
          break;
        }
      }
      _comboCount = savedCombo;

      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = firstUnanswered;
          _answerController.text = _answers[_currentIndex] ?? '';
        });
      });
    }
  }

  // ── Auto-save ───────────────────────────────────────────────────────

  /// Save a single answer to the database (fire-and-forget).
  void _autoSaveAnswer(List<TestQuestionModel> questions, int index) {
    final answer = _answers[index];
    if (answer == null || answer.isEmpty) return;
    if (index >= questions.length) return;

    final question = questions[index];
    ref.read(testRepositoryProvider).saveQuestionAnswer(
      testId: widget.testId,
      questionId: question.id,
      answer: answer,
      currentIndex: _currentIndex,
    ).catchError((_) {/* fire-and-forget, best-effort */});
  }

  // ── Instant feedback ────────────────────────────────────────────────

  /// Show a brief correct/incorrect overlay, then proceed with [onComplete].
  void _showAnswerFeedback(TestQuestionModel question, String userAnswer, VoidCallback onComplete) {
    final isCorrect = userAnswer.trim().toLowerCase() == question.correctAnswer.trim().toLowerCase();
    setState(() {
      _lastAnswerCorrect = isCorrect;
      _showFeedbackOverlay = true;
    });

    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    _feedbackController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _showFeedbackOverlay = false);
      _feedbackController.reset();
      onComplete();
    });
  }

  // ── Hint helpers ───────────────────────────────────────────────────

  /// Derive a progressive hint from the correct answer.
  String _deriveHint(String correctAnswer) {
    final trimmed = correctAnswer.trim();
    if (trimmed.isEmpty) return 'No hint available';
    final firstChar = trimmed[0].toUpperCase();
    final length = trimmed.length;
    return "Starts with '$firstChar', $length letters";
  }

  // ── #69: Smart answer validation ────────────────────────────────────

  /// Simple string similarity: ratio of matching characters to max length.
  /// Compares lowercase trimmed strings character-by-character.
  double _stringSimilarity(String a, String b) {
    final s1 = a.trim().toLowerCase();
    final s2 = b.trim().toLowerCase();
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;

    final maxLen = s1.length > s2.length ? s1.length : s2.length;
    final minLen = s1.length < s2.length ? s1.length : s2.length;
    int matches = 0;
    for (int i = 0; i < minLen; i++) {
      if (s1[i] == s2[i]) matches++;
    }
    return matches / maxLen;
  }

  /// Check the user's answer against the correct answer.
  /// If similarity is >70% but not exact, show a fuzzy hint.
  void _checkFuzzyHint(TestQuestionModel question, String userAnswer) {
    _dismissFuzzyHint();

    final trimmedUser = userAnswer.trim().toLowerCase();
    final trimmedCorrect = question.correctAnswer.trim().toLowerCase();

    if (trimmedUser.isEmpty || trimmedUser == trimmedCorrect) return;

    final similarity = _stringSimilarity(trimmedUser, trimmedCorrect);
    if (similarity > 0.70) {
      setState(() {
        _fuzzyHintText = 'Did you mean "${question.correctAnswer.trim()}"?';
      });

      // Auto-dismiss after 3 seconds
      _fuzzyHintTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) _dismissFuzzyHint();
      });
    }
  }

  /// Dismiss the fuzzy hint and cancel its timer.
  void _dismissFuzzyHint() {
    _fuzzyHintTimer?.cancel();
    _fuzzyHintTimer = null;
    if (_fuzzyHintText != null && mounted) {
      setState(() => _fuzzyHintText = null);
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────

  void _nextQuestion(List<TestQuestionModel> questions) {
    // Prevent rapid taps during animation or feedback
    if (_slideController.isAnimating || _showFeedbackOverlay) return;

    // #69: Dismiss any existing fuzzy hint
    _dismissFuzzyHint();

    // Save current answer
    final answer = _answerController.text.trim();
    if (answer.isNotEmpty) {
      _answers[_currentIndex] = answer;
      // Increment combo -- answered this question
      _comboCount++;
    } else {
      // Skipped a question -> reset combo
      _comboCount = 0;
    }
    // Auto-save to DB
    _autoSaveAnswer(questions, _currentIndex);

    final question = questions[_currentIndex];

    // #69: Check fuzzy hint for text input answers
    if (answer.isNotEmpty) {
      _checkFuzzyHint(question, answer);
    }

    // Slide-to-next logic extracted so feedback can call it
    void proceedToNext() {
      if (_currentIndex < questions.length - 1) {
        setState(() {
          _slideAnimation = Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-1.2, 0),
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeInOutCubic,
          ));
        });
        _slideController.forward().then((_) {
          if (!mounted) return;
          setState(() {
            _currentIndex++;
            _answerController.text = _answers[_currentIndex] ?? '';
            _slideAnimation = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(1.2, 0),
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeInOutCubic,
            ));
          });
          _slideController.reverse();
          if (_answerFocusNode.canRequestFocus) {
            _answerFocusNode.requestFocus();
          }
        });
        SoundService.playFlashcardFlip();
      }
    }

    // Show instant feedback if user answered, then proceed
    if (answer.isNotEmpty) {
      _showAnswerFeedback(question, answer, proceedToNext);
    } else {
      HapticFeedback.selectionClick();
      proceedToNext();
    }
  }

  void _prevQuestion(List<TestQuestionModel> questions) {
    // Prevent rapid taps during animation
    if (_slideController.isAnimating) return;

    // #69: Dismiss fuzzy hint when navigating away
    _dismissFuzzyHint();

    if (_currentIndex > 0) {
      // Save current answer
      final answer = _answerController.text.trim();
      if (answer.isNotEmpty) {
        _answers[_currentIndex] = answer;
      }
      // Auto-save to DB
      _autoSaveAnswer(questions, _currentIndex);
      HapticFeedback.selectionClick();

      setState(() {
        _slideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(1.2, 0),
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Curves.easeInOutCubic,
        ));
      });
      _slideController.forward().then((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex--;
          _answerController.text = _answers[_currentIndex] ?? '';
          // reverse() goes 1.0→0.0, so begin=Offset.zero is the FINAL position
          _slideAnimation = Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-1.2, 0),
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeInOutCubic,
          ));
        });
        _slideController.reverse();
        if (_answerFocusNode.canRequestFocus) {
          _answerFocusNode.requestFocus();
        }
      });
      SoundService.playFlashcardFlip();
    }
  }

  Future<void> _submitQuiz(List<TestQuestionModel> questions, {bool force = false}) async {
    if (_isSubmitting) return;

    // Save current answer
    final answer = _answerController.text.trim();
    if (answer.isNotEmpty) {
      _answers[_currentIndex] = answer;
    }

    // For forced submissions (time up), fill unanswered with placeholder
    if (force) {
      for (int i = 0; i < questions.length; i++) {
        _answers.putIfAbsent(i, () => '(no answer)');
        if (_answers[i]!.trim().isEmpty) _answers[i] = '(no answer)';
      }
    }

    // Check that all questions are answered
    final unanswered = <int>[];
    for (int i = 0; i < questions.length; i++) {
      if (_answers[i] == null || _answers[i]!.trim().isEmpty) {
        unanswered.add(i + 1);
      }
    }

    if (unanswered.isNotEmpty && !force) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            unanswered.length == 1
                ? l.quizAnswerQuestion(unanswered.first.toString())
                : l.quizAnswerQuestions(unanswered.join(", ")),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
    _sessionStopwatch.stop(); // UX-18: Stop session timer

    try {
      // Mark as completed before evaluation
      await ref.read(testRepositoryProvider).markTestCompleted(widget.testId);

      // Build answers list
      final answersList = questions.map((q) {
        return {
          'questionId': q.id,
          'answer': _answers[q.questionNumber - 1] ?? '',
        };
      }).toList();

      final result = await ref
          .read(testRepositoryProvider)
          .submitAnswers(
            testId: widget.testId,
            answers: answersList,
          );

      // Recalculate course progress in background
      ref
          .read(courseRepositoryProvider)
          .recalculateProgress(result.test.courseId)
          .then((_) => ref.invalidate(coursesProvider))
          .catchError((_) {/* best-effort */});

      // Award XP for quiz completion
      _awardQuizXp(result.test.score);

      // Remove from home screen banner
      ref.invalidate(inProgressQuizzesProvider);

      if (!mounted) return;

      // Show celebration for perfect score
      final l = AppLocalizations.of(context)!;
      if ((result.test.score ?? 0) >= 100) {
        CelebrationOverlay.show(
          context,
          title: l.quizPerfectScore,
          subtitle: l.quizPerfectSub,
          icon: Icons.emoji_events,
          color: const Color(0xFFF59E0B),
        );
        await Future.delayed(const Duration(milliseconds: 1500));
      }

      if (!mounted) return;
      // Trigger in-app review at strategic moments
      ReviewService.recordPositiveEvent();
      // Navigate to results, then pop back with completion signal for journey
      await context.push(Routes.testResultsPath(result.test.id));
      if (mounted) Navigator.of(context).pop(JourneyResult.completed);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppErrorHandler.showError(e, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(quizQuestionsProvider(widget.testId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmExit();
        if (shouldLeave && context.mounted) Navigator.of(context).pop(JourneyResult.cancelled);
      },
      child: Scaffold(
      backgroundColor: AppColors.immersiveBg,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.darkImmersive,
        ),
        child: questionsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => _buildError(e),
          data: (questions) {
            if (questions.isEmpty) return _buildEmpty();
            return _buildQuizSession(questions);
          },
        ),
      ),
    ),
    );
  }

  Future<bool> _confirmExit() async {
    if (_isSubmitting) return false; // Don't leave while submitting

    // Save current answer before showing dialog
    final answer = _answerController.text.trim();
    if (answer.isNotEmpty) {
      _answers[_currentIndex] = answer;
      if (_questions != null) {
        _autoSaveAnswer(_questions!, _currentIndex);
      }
    }

    final l = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.immersiveCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          l.quizLeaveTitle,
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        content: Text(
          l.quizLeaveSaved,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l.quizStay,
              style: AppTypography.labelLarge.copyWith(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l.quizLeaveForNow,
              style: AppTypography.labelLarge.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildError(Object error) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.md),
              Text(l.quizCouldNotLoad,
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                  )),
              const SizedBox(height: AppSpacing.sm),
              Text(AppErrorHandler.friendlyMessage(error),
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: () => Navigator.of(context).pop(JourneyResult.cancelled),
                child: Text(l.quizGoBack,
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: Center(
        child: Text(
          l.quizNoQuestions,
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildQuizSession(List<TestQuestionModel> questions) {
    // Cache questions ref for exit dialog & resume detection
    _questions = questions;
    _initFromSavedProgress(questions);

    // ── UX-18: Start session timer on first build ──
    if (!_sessionStopwatch.isRunning) _sessionStopwatch.start();

    final l = AppLocalizations.of(context)!;
    final total = questions.length;
    final current = _currentIndex + 1;
    final progress = current / total;
    final question = questions[_currentIndex];
    final isLast = _currentIndex == total - 1;
    final hasAnswer = _answerController.text.trim().isNotEmpty;

    return Stack(
      children: [
        // Decorative orb — kept small to avoid overlap on short devices
        Positioned(
          top: -80,
          right: -50,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          left: -60,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
            ),
          ),
        ),

        // Main content
        SafeArea(
          child: Column(
            children: [
              // Header: progress + close
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0,
                ),
                child: Column(
                  children: [
                    // ── UX-18: Focus mode indicator ──
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Focus Mode',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        // Close button
                        TapScale(
                          onTap: () => _showExitDialog(questions),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            child: Icon(Icons.close,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 20),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Progress bar
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '$current/$total',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Timer for practice exams
                    if (widget.timeLimitMinutes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: ExamTimerWidget(
                          totalMinutes: widget.timeLimitMinutes!,
                          onTimeUp: () => _submitQuiz(questions, force: true),
                        ),
                      ),
                  ],
                ),
              ),

              // Combo streak indicator
              if (_comboCount >= 2)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: QuizComboIndicator(count: _comboCount),
                ),

              // #70: Session stats row (shown after first question is answered)
              if (_answers.isNotEmpty)
                _buildSessionStats(total),

              // Question area
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question number badge + difficulty badge (#67)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6467F2),
                                    Color(0xFF8B5CF6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                l.quizQuestion('$current'),
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _DifficultyBadge(
                              correctAnswer: question.correctAnswer,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Question text
                        MathText(
                          text: question.question,
                          style: AppTypography.h2.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Answer input
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: TextField(
                            controller: _answerController,
                            focusNode: _answerFocusNode,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            maxLines: 5,
                            minLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: l.quizTypeAnswer,
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.50),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(AppSpacing.lg),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Hint text
                        Text(
                          l.quizAnswerHint,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Hint button
                        _buildHintButton(question),

                        // #69: Smart answer validation hint
                        if (_fuzzyHintText != null)
                          _buildFuzzyHint(),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom navigation buttons
              Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  MediaQuery.of(context).padding.bottom + AppSpacing.md,
                ),
                child: Row(
                  children: [
                    // Previous button
                    if (_currentIndex > 0)
                      Expanded(
                        child: TapScale(
                          onTap: () => _prevQuestion(questions),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back,
                                      size: 18,
                                      color: Colors.white.withValues(alpha: 0.7)),
                                  const SizedBox(width: 6),
                                  Text(
                                    l.quizPrevious,
                                    style: AppTypography.labelLarge.copyWith(
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (_currentIndex > 0) const SizedBox(width: AppSpacing.md),

                    // Skip button (only when not last question and no answer typed)
                    if (!isLast && !hasAnswer) ...[
                      TextButton(
                        onPressed: () {
                          if (_slideController.isAnimating) return;
                          _comboCount = 0; // Reset combo on skip
                          HapticFeedback.selectionClick();
                          // Navigate to next without saving
                          if (_currentIndex < questions.length - 1) {
                            setState(() {
                              _slideAnimation = Tween<Offset>(
                                begin: Offset.zero,
                                end: const Offset(-1.2, 0),
                              ).animate(CurvedAnimation(
                                parent: _slideController,
                                curve: Curves.easeInOutCubic,
                              ));
                            });
                            _slideController.forward().then((_) {
                              if (!mounted) return;
                              setState(() {
                                _currentIndex++;
                                _answerController.text = _answers[_currentIndex] ?? '';
                                _slideAnimation = Tween<Offset>(
                                  begin: Offset.zero,
                                  end: const Offset(1.2, 0),
                                ).animate(CurvedAnimation(
                                  parent: _slideController,
                                  curve: Curves.easeInOutCubic,
                                ));
                              });
                              _slideController.reverse();
                              if (_answerFocusNode.canRequestFocus) {
                                _answerFocusNode.requestFocus();
                              }
                            });
                            SoundService.playFlashcardFlip();
                          }
                        },
                        child: Text(
                          'Skip',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],

                    // Next / Submit button
                    Expanded(
                      flex: _currentIndex > 0 ? 1 : 1,
                      child: _isSubmitting
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6467F2),
                                    Color(0xFF8B5CF6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : TapScale(
                              onTap: () {
                                if (isLast) {
                                  _submitQuiz(questions);
                                } else {
                                  _nextQuestion(questions);
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: hasAnswer
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF6467F2),
                                            Color(0xFF8B5CF6),
                                          ],
                                        )
                                      : null,
                                  color: hasAnswer
                                      ? null
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: hasAnswer
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isLast
                                            ? (widget.isPracticeExam
                                                ? l.quizSubmitExam
                                                : l.quizSubmitQuiz)
                                            : l.quizNext,
                                        style:
                                            AppTypography.labelLarge.copyWith(
                                          color: hasAnswer
                                              ? Colors.white
                                              : Colors.white
                                                  .withValues(alpha: 0.6),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        isLast
                                            ? Icons.check_circle
                                            : Icons.arrow_forward,
                                        size: 18,
                                        color: hasAnswer
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Instant feedback overlay (on top of everything)
        _buildFeedbackOverlay(),
      ],
    );
  }

  // ── #70: Session stats row ─────────────────────────────────────────

  Widget _buildSessionStats(int totalQuestions) {
    final elapsed = _displayedElapsed;
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final answeredCount = _answers.length;
    final totalSeconds = elapsed.inSeconds;

    // Average pace: total time / questions answered
    final avgPaceSeconds = answeredCount > 0
        ? totalSeconds / answeredCount
        : 0.0;
    final avgPaceMinutes = avgPaceSeconds / 60.0;
    final paceStr = avgPaceMinutes < 0.1
        ? '<0.1 min/Q'
        : '~${avgPaceMinutes.toStringAsFixed(1)} min/Q';

    // Estimated remaining: pace * remaining questions
    final remaining = totalQuestions - answeredCount;
    final estRemainingSeconds = (avgPaceSeconds * remaining).round();
    final estRemainingMinutes = (estRemainingSeconds / 60.0).ceil();
    final estStr = answeredCount > 0
        ? (estRemainingMinutes <= 0
            ? 'almost done'
            : '~$estRemainingMinutes min left')
        : '--';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _statChip(Icons.timer_outlined, timeStr),
          const SizedBox(width: AppSpacing.md),
          _statChip(Icons.speed, paceStr),
          const SizedBox(width: AppSpacing.md),
          _statChip(Icons.hourglass_bottom, estStr),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ── Hint button widget ──────────────────────────────────────────────

  Widget _buildHintButton(TestQuestionModel question) {
    final hintUsed = _hintsUsed.contains(_currentIndex);
    if (hintUsed) {
      // Already used hint — show hint text
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('\u{1F4A1}', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                'Hint used',
                style: AppTypography.caption.copyWith(
                  color: Colors.white38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _deriveHint(question.correctAnswer),
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white60,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _hintsUsed.add(_currentIndex);
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{1F4A1}', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            'Hint',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── #69: Fuzzy hint widget ─────────────────────────────────────────

  Widget _buildFuzzyHint() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 14,
              color: AppColors.warning.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _fuzzyHintText!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warning.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Feedback overlay widget ────────────────────────────────────────

  Widget _buildFeedbackOverlay() {
    if (!_showFeedbackOverlay) return const SizedBox.shrink();

    final isCorrect = _lastAnswerCorrect;
    final color = isCorrect
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final label = isCorrect ? 'Correct!' : 'Incorrect';

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: color.withValues(alpha: 0.15),
          child: Center(
            child: ScaleTransition(
              scale: _feedbackScaleAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: AppTypography.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _awardQuizXp(double? score) {
    final xpRepo = ref.read(xpRepositoryProvider);
    final scorePercent = score ?? 0;
    final baseXp = XpConfig.quizComplete;
    final bonus = XpConfig.quizScoreBonus(scorePercent);
    final totalXp = baseXp + bonus;

    xpRepo
        .awardXp(
          action: 'quiz_complete',
          amount: totalXp,
          metadata: {'test_id': widget.testId, 'score': scorePercent},
        )
        .then((_) => ref.invalidate(xpTotalProvider))
        .catchError((_) {/* silent */});

    // Bonus for perfect score
    if (scorePercent >= 100) {
      xpRepo
          .awardXp(
            action: 'perfect_quiz',
            amount: XpConfig.perfectQuiz,
            metadata: {'test_id': widget.testId},
          )
          .then((_) => ref.invalidate(xpTotalProvider))
          .catchError((_) {/* silent */});
    }

    if (mounted) {
      final l = AppLocalizations.of(context)!;
      final displayXp = scorePercent >= 100
          ? totalXp + XpConfig.perfectQuiz
          : totalXp;
      XpPopup.show(
        context,
        xp: displayXp,
        label: scorePercent >= 100 ? l.quizPerfect : l.quizComplete,
      );
    }
  }

  void _showExitDialog(List<TestQuestionModel> questions) {
    // Save current answer before showing dialog
    final answer = _answerController.text.trim();
    if (answer.isNotEmpty) {
      _answers[_currentIndex] = answer;
      _autoSaveAnswer(questions, _currentIndex);
    }

    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.immersiveCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          widget.isPracticeExam ? l.quizLeaveExamTitle : l.quizLeaveTitle,
          style: AppTypography.h3.copyWith(
            color: Colors.white,
          ),
        ),
        content: Text(
          l.quizLeaveSaved,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white60,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l.quizContinueQuiz,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(JourneyResult.cancelled);
            },
            child: Text(
              l.quizLeaveForNow,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// #67: Difficulty Badge per Question
// ═══════════════════════════════════════════════════════════════════════

/// Pill badge that estimates question difficulty from the answer length/complexity.
///
/// - Short answer (<20 chars): Easy (green)
/// - Medium answer (20-60 chars): Medium (amber)
/// - Long answer (>60 chars): Hard (red)
class _DifficultyBadge extends StatelessWidget {
  final String correctAnswer;

  const _DifficultyBadge({required this.correctAnswer});

  @override
  Widget build(BuildContext context) {
    final trimmed = correctAnswer.trim();
    final length = trimmed.length;

    final String label;
    final Color color;

    if (length < 20) {
      label = 'Easy';
      color = const Color(0xFF22C55E); // green
    } else if (length <= 60) {
      label = 'Medium';
      color = const Color(0xFFF59E0B); // amber
    } else {
      label = 'Hard';
      color = const Color(0xFFEF4444); // red
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
