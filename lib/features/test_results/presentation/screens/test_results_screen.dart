import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/confetti_overlay.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../../core/widgets/floating_orbs.dart';
import '../widgets/score_ring.dart';
import '../widgets/correction_card.dart';
import '../widgets/collapsed_correction_card.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/constants/xp_config.dart';
import '../../../../core/providers/generation_provider.dart';
import '../providers/test_provider.dart';
import '../../data/test_repository.dart';
import '../../data/models/test_model.dart';
import '../../data/models/test_question_model.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../../sharing/presentation/widgets/share_preview_sheet.dart';
import '../../../sharing/presentation/widgets/quiz_share_card.dart';
import '../../../sharing/presentation/widgets/practice_exam_share_card.dart';
import '../widgets/explain_mistakes_sheet.dart';

class TestResultsScreen extends ConsumerStatefulWidget {
  final String testId;

  const TestResultsScreen({super.key, required this.testId});

  @override
  ConsumerState<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends ConsumerState<TestResultsScreen> {
  int? _expandedIndex; // null = all collapsed
  bool _confettiShown = false;
  bool _mistakeAnalysisExpanded = false; // #78: Mistake Analysis card
  bool _testHistoryExpanded = false; // #79: Test Analytics Dashboard

  void _maybeTriggerConfetti(double score) {
    if (!_confettiShown && score >= 60) {
      _confettiShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ConfettiOverlay.show(context);
        // Extra celebration for perfect score
        if (score >= 100) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              CelebrationOverlay.show(
                context,
                title: '🏆 Perfect Score!',
                subtitle: 'You mastered every question!',
                icon: Icons.military_tech,
                color: const Color(0xFFF59E0B),
              );
            }
          });
        }
      });
    }
  }

  void _showExplainMistakes(String testId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, __) => ExplainMistakesSheet(testId: testId),
      ),
    );
  }

  Future<void> _showShareSheet(TestWithQuestions result) async {
    final test = result.test;
    final profile = ref.read(profileProvider).valueOrNull;
    final xpTotal = ref.read(xpTotalProvider).valueOrNull ?? 0;

    // Get course name
    String courseName = 'My Course';
    try {
      final course = await Supabase.instance.client
          .from('courses')
          .select('title')
          .eq('id', test.courseId)
          .maybeSingle();
      courseName = course?['title'] as String? ?? 'My Course';
    } catch (e) {
      debugPrint('TestResults: fetch course name for share failed: $e');
    }

    if (!mounted) return;

    final isPracticeExam = test.isPracticeExam;

    final Widget shareCard = isPracticeExam
        ? PracticeExamShareCard(
            scorePercent: (test.score ?? 0) * 100,
            grade: test.grade ?? 'N/A',
            correctCount: test.correctCount,
            totalCount: test.totalCount,
            courseName: courseName,
            userName: profile?.fullName ?? 'Student',
            xpLevel: XpConfig.levelFromXp(xpTotal),
          )
        : QuizShareCard(
            scorePercent: (test.score ?? 0) * 100,
            grade: test.grade ?? 'N/A',
            correctCount: test.correctCount,
            totalCount: test.totalCount,
            courseName: courseName,
            userName: profile?.fullName ?? 'Student',
            xpLevel: XpConfig.levelFromXp(xpTotal),
            streakDays: profile?.streakDays ?? 0,
          );

    SharePreviewSheet.show(
      context,
      shareCard: shareCard,
      shareType: isPracticeExam ? 'practice_exam' : 'quiz',
      referenceId: test.id,
    );
  }

  Future<void> _retryQuiz(TestWithQuestions result) async {
    final courseId = result.test.courseId;

    // Fetch course name for the generation banner
    String courseName = 'My Course';
    try {
      final course = await Supabase.instance.client
          .from('courses')
          .select('title')
          .eq('id', courseId)
          .maybeSingle();
      courseName = course?['title'] as String? ?? 'My Course';
    } catch (e) {
      debugPrint('TestResults: fetch course name for retry failed: $e');
    }

    if (!mounted) return;

    ref.read(generationProvider.notifier).generateQuiz(courseId, courseName);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating new quiz...')),
    );

    context.go(Routes.home);
  }

  /// Extract weak topics from wrong answers and generate a focused quiz.
  Future<void> _smartRetryQuiz(TestWithQuestions result) async {
    HapticFeedback.mediumImpact();
    final courseId = result.test.courseId;

    // Extract topics from wrong answers using question text as topic hints
    final wrongQuestions = result.questions
        .where((q) => !q.isCorrect)
        .toList();

    if (wrongQuestions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mistakes found — try a regular retry!')),
      );
      return;
    }

    // Use question text as focus topics (the edge function will use them as context)
    final focusTopics = wrongQuestions
        .map((q) => q.question)
        .toList();

    // Fetch course name for the generation banner
    String courseName = 'My Course';
    try {
      final course = await Supabase.instance.client
          .from('courses')
          .select('title')
          .eq('id', courseId)
          .maybeSingle();
      courseName = course?['title'] as String? ?? 'My Course';
    } catch (e) {
      debugPrint('TestResults: fetch course name for smart retry failed: $e');
    }

    if (!mounted) return;

    ref.read(generationProvider.notifier).generateQuiz(
      courseId,
      courseName,
      focusTopics: focusTopics,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generating smart quiz focused on ${wrongQuestions.length} weak topic${wrongQuestions.length == 1 ? '' : 's'}...',
        ),
      ),
    );

    context.go(Routes.home);
  }

  /// Create a flashcard deck from wrong answers in this quiz.
  Future<void> _createFlashcardsFromMistakes(TestWithQuestions result) async {
    HapticFeedback.mediumImpact();

    final wrongQuestions = result.questions
        .where((q) => !q.isCorrect)
        .toList();

    if (wrongQuestions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mistakes to create flashcards from!')),
      );
      return;
    }

    try {
      final repo = ref.read(flashcardRepositoryProvider);

      // Create the deck
      final deck = await repo.createDeck(
        courseId: result.test.courseId,
        title: 'Quiz Mistakes — ${result.test.title ?? 'Review'}',
      );

      // Create flashcard entries matching the flashcards table schema
      final cards = wrongQuestions.map((q) => {
        'deck_id': deck.id,
        'user_id': result.test.userId,
        'topic': 'Quiz Mistake',
        'question_before': q.question,
        'keyword': q.correctAnswer,
        'question_after': '',
        'answer': q.correctAnswer,
      }).toList();

      await repo.insertCards(cards);

      // Invalidate related providers so they refresh
      ref.invalidate(flashcardDecksProvider(result.test.courseId));
      ref.invalidate(parentDecksProvider(result.test.courseId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Created deck with ${wrongQuestions.length} flashcard${wrongQuestions.length == 1 ? '' : 's'} from mistakes',
          ),
        ),
      );

      // Navigate to the new deck detail
      context.push(Routes.deckDetailPath(deck.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorHandler.friendlyMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(testResultsProvider(widget.testId));

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: Stack(
        children: [
          // Animated ambient orbs
          const Positioned.fill(
            child: FloatingOrbs(),
          ),

          // Main content
          SafeArea(
            bottom: false,
            child: resultsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: ShimmerList(count: 4, itemHeight: 100),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48,
                          color: Colors.white38),
                      const SizedBox(height: AppSpacing.md),
                      Text('Could not load results',
                          style: AppTypography.h3),
                      const SizedBox(height: AppSpacing.sm),
                      Text(AppErrorHandler.friendlyMessage(e),
                          style: AppTypography.bodySmall,
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
              data: (result) {
                return _buildResults(result);
              },
            ),
          ),

          // Floating CTAs
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            child: resultsAsync.whenOrNull(
                  data: (result) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Share Result button
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: TapScale(
                            onTap: () => _showShareSheet(result),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.share_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Share Result',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Explain Mistakes button (only if there are mistakes)
                        if (result.test.mistakeCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: TapScale(
                              onTap: () => _showExplainMistakes(result.test.id),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.psychology,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Explain My Mistakes',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Retry Quiz button
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: TapScale(
                            onTap: () => _retryQuiz(result),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.replay_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Retry Quiz',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Smart Retry button (only if there are mistakes)
                        if (result.test.mistakeCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: TapScale(
                              onTap: () => _smartRetryQuiz(result),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ctaLime.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: AppColors.ctaLime.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '\u{1F3AF}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          'Smart Retry',
                                          style: AppTypography.labelLarge.copyWith(
                                            color: AppColors.ctaLime,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Focus on ${result.test.mistakeCount} weak topic${result.test.mistakeCount == 1 ? '' : 's'}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.ctaLime.withValues(alpha: 0.7),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Create Flashcards from Mistakes button (only if there are mistakes)
                        if (result.test.mistakeCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: TapScale(
                              onTap: () => _createFlashcardsFromMistakes(result),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '\u{1F0CF}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Create Flashcards from Mistakes',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Practice Weak Areas button
                        PrimaryButton(
                          label: 'Practice Weak Areas',
                          trailingIcon: Icons.fitness_center,
                          onPressed: () async {
                            final canUse = await checkFeatureAccess(
                              ref: ref,
                              feature: 'flashcards',
                              context: context,
                            );
                            if (!canUse) return;

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Generating weak area flashcards...')),
                              );
                            }
                            try {
                              final deck = await ref
                                  .read(flashcardRepositoryProvider)
                                  .generateFlashcards(
                                    courseId: result.test.courseId,
                                    topic: 'weak areas',
                                    count: 15,
                                  );
                              if (context.mounted) {
                                context.push(Routes.flashcardSessionPath(deck.id));
                              }
                              await recordFeatureUsage(ref: ref, feature: 'flashcards');
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppErrorHandler.friendlyMessage(e))),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    );
                  },
                ) ??
                const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(TestWithQuestions result) {
    final test = result.test;
    final questions = result.questions;
    final correctCount = test.correctCount;
    final totalCount = test.totalCount;
    final mistakeCount = test.mistakeCount;
    final score = test.score ?? 0.0;

    // Trigger confetti for scores >= 60%
    _maybeTriggerConfetti(score);

    return Column(
      children: [
        // Top bar: back + title + share
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GlassIconButton(
                icon: Icons.chevron_left,
                onTap: () => Navigator.of(context).pop(),
              ),
              Text(
                'TEST RESULTS',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),
              _GlassIconButton(
                icon: Icons.ios_share,
                onTap: () => _showShareSheet(result),
                iconSize: 18,
              ),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              MediaQuery.of(context).padding.bottom + 260,
            ),
            child: StaggeredColumn(
              children: [
                // Score ring
                ScoreRing(
                  score: score,
                  grade: test.grade ?? 'N/A',
                  correctCount: correctCount,
                  totalCount: totalCount,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Motivational text
                Text(
                  test.motivationText ??
                      'Keep studying to improve your score!',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // #78: Mistake Analysis card
                if (mistakeCount > 0)
                  _buildMistakeAnalysis(questions),

                // #79: Test Analytics Dashboard
                _buildTestHistory(test.courseId),

                const SizedBox(height: AppSpacing.xxl),

                // Section header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detailed Breakdown',
                        style: AppTypography.h4.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$mistakeCount Mistakes',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white38,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Question results
                ..._buildQuestionCards(questions),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── #78: Mistake Analysis ──────────────────────────────────────────

  /// Simple string similarity: ratio of common characters to max length.
  double _stringSimilarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final la = a.toLowerCase();
    final lb = b.toLowerCase();
    if (la == lb) return 1.0;

    // Count common characters (order-insensitive)
    final charsA = la.split('');
    final charsB = lb.split('').toList();
    int common = 0;
    for (final c in charsA) {
      final idx = charsB.indexOf(c);
      if (idx != -1) {
        common++;
        charsB.removeAt(idx);
      }
    }
    final maxLen = la.length > lb.length ? la.length : lb.length;
    return common / maxLen;
  }

  Widget _buildMistakeAnalysis(List<TestQuestionModel> questions) {
    // Categorise incorrect questions
    int knowledgeGaps = 0;
    int closeCalls = 0;
    int skipped = 0;

    for (final q in questions) {
      if (q.isCorrect) continue;

      final userAnswer = (q.userAnswer ?? '').trim();
      if (userAnswer.isEmpty || userAnswer == '(no answer)') {
        skipped++;
      } else {
        final similarity = _stringSimilarity(userAnswer, q.correctAnswer);
        if (similarity > 0.5) {
          closeCalls++;
        } else {
          knowledgeGaps++;
        }
      }
    }

    // Don't show if there's nothing to categorise
    if (knowledgeGaps == 0 && closeCalls == 0 && skipped == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: GestureDetector(
        onTap: () => setState(() =>
            _mistakeAnalysisExpanded = !_mistakeAnalysisExpanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Colors.white60,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Mistake Analysis',
                      style: AppTypography.h4.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    _mistakeAnalysisExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),

              // Expanded content
              if (_mistakeAnalysisExpanded) ...[
                const SizedBox(height: AppSpacing.md),
                if (knowledgeGaps > 0)
                  _mistakeCategoryRow(
                    icon: Icons.circle,
                    color: AppColors.error,
                    label: 'Knowledge Gaps',
                    description: 'Completely wrong answers',
                    count: knowledgeGaps,
                  ),
                if (closeCalls > 0)
                  Padding(
                    padding: EdgeInsets.only(
                        top: knowledgeGaps > 0 ? AppSpacing.sm : 0),
                    child: _mistakeCategoryRow(
                      icon: Icons.circle,
                      color: AppColors.warning,
                      label: 'Close Calls',
                      description: 'Partially right answers',
                      count: closeCalls,
                    ),
                  ),
                if (skipped > 0)
                  Padding(
                    padding: EdgeInsets.only(
                        top: (knowledgeGaps > 0 || closeCalls > 0)
                            ? AppSpacing.sm
                            : 0),
                    child: _mistakeCategoryRow(
                      icon: Icons.circle,
                      color: Colors.white38,
                      label: 'Skipped',
                      description: 'Questions not answered',
                      count: skipped,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _mistakeCategoryRow({
    required IconData icon,
    required Color color,
    required String label,
    required String description,
    required int count,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '$count',
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ── #79: Test Analytics Dashboard ────────────────────────────────

  Widget _buildTestHistory(String courseId) {
    final historyAsync = ref.watch(courseTestsProvider(courseId));

    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tests) {
        // Only show completed tests with scores
        final completed = tests
            .where((t) => t.status == 'completed' && t.score != null)
            .toList();

        if (completed.length < 2) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: GestureDetector(
            onTap: () => setState(
                () => _testHistoryExpanded = !_testHistoryExpanded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Icon(
                        Icons.timeline_rounded,
                        color: AppColors.primary.withValues(alpha: 0.8),
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Your Test History',
                          style: AppTypography.h4.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(
                        _testHistoryExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),

                  // Expanded content
                  if (_testHistoryExpanded) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildTestHistoryContent(completed),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestHistoryContent(List<TestModel> completed) {
    final dateFormat = DateFormat('MMM d');

    // Compute statistics
    final allScores = completed
        .map((t) => (t.score! * 100).round())
        .toList();
    final average = allScores.isNotEmpty
        ? (allScores.reduce((a, b) => a + b) / allScores.length).round()
        : 0;
    final best = allScores.isNotEmpty
        ? allScores.reduce((a, b) => a > b ? a : b)
        : 0;

    // Trend: compare average of last 3 vs overall average
    final recentCount = completed.length >= 3 ? 3 : completed.length;
    final recentScores = allScores.sublist(0, recentCount);
    final recentAvg = recentScores.isNotEmpty
        ? recentScores.reduce((a, b) => a + b) / recentScores.length
        : 0.0;
    final trendUp = recentAvg > average;

    // Last 5 scores as text list
    final last5 = completed.take(5).toList();
    final scoreEntries = last5.map((t) {
      final dateStr = t.createdAt != null
          ? dateFormat.format(t.createdAt!)
          : '?';
      final pct = (t.score! * 100).round();
      return '$dateStr: $pct%';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent scores list
        Text(
          scoreEntries.join('  \u00B7  '),
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white60,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Stats row
        Row(
          children: [
            // Average
            Expanded(
              child: _testStatChip(
                label: 'Average',
                value: '$average%',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Best
            Expanded(
              child: _testStatChip(
                label: 'Best',
                value: '$best%',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Trend
            Expanded(
              child: _testStatChip(
                label: 'Trend',
                value: trendUp ? '\u2191 Up' : '\u2193 Down',
                color: trendUp ? AppColors.success : AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _testStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildQuestionCards(List<TestQuestionModel> questions) {
    final cards = <Widget>[];
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final isExpanded = _expandedIndex == i;

      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: isExpanded
              ? GestureDetector(
                  onTap: () => setState(() => _expandedIndex = null),
                  child: CorrectionCard(
                    questionNumber: q.questionNumber,
                    question: q.question,
                    userAnswer: q.userAnswer ?? '',
                    correctAnswer: q.correctAnswer,
                    aiInsight: q.aiInsight ?? '',
                    isCorrect: q.isCorrect,
                  ),
                )
              : CollapsedCorrectionCard(
                  questionNumber: q.questionNumber,
                  question: q.question,
                  isCorrect: q.isCorrect,
                  onTap: () => setState(() => _expandedIndex = i),
                ),
        ),
      );
    }
    return cards;
  }
}

/// Glass-card icon button matching mockup style.
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;

  const _GlassIconButton({
    required this.icon,
    this.onTap,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      scaleDown: 0.90,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white60,
          size: iconSize,
        ),
      ),
    );
  }
}
