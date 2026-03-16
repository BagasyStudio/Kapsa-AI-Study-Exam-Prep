import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../providers/inline_quiz_provider.dart';
import 'inline_quiz_feedback_card.dart';

/// Oracle inline quiz widget rendered at the bottom of the chat ListView.
///
/// Drives through phases: generating -> answering (per-question) ->
/// evaluating -> complete, with premium dark styling and Oracle identity.
class InlineQuizWidget extends ConsumerStatefulWidget {
  final String courseId;
  final VoidCallback? onScrollToBottom;

  const InlineQuizWidget({
    super.key,
    required this.courseId,
    this.onScrollToBottom,
  });

  @override
  ConsumerState<InlineQuizWidget> createState() => _InlineQuizWidgetState();
}

class _InlineQuizWidgetState extends ConsumerState<InlineQuizWidget> {
  final _answerController = TextEditingController();
  final _answerFocusNode = FocusNode();

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  void _requestScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onScrollToBottom?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inlineQuizProvider(widget.courseId));
    final notifier = ref.read(inlineQuizProvider(widget.courseId).notifier);

    // Auto-scroll on phase changes
    ref.listen<InlineQuizState>(
      inlineQuizProvider(widget.courseId),
      (prev, next) {
        if (prev?.phase != next.phase ||
            prev?.currentIndex != next.currentIndex ||
            prev?.currentQuestionState != next.currentQuestionState) {
          _requestScroll();
        }
      },
    );

    if (state.phase == InlineQuizPhase.idle) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.xl,
        top: AppSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.immersiveBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Oracle identity header
            _OracleQuizHeader(
              showCancel: state.phase == InlineQuizPhase.answering,
              onCancel: () => notifier.reset(),
              progress: state.phase == InlineQuizPhase.answering
                  ? '${state.currentIndex + 1}/${state.questions.length}'
                  : null,
            ),

            // Phase-specific content
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: _buildPhaseContent(state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseContent(InlineQuizState state, InlineQuizNotifier notifier) {
    switch (state.phase) {
      case InlineQuizPhase.generating:
        return _buildGenerating();
      case InlineQuizPhase.answering:
        return _buildAnswering(state, notifier);
      case InlineQuizPhase.evaluating:
        return _buildEvaluating();
      case InlineQuizPhase.complete:
        return _buildComplete(state, notifier);
      case InlineQuizPhase.error:
        return _buildError(state, notifier);
      case InlineQuizPhase.idle:
        return const SizedBox.shrink();
    }
  }

  // ── Generating ──

  Widget _buildGenerating() {
    return Column(
      children: [
        const ShimmerCard(height: 48),
        const SizedBox(height: AppSpacing.sm),
        const ShimmerCard(height: 32),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Preparing your quiz...',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ── Answering ──

  Widget _buildAnswering(InlineQuizState state, InlineQuizNotifier notifier) {
    final question = state.questions[state.currentIndex];
    final qState = state.currentQuestionState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        Text(
          question.question,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 1.5,
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        if (qState == QuestionUiState.typing) ...[
          // Answer input
          _AnswerInput(
            controller: _answerController,
            focusNode: _answerFocusNode,
            onSubmit: () => _submitAnswer(notifier, state),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Check Answer button
          _GradientButton(
            label: 'Check Answer',
            enabled: _answerController.text.trim().isNotEmpty,
            onTap: () => _submitAnswer(notifier, state),
          ),
        ] else if (qState == QuestionUiState.revealed) ...[
          // Feedback card
          InlineQuizFeedbackCard(
            isCorrect: state.localResults[state.currentIndex] ?? false,
            userAnswer: state.userAnswers[state.currentIndex] ?? '',
            correctAnswer: question.correctAnswer,
          ),

          const SizedBox(height: AppSpacing.md),

          // Next / See Results button
          _GradientButton(
            label: state.currentIndex < state.questions.length - 1
                ? 'Next Question'
                : 'See Results',
            enabled: true,
            onTap: () {
              _answerController.clear();
              notifier.nextQuestion();
            },
          ),
        ],
      ],
    );
  }

  void _submitAnswer(InlineQuizNotifier notifier, InlineQuizState state) {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;
    _answerFocusNode.unfocus();
    notifier.checkAnswer(text);
  }

  // ── Evaluating ──

  Widget _buildEvaluating() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(
              AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Evaluating your answers...',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  // ── Complete ──

  Widget _buildComplete(InlineQuizState state, InlineQuizNotifier notifier) {
    final result = state.evaluatedResult;
    if (result == null) return const SizedBox.shrink();

    final test = result.test;
    final questions = result.questions;
    final score = test.correctCount;
    final total = test.totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score circle + grade
        Row(
          children: [
            _ScoreCircle(score: score, total: total),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (test.grade != null)
                    Text(
                      'Grade: ${test.grade}',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  if (test.motivationText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      test.motivationText!,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Per-question result rows
        ...questions.map((q) => QuizResultRow(
              index: q.questionNumber,
              isCorrect: q.isCorrect,
              question: q.question,
              aiInsight: q.aiInsight,
            )),

        // Mistakes explanation (loaded on demand)
        if (state.mistakesExplanation != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _MistakesExplanationCard(data: state.mistakesExplanation!),
        ],

        const SizedBox(height: AppSpacing.md),

        // CTAs
        if (test.mistakeCount > 0 && state.mistakesExplanation == null) ...[
          _GradientButton(
            label: state.isLoadingMistakes
                ? 'Loading...'
                : 'Review Mistakes',
            enabled: !state.isLoadingMistakes,
            onTap: () => notifier.loadMistakesExplanation(),
            icon: Icons.lightbulb_outline,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        _GradientButton(
          label: 'Take Full Exam',
          enabled: true,
          onTap: () => context.push(Routes.practiceExam),
          icon: Icons.school,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Continue chatting (muted)
        Center(
          child: TapScale(
            onTap: () => notifier.reset(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Continue Chatting',
                style: AppTypography.caption.copyWith(
                  color: Colors.white38,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Error ──

  Widget _buildError(InlineQuizState state, InlineQuizNotifier notifier) {
    return Column(
      children: [
        Icon(
          state.isNoMaterials ? Icons.folder_open : Icons.error_outline,
          size: 32,
          color: state.isNoMaterials
              ? Colors.white38
              : AppColors.error.withValues(alpha: 0.7),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          state.errorMessage ?? 'Something went wrong.',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white60,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.isNoMaterials)
          _GradientButton(
            label: 'Go to Materials',
            enabled: true,
            onTap: () => context.push(
              Routes.courseDetailPath(widget.courseId),
            ),
            icon: Icons.folder,
          )
        else if (state.userAnswers.isNotEmpty)
          _GradientButton(
            label: 'Retry Evaluation',
            enabled: true,
            onTap: () => notifier.retryEvaluation(),
          )
        else
          _GradientButton(
            label: 'Try Again',
            enabled: true,
            onTap: () => notifier.startQuiz(),
          ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

/// Oracle Quiz header pill with cancel button.
class _OracleQuizHeader extends StatelessWidget {
  final bool showCancel;
  final VoidCallback? onCancel;
  final String? progress;

  const _OracleQuizHeader({
    this.showCancel = false,
    this.onCancel,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Oracle Quiz pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Oracle Quiz',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Progress pill
          if (progress != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                progress!,
                style: AppTypography.caption.copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],

          const Spacer(),

          // Cancel button
          if (showCancel)
            TapScale(
              scaleDown: 0.85,
              onTap: onCancel,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white38,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dark themed answer input field.
class _AnswerInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  const _AnswerInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  @override
  State<_AnswerInput> createState() => _AnswerInputState();
}

class _AnswerInputState extends State<_AnswerInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    // Auto-focus the input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Trigger rebuild to update button state
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      style: AppTypography.bodyMedium.copyWith(
        color: Colors.white,
        fontSize: 14,
      ),
      maxLines: 3,
      minLines: 1,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => widget.onSubmit(),
      decoration: InputDecoration(
        hintText: 'Type your answer...',
        hintStyle: AppTypography.bodySmall.copyWith(
          color: Colors.white24,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

/// Gradient primary button.
class _GradientButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final IconData? icon;

  const _GradientButton({
    required this.label,
    required this.enabled,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                )
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: enabled ? Colors.white : Colors.white24,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: enabled ? Colors.white : Colors.white24,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Score circle with fraction display.
class _ScoreCircle extends StatelessWidget {
  final int score;
  final int total;

  const _ScoreCircle({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? score / total : 0.0;
    final color = fraction >= 0.7
        ? AppColors.success
        : fraction >= 0.4
            ? AppColors.warning
            : AppColors.error;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              value: fraction,
              strokeWidth: 3.5,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              Text(
                '/$total',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white38,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Expanded explanation of mistakes from the AI.
class _MistakesExplanationCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MistakesExplanationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final explanation = data['explanation'] as String? ?? '';
    final weakTopics = data['weakTopics'] as List<dynamic>? ?? [];
    final studyTips = data['studyTips'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Review Insights',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          if (explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              explanation,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],

          if (weakTopics.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Focus areas:',
              style: AppTypography.caption.copyWith(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: weakTopics
                  .take(4)
                  .map((t) => _TopicChip(label: t.toString()))
                  .toList(),
            ),
          ],

          if (studyTips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...studyTips.take(3).map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\u2022 ',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tip.toString(),
                            style: AppTypography.caption.copyWith(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;

  const _TopicChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
