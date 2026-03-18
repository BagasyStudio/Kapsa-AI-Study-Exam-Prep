import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'exercise_screen.dart';

/// Case Study exercise.
///
/// Data format:
/// ```json
/// {
///   "scenario": "A long scenario text...",
///   "questions": [
///     {
///       "question": "...",
///       "correctAnswer": "...",
///       "keyTerms": ["term1", "term2", ...]
///     },
///     ...
///   ]
/// }
/// ```
/// User reads a scenario, then answers questions. Score is based on key terms mentioned.
class CaseStudyExercise extends StatefulWidget {
  final dynamic data;
  final String courseId;
  final void Function(int score) onComplete;

  const CaseStudyExercise({
    super.key,
    required this.data,
    required this.courseId,
    required this.onComplete,
  });

  @override
  State<CaseStudyExercise> createState() => _CaseStudyExerciseState();
}

class _CaseStudyExerciseState extends State<CaseStudyExercise>
    with SingleTickerProviderStateMixin {
  static const _accentColor = Color(0xFFEC4899);

  String _scenario = '';
  List<Map<String, dynamic>> _questions = [];

  // Phase: 0 = reading scenario, 1 = answering questions, 2 = results
  int _phase = 0;
  int _currentQuestionIndex = 0;
  final _answerController = TextEditingController();
  final _focusNode = FocusNode();
  final List<String> _userAnswers = [];
  bool _isComplete = false;

  // Results tracking
  List<List<String>> _matchedTermsPerQuestion = [];
  int _totalMatchedTerms = 0;
  int _totalPossibleTerms = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _parseData();
  }

  void _parseData() {
    try {
      final map = widget.data as Map;
      _scenario = map['scenario'] as String? ?? '';
      final questions = map['questions'] as List;
      _questions =
          questions.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      _scenario = '';
      _questions = [];
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _continueToQuestions() {
    HapticFeedback.mediumImpact();
    setState(() => _phase = 1);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _submitAnswer() {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;
    HapticFeedback.lightImpact();

    _userAnswers.add(answer);
    _answerController.clear();

    if (_currentQuestionIndex + 1 >= _questions.length) {
      // All questions answered, calculate results
      _calculateResults();
      setState(() => _phase = 2);
      _fadeController.forward(from: 0);
    } else {
      setState(() => _currentQuestionIndex++);
      _focusNode.requestFocus();
    }
  }

  void _calculateResults() {
    _matchedTermsPerQuestion = [];
    _totalMatchedTerms = 0;
    _totalPossibleTerms = 0;

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final keyTerms = (question['keyTerms'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final userAnswer =
          i < _userAnswers.length ? _userAnswers[i].toLowerCase() : '';

      final matched = <String>[];
      for (final term in keyTerms) {
        if (userAnswer.contains(term.toLowerCase())) {
          matched.add(term);
        }
      }

      _matchedTermsPerQuestion.add(matched);
      _totalMatchedTerms += matched.length;
      _totalPossibleTerms += keyTerms.length;
    }
  }

  void _finish() {
    final score = _totalPossibleTerms > 0
        ? ((_totalMatchedTerms / _totalPossibleTerms) * 100).round()
        : 0;
    setState(() => _isComplete = true);
    widget.onComplete(score);
  }

  @override
  Widget build(BuildContext context) {
    if (_scenario.isEmpty && _questions.isEmpty) {
      return Column(
        children: [
          const ExerciseHeader(
            title: 'Case Study',
            accentColor: _accentColor,
            icon: Icons.cases_rounded,
          ),
          const Expanded(
            child: Center(
              child: Text('No data available',
                  style: TextStyle(color: Colors.white60)),
            ),
          ),
        ],
      );
    }

    if (_isComplete) {
      return Column(
        children: [
          const ExerciseHeader(
            title: 'Case Study',
            accentColor: _accentColor,
            icon: Icons.cases_rounded,
          ),
          Expanded(
            child: ExerciseCompleteCard(
              score: _totalMatchedTerms,
              total: _totalPossibleTerms,
              accentColor: _accentColor,
              courseId: widget.courseId,
              onFinish: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      );
    }

    switch (_phase) {
      case 0:
        return _buildScenarioPhase();
      case 1:
        return _buildQuestionPhase();
      case 2:
        return _buildResultsPhase();
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Phase 0: Scenario Reading
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScenarioPhase() {
    return Column(
      children: [
        const ExerciseHeader(
          title: 'Case Study',
          subtitle: 'Read the scenario',
          accentColor: _accentColor,
          icon: Icons.cases_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Scenario card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.immersiveCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor.withValues(alpha: 0.15),
                            ),
                            child: Icon(Icons.menu_book_rounded,
                                size: 16, color: _accentColor),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Scenario',
                            style: AppTypography.labelLarge.copyWith(
                              color: _accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _scenario,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Continue button
                TapScale(
                  onTap: _continueToQuestions,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue to Questions',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 20, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Phase 1: Questions
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuestionPhase() {
    final question = _questions[_currentQuestionIndex];
    final questionText = question['question'] as String? ?? '';

    return Column(
      children: [
        ExerciseHeader(
          title: 'Case Study',
          subtitle:
              'Question ${_currentQuestionIndex + 1}/${_questions.length}',
          accentColor: _accentColor,
          icon: Icons.cases_rounded,
        ),
        const SizedBox(height: AppSpacing.md),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(_accentColor),
              minHeight: 4,
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Question card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.immersiveCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.immersiveBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Q${_currentQuestionIndex + 1}',
                          style: AppTypography.caption.copyWith(
                            color: _accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        questionText,
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Answer text field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: TextField(
                    controller: _answerController,
                    focusNode: _focusNode,
                    style: AppTypography.bodyMedium
                        .copyWith(color: Colors.white),
                    maxLines: 4,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Type your answer...',
                      hintStyle: AppTypography.bodySmall
                          .copyWith(color: Colors.white30),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitAnswer(),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Submit button
                TapScale(
                  onTap: _answerController.text.trim().isEmpty
                      ? null
                      : _submitAnswer,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _currentQuestionIndex + 1 >= _questions.length
                          ? 'Submit & See Results'
                          : 'Next Question',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Phase 2: Results
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildResultsPhase() {
    final score = _totalPossibleTerms > 0
        ? ((_totalMatchedTerms / _totalPossibleTerms) * 100).round()
        : 0;

    return Column(
      children: [
        ExerciseHeader(
          title: 'Case Study',
          subtitle: '$score% key terms covered',
          accentColor: _accentColor,
          icon: Icons.cases_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _questions.length + 1,
              itemBuilder: (context, index) {
                if (index < _questions.length) {
                  return _buildResultCard(index);
                }
                // Finish button
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: TapScale(
                    onTap: _finish,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.ctaLime,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ctaLime.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Finish',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.ctaLimeText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(int index) {
    final question = _questions[index];
    final questionText = question['question'] as String? ?? '';
    final correctAnswer = question['correctAnswer'] as String? ?? '';
    final keyTerms = (question['keyTerms'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final userAnswer = index < _userAnswers.length ? _userAnswers[index] : '';
    final matchedTerms = index < _matchedTermsPerQuestion.length
        ? _matchedTermsPerQuestion[index]
        : <String>[];
    final allMatched =
        keyTerms.isNotEmpty && matchedTerms.length == keyTerms.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: allMatched
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.immersiveBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question label
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Q${index + 1}',
                style: AppTypography.caption.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Question text
            Text(
              questionText,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // User answer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your answer:',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userAnswer,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Correct answer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Model answer:',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    correctAnswer,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Key terms
            Text(
              'Key Terms',
              style: AppTypography.caption.copyWith(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: keyTerms.map((term) {
                final isMatched = matchedTerms
                    .any((m) => m.toLowerCase() == term.toLowerCase());
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isMatched
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isMatched
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.error.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMatched
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 12,
                        color:
                            isMatched ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        term,
                        style: AppTypography.caption.copyWith(
                          color: isMatched
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
