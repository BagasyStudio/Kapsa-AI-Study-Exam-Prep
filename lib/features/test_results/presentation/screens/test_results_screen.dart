import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/confetti_overlay.dart';
import '../../../../core/widgets/floating_orbs.dart';
import '../widgets/score_ring.dart';
import '../widgets/correction_card.dart';
import '../widgets/collapsed_correction_card.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/utils/error_handler.dart';
import '../providers/test_provider.dart';
import '../../data/test_repository.dart';
import '../../data/models/test_question_model.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

class TestResultsScreen extends ConsumerStatefulWidget {
  final String testId;

  const TestResultsScreen({super.key, required this.testId});

  @override
  ConsumerState<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends ConsumerState<TestResultsScreen> {
  int? _expandedIndex; // null = all collapsed
  bool _confettiShown = false;

  void _maybeTriggerConfetti(double score) {
    if (!_confettiShown && score >= 60) {
      _confettiShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ConfettiOverlay.show(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(testResultsProvider(widget.testId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48,
                          color: AppColors.textMuted),
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

          // Floating CTA
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            child: resultsAsync.whenOrNull(
                  data: (result) {
                    return PrimaryButton(
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
                                count: 10,
                                topic: 'weak areas',
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Share results coming soon')),
                  );
                },
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
              MediaQuery.of(context).padding.bottom + 100,
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
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),

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
                          color: const Color(0xFF1E293B),
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$mistakeCount Mistakes',
                          style: AppTypography.caption.copyWith(
                            color: const Color(0xFF64748B),
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
          color: Colors.white.withValues(alpha: 0.45),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
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
          color: const Color(0xFF475569), // slate-600
          size: iconSize,
        ),
      ),
    );
  }
}
