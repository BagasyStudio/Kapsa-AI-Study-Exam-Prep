import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'exercise_screen.dart';

/// Mistake Spotter exercise.
///
/// Data format: JSON object with `paragraph` (array of sentences)
/// and `errors` (array of {sentenceIndex, correction, explanation}).
/// User taps sentences they think contain errors, then submits to check.
class MistakeSpotterExercise extends StatefulWidget {
  final dynamic data;
  final String courseId;
  final void Function(int score) onComplete;

  const MistakeSpotterExercise({
    super.key,
    required this.data,
    required this.courseId,
    required this.onComplete,
  });

  @override
  State<MistakeSpotterExercise> createState() =>
      _MistakeSpotterExerciseState();
}

class _MistakeSpotterExerciseState extends State<MistakeSpotterExercise>
    with SingleTickerProviderStateMixin {
  static const _accentColor = Color(0xFFEF4444);

  List<String> _sentences = [];
  List<Map<String, dynamic>> _errors = [];
  final Set<int> _selectedIndices = {};
  bool _submitted = false;
  bool _isComplete = false;
  int _correctCount = 0;

  late AnimationController _feedbackAnimController;
  late Animation<double> _feedbackAnim;

  @override
  void initState() {
    super.initState();
    _feedbackAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackAnim = CurvedAnimation(
      parent: _feedbackAnimController,
      curve: Curves.easeOutBack,
    );
    _parseData();
  }

  void _parseData() {
    try {
      final map = Map<String, dynamic>.from(widget.data as Map);
      final paragraphList = map['paragraph'] as List;
      _sentences = paragraphList.map((e) => e.toString()).toList();
      final errorsList = map['errors'] as List;
      _errors =
          errorsList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      _sentences = [];
      _errors = [];
    }
  }

  @override
  void dispose() {
    _feedbackAnimController.dispose();
    super.dispose();
  }

  Set<int> get _errorIndices =>
      _errors.map((e) => (e['sentenceIndex'] as num).toInt()).toSet();

  void _toggleSentence(int index) {
    if (_submitted) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _submit() {
    if (_submitted) return;
    HapticFeedback.mediumImpact();

    final errorSet = _errorIndices;
    int correct = 0;
    for (final idx in _selectedIndices) {
      if (errorSet.contains(idx)) correct++;
    }

    _correctCount = correct;

    setState(() => _submitted = true);
    _feedbackAnimController.forward(from: 0);
  }

  void _finish() {
    final score = _errors.isEmpty
        ? 0
        : ((_correctCount / _errors.length) * 100).round();
    setState(() => _isComplete = true);
    widget.onComplete(score);
  }

  String? _getCorrectionFor(int index) {
    for (final err in _errors) {
      if ((err['sentenceIndex'] as num).toInt() == index) {
        return err['correction'] as String?;
      }
    }
    return null;
  }

  String? _getExplanationFor(int index) {
    for (final err in _errors) {
      if ((err['sentenceIndex'] as num).toInt() == index) {
        return err['explanation'] as String?;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_sentences.isEmpty) {
      return Column(
        children: [
          const ExerciseHeader(
            title: 'Mistake Spotter',
            accentColor: _accentColor,
            icon: Icons.search_rounded,
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
            title: 'Mistake Spotter',
            accentColor: _accentColor,
            icon: Icons.search_rounded,
          ),
          Expanded(
            child: ExerciseCompleteCard(
              score: _correctCount,
              total: _errors.length,
              accentColor: _accentColor,
              courseId: widget.courseId,
              onFinish: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      );
    }

    final errorSet = _errorIndices;
    final errorMap = <int, Map<String, dynamic>>{};
    for (final e in _errors) {
      errorMap[(e['sentenceIndex'] as num).toInt()] = e;
    }
    final canSubmit = _selectedIndices.length == _errors.length;

    return Column(
      children: [
        ExerciseHeader(
          title: 'Mistake Spotter',
          subtitle: _submitted
              ? '$_correctCount/${_errors.length} errors found'
              : 'Tap sentences with errors',
          accentColor: _accentColor,
          icon: Icons.search_rounded,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Instructions badge ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: _accentColor.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Find ${_errors.length} sentence${_errors.length == 1 ? '' : 's'} with errors. Selected: ${_selectedIndices.length}/${_errors.length}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // ── Sentences list ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: _sentences.length,
            itemBuilder: (context, index) {
              return _buildSentenceCard(index, errorSet, errorMap);
            },
          ),
        ),

        // ── Bottom button ──
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _submitted
              ? ScaleTransition(
                  scale: _feedbackAnim,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: (_correctCount == _errors.length
                                  ? AppColors.success
                                  : AppColors.warning)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _correctCount == _errors.length
                                  ? Icons.check_circle_rounded
                                  : Icons.info_rounded,
                              color: _correctCount == _errors.length
                                  ? AppColors.success
                                  : AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$_correctCount/${_errors.length} errors found correctly',
                                style: AppTypography.labelMedium.copyWith(
                                  color: _correctCount == _errors.length
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TapScale(
                        onTap: _finish,
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.ctaLime,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ctaLime
                                    .withValues(alpha: 0.3),
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
                    ],
                  ),
                )
              : TapScale(
                  onTap: canSubmit ? _submit : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: canSubmit
                          ? _accentColor
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: canSubmit
                          ? [
                              BoxShadow(
                                color:
                                    _accentColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      canSubmit
                          ? 'Submit'
                          : 'Select ${_errors.length - _selectedIndices.length} more',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge.copyWith(
                        color: canSubmit
                            ? Colors.white
                            : Colors.white30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSentenceCard(
    int index,
    Set<int> errorIndices,
    Map<int, Map<String, dynamic>> errorMap,
  ) {
    final isSelected = _selectedIndices.contains(index);
    final isError = errorIndices.contains(index);

    Color borderColor;
    Color bgColor;
    if (_submitted) {
      if (isError && isSelected) {
        // Correctly found error
        borderColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.08);
      } else if (isError && !isSelected) {
        // Missed error
        borderColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.08);
      } else if (!isError && isSelected) {
        // Wrong selection
        borderColor = Colors.white24;
        bgColor = Colors.white.withValues(alpha: 0.03);
      } else {
        borderColor = AppColors.immersiveBorder;
        bgColor = AppColors.immersiveCard;
      }
    } else {
      borderColor =
          isSelected ? _accentColor : AppColors.immersiveBorder;
      bgColor = isSelected
          ? _accentColor.withValues(alpha: 0.08)
          : AppColors.immersiveCard;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TapScale(
        onTap: _submitted ? null : () => _toggleSentence(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selection indicator
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 10, top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected && !_submitted
                          ? _accentColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: isSelected && !_submitted
                            ? _accentColor
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            _submitted
                                ? (isError
                                    ? Icons.check_rounded
                                    : Icons.close_rounded)
                                : Icons.circle,
                            size: _submitted ? 16 : 8,
                            color: _submitted
                                ? (isError
                                    ? AppColors.success
                                    : Colors.white38)
                                : _accentColor,
                          )
                        : _submitted && isError
                            ? const Icon(Icons.error_outline,
                                size: 16, color: AppColors.error)
                            : null,
                  ),
                  Expanded(
                    child: Text(
                      _sentences[index],
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(
                          alpha: _submitted && !isError && !isSelected
                              ? 0.5
                              : 0.9,
                        ),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              // Show correction/explanation after submit
              if (_submitted && isError && errorMap.containsKey(index))
                Padding(
                  padding:
                      const EdgeInsets.only(left: 34, top: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_getCorrectionFor(index) != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getCorrectionFor(index)!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (_getExplanationFor(index) != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: AppSpacing.xxs),
                          child: Text(
                            _getExplanationFor(index)!,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
