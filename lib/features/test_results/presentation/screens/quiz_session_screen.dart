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
import '../../../../core/widgets/tap_scale.dart';
import '../providers/test_provider.dart';
import '../../data/models/test_question_model.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../courses/presentation/providers/course_provider.dart';

/// Full-screen quiz session where users answer AI-generated questions.
///
/// Displays one question at a time with a text input field.
/// After answering all questions, submits to the AI for evaluation
/// and navigates to the results screen.
class QuizSessionScreen extends ConsumerStatefulWidget {
  final String testId;

  const QuizSessionScreen({super.key, required this.testId});

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  final _answerController = TextEditingController();
  final _answerFocusNode = FocusNode();
  bool _isSubmitting = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

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
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextQuestion(List<TestQuestionModel> questions) {
    // Prevent rapid taps during animation
    if (_slideController.isAnimating) return;

    // Save current answer
    final answer = _answerController.text.trim();
    if (answer.isNotEmpty) {
      _answers[_currentIndex] = answer;
    }

    if (_currentIndex < questions.length - 1) {
      // Animate slide out
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
            begin: const Offset(1.2, 0),
            end: Offset.zero,
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

  void _prevQuestion() {
    // Prevent rapid taps during animation
    if (_slideController.isAnimating) return;

    if (_currentIndex > 0) {
      // Save current answer
      final answer = _answerController.text.trim();
      if (answer.isNotEmpty) {
        _answers[_currentIndex] = answer;
      }

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
          _slideAnimation = Tween<Offset>(
            begin: const Offset(-1.2, 0),
            end: Offset.zero,
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

  Future<void> _submitQuiz(List<TestQuestionModel> questions) async {
    // Save current answer
    final answer = _answerController.text.trim();
    if (answer.isNotEmpty) {
      _answers[_currentIndex] = answer;
    }

    // Check that all questions are answered
    final unanswered = <int>[];
    for (int i = 0; i < questions.length; i++) {
      if (_answers[i] == null || _answers[i]!.trim().isEmpty) {
        unanswered.add(i + 1);
      }
    }

    if (unanswered.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            unanswered.length == 1
                ? 'Please answer question ${unanswered.first}'
                : 'Please answer questions ${unanswered.join(", ")}',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
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

      if (!mounted) return;
      // Navigate to results, replacing this screen
      context.pushReplacement(Routes.testResultsPath(result.test.id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppErrorHandler.showError(e, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(quizQuestionsProvider(widget.testId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.darkImmersive),
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
    );
  }

  Widget _buildError(Object error) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Colors.white.withValues(alpha: 0.6)),
              const SizedBox(height: AppSpacing.md),
              Text('Could not load quiz',
                  style: AppTypography.h3.copyWith(color: Colors.white)),
              const SizedBox(height: AppSpacing.sm),
              Text(AppErrorHandler.friendlyMessage(error),
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return SafeArea(
      child: Center(
        child: Text(
          'No questions found',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildQuizSession(List<TestQuestionModel> questions) {
    final total = questions.length;
    final current = _currentIndex + 1;
    final progress = current / total;
    final question = questions[_currentIndex];
    final isLast = _currentIndex == total - 1;
    final hasAnswer = _answerController.text.trim().isNotEmpty;

    return Stack(
      children: [
        // Decorative orb
        Positioned(
          top: -100,
          right: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
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
                    Row(
                      children: [
                        // Close button
                        TapScale(
                          onTap: () => _showExitDialog(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            child: Icon(Icons.close,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 18),
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
                  ],
                ),
              ),

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
                        // Question number badge
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
                            'Question $current',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Question text
                        Text(
                          question.question,
                          style: AppTypography.h2.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Answer input
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
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
                              hintText: 'Type your answer here...',
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.3),
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
                          'Answer in your own words. The AI will evaluate your understanding.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 12,
                          ),
                        ),
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
                          onTap: _prevQuestion,
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
                                    'Previous',
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
                                                .withValues(alpha: 0.4),
                                            blurRadius: 16,
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
                                        isLast ? 'Submit Quiz' : 'Next',
                                        style:
                                            AppTypography.labelLarge.copyWith(
                                          color: hasAnswer
                                              ? Colors.white
                                              : Colors.white
                                                  .withValues(alpha: 0.4),
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
                                                .withValues(alpha: 0.4),
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
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Leave Quiz?',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        content: Text(
          'Your progress will be lost. Are you sure you want to leave?',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Continue Quiz',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Leave',
              style: AppTypography.labelLarge.copyWith(
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
