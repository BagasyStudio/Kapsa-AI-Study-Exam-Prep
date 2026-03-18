import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'exercise_screen.dart';

/// Fill-in-the-gaps exercise.
///
/// Data format: JSON array of `{"sentence":"...___...","answer":"...","hint":"..."}`
/// Shows sentences one at a time with a text field for the blank.
class FillGapsExercise extends StatefulWidget {
  final dynamic data;
  final String courseId;
  final void Function(int score) onComplete;

  const FillGapsExercise({
    super.key,
    required this.data,
    required this.courseId,
    required this.onComplete,
  });

  @override
  State<FillGapsExercise> createState() => _FillGapsExerciseState();
}

class _FillGapsExerciseState extends State<FillGapsExercise>
    with TickerProviderStateMixin {
  static const _accentColor = Color(0xFF14B8A6);

  List<Map<String, dynamic>> _items = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  int _comboCount = 0;
  bool _showingFeedback = false;
  bool? _lastAnswerCorrect;
  bool _isComplete = false;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  late AnimationController _feedbackAnimController;

  // Slide + fade animation for the explanation card
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _feedbackAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _parseData();
  }

  void _parseData() {
    try {
      final list = widget.data as List;
      _items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      _items = [];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _feedbackAnimController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (_showingFeedback) return;
    final userAnswer = _controller.text.trim().toLowerCase();
    final correctAnswer =
        (_items[_currentIndex]['answer'] as String).trim().toLowerCase();
    final isCorrect = userAnswer == correctAnswer;

    if (isCorrect) {
      _correctCount++;
      _comboCount++;
    } else {
      _comboCount = 0;
    }

    setState(() {
      _showingFeedback = true;
      _lastAnswerCorrect = isCorrect;
    });

    _feedbackAnimController.forward(from: 0);
    _slideController.forward(from: 0);
    HapticFeedback.mediumImpact();

    // Correct answers auto-dismiss after 1.5s
    // Incorrect answers stay until user taps "Continue"
    if (isCorrect) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _advanceToNext();
      });
    }
  }

  void _advanceToNext() {
    if (!mounted) return;
    _controller.clear();
    _feedbackAnimController.reset();
    _slideController.reset();

    if (_currentIndex + 1 >= _items.length) {
      final score = _items.isEmpty
          ? 0
          : ((_correctCount / _items.length) * 100).round();
      setState(() => _isComplete = true);
      widget.onComplete(score);
    } else {
      setState(() {
        _currentIndex++;
        _showingFeedback = false;
        _lastAnswerCorrect = null;
      });
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Column(
        children: [
          const ExerciseHeader(
            title: 'Fill the Gaps',
            accentColor: _accentColor,
            icon: Icons.text_fields_rounded,
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
            title: 'Fill the Gaps',
            accentColor: _accentColor,
            icon: Icons.text_fields_rounded,
          ),
          Expanded(
            child: ExerciseCompleteCard(
              score: _correctCount,
              total: _items.length,
              accentColor: _accentColor,
              courseId: widget.courseId,
              onFinish: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      );
    }

    final item = _items[_currentIndex];
    final sentence = item['sentence'] as String? ?? '';
    final hint = item['hint'] as String? ?? '';
    final correctAnswer = item['answer'] as String? ?? '';

    return Column(
      children: [
        ExerciseHeader(
          title: 'Fill the Gaps',
          subtitle: '${_currentIndex + 1}/${_items.length}',
          accentColor: _accentColor,
          icon: Icons.text_fields_rounded,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Progress bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _items.length,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(_accentColor),
              minHeight: 4,
            ),
          ),
        ),

        // ── Combo indicator ──
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: ExerciseComboIndicator(count: _comboCount),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Sentence card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.immersiveCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _showingFeedback
                          ? (_lastAnswerCorrect == true
                              ? AppColors.success
                              : AppColors.error)
                          : AppColors.immersiveBorder,
                    ),
                  ),
                  child: _buildSentenceRichText(sentence),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Hint ──
                if (hint.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 16,
                            color: _accentColor.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hint,
                            style: AppTypography.bodySmall.copyWith(
                              color: _accentColor.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Text field ──
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _showingFeedback
                          ? (_lastAnswerCorrect == true
                              ? AppColors.success
                              : AppColors.error)
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !_showingFeedback,
                    style:
                        AppTypography.bodyLarge.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your answer...',
                      hintStyle: AppTypography.bodyMedium
                          .copyWith(color: Colors.white30),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _checkAnswer(),
                  ),
                ),

                // ── Feedback with slide + fade ──
                if (_showingFeedback)
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: (_lastAnswerCorrect == true
                                    ? AppColors.success
                                    : AppColors.error)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (_lastAnswerCorrect == true
                                      ? AppColors.success
                                      : AppColors.error)
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _lastAnswerCorrect == true
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: _lastAnswerCorrect == true
                                        ? AppColors.success
                                        : AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _lastAnswerCorrect == true
                                          ? 'Correct!'
                                          : 'The answer was: $correctAnswer',
                                      style:
                                          AppTypography.labelMedium.copyWith(
                                        color: _lastAnswerCorrect == true
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Explanation text for incorrect answers
                              if (_lastAnswerCorrect == false &&
                                  (item['explanation'] as String?)
                                          ?.isNotEmpty ==
                                      true) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 28),
                                  child: Text(
                                    item['explanation'] as String,
                                    style:
                                        AppTypography.bodySmall.copyWith(
                                      color: Colors.white60,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                              // "Continue" button for incorrect answers
                              if (_lastAnswerCorrect == false) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TapScale(
                                    onTap: _advanceToNext,
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.error
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        'Continue',
                                        style: AppTypography.labelMedium
                                            .copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.xl),

                // ── Check button ──
                if (!_showingFeedback)
                  TapScale(
                    onTap:
                        _controller.text.trim().isEmpty ? null : _checkAnswer,
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
                        'Check Answer',
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

  Widget _buildSentenceRichText(String sentence) {
    final parts = sentence.split('___');
    if (parts.length <= 1) {
      return Text(
        sentence,
        style: AppTypography.bodyLarge.copyWith(
          color: Colors.white,
          height: 1.6,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: AppTypography.bodyLarge.copyWith(
          color: Colors.white,
          height: 1.6,
        ),
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            TextSpan(text: parts[i]),
            if (i < parts.length - 1)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 2),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '  ?  ',
                    style: AppTypography.labelMedium.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
