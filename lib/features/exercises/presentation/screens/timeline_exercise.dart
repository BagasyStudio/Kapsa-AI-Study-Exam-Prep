import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'exercise_screen.dart';

/// Timeline exercise.
///
/// Data format: JSON object with `title` (string)
/// and `steps` (array of {id, text} in correct order).
/// Steps are shuffled on init. User reorders with ReorderableListView.
/// Score: 100 if correct on first try, 60 on second, 40 otherwise.
class TimelineExercise extends StatefulWidget {
  final dynamic data;
  final String courseId;
  final void Function(int score) onComplete;

  const TimelineExercise({
    super.key,
    required this.data,
    required this.courseId,
    required this.onComplete,
  });

  @override
  State<TimelineExercise> createState() => _TimelineExerciseState();
}

class _TimelineExerciseState extends State<TimelineExercise>
    with SingleTickerProviderStateMixin {
  static const _accentColor = Color(0xFFF59E0B);

  String _title = '';
  List<Map<String, dynamic>> _correctOrder = [];
  List<Map<String, dynamic>> _currentOrder = [];
  bool _checked = false;
  bool _isComplete = false;
  int _attempt = 0;
  int _correctCount = 0;
  List<bool> _positionCorrect = [];

  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnim;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackAnim = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.easeOutCubic,
    );
    _parseData();
  }

  void _parseData() {
    try {
      final map = widget.data as Map;
      _title = map['title'] as String? ?? 'Put in order';
      final steps = map['steps'] as List;
      _correctOrder =
          steps.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _currentOrder = List.from(_correctOrder);
      _currentOrder.shuffle();
      // Make sure it's actually scrambled
      if (_currentOrder.length > 1) {
        int attempts = 0;
        while (_isIdenticalOrder() && attempts < 10) {
          _currentOrder.shuffle();
          attempts++;
        }
      }
    } catch (_) {
      _correctOrder = [];
      _currentOrder = [];
    }
  }

  bool _isIdenticalOrder() {
    for (int i = 0; i < _currentOrder.length; i++) {
      if (_currentOrder[i]['id'] != _correctOrder[i]['id']) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_checked) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
    });
  }

  void _checkOrder() {
    if (_checked) return;
    HapticFeedback.mediumImpact();

    _attempt++;
    _correctCount = 0;
    _positionCorrect = [];
    for (int i = 0; i < _currentOrder.length; i++) {
      final isCorrect = _currentOrder[i]['id'] == _correctOrder[i]['id'];
      _positionCorrect.add(isCorrect);
      if (isCorrect) _correctCount++;
    }

    setState(() => _checked = true);
    _feedbackController.forward();
  }

  bool get _allCorrect => _correctCount == _correctOrder.length;

  void _retry() {
    HapticFeedback.lightImpact();
    _feedbackController.reset();
    setState(() {
      _checked = false;
      _positionCorrect = [];
      _correctCount = 0;
    });
  }

  void _finish() {
    int score;
    if (_allCorrect) {
      if (_attempt == 1) {
        score = 100;
      } else if (_attempt == 2) {
        score = 60;
      } else {
        score = 40;
      }
    } else {
      // Not all correct, partial score based on positions
      score = _correctOrder.isEmpty
          ? 0
          : ((_correctCount / _correctOrder.length) * 40).round();
    }

    setState(() => _isComplete = true);
    widget.onComplete(score);
  }

  @override
  Widget build(BuildContext context) {
    if (_correctOrder.isEmpty) {
      return Column(
        children: [
          const ExerciseHeader(
            title: 'Timeline',
            accentColor: _accentColor,
            icon: Icons.timeline_rounded,
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
            title: 'Timeline',
            accentColor: _accentColor,
            icon: Icons.timeline_rounded,
          ),
          Expanded(
            child: ExerciseCompleteCard(
              score: _correctCount,
              total: _correctOrder.length,
              accentColor: _accentColor,
              courseId: widget.courseId,
              onFinish: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ExerciseHeader(
          title: 'Timeline',
          subtitle: _title,
          accentColor: _accentColor,
          icon: Icons.timeline_rounded,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Info / Result banner ──
        if (!_checked)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Icon(Icons.drag_indicator,
                    size: 16,
                    color: _accentColor.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  'Drag to reorder the steps',
                  style: AppTypography.bodySmall.copyWith(
                    color: _accentColor.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (_attempt > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Attempt ${_attempt + 1}',
                      style: AppTypography.caption.copyWith(
                        color: _accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        if (_checked)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: FadeTransition(
              opacity: _feedbackAnim,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (_allCorrect
                          ? AppColors.success
                          : AppColors.warning)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_allCorrect
                            ? AppColors.success
                            : AppColors.warning)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _allCorrect
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      size: 18,
                      color: _allCorrect
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _allCorrect
                          ? 'All correct!'
                          : '$_correctCount/${_correctOrder.length} in correct position',
                      style: AppTypography.labelMedium.copyWith(
                        color: _allCorrect
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.sm),

        // ── Reorderable list ──
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            itemCount: _currentOrder.length,
            buildDefaultDragHandles: !_checked,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  return Material(
                    color: Colors.transparent,
                    elevation: 4,
                    shadowColor: _accentColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
              );
            },
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              return _buildStepCard(index);
            },
          ),
        ),

        // ── Bottom button ──
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _checked
              ? Row(
                  children: [
                    if (!_allCorrect)
                      Expanded(
                        child: TapScale(
                          onTap: _retry,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                            child: Text(
                              'Retry',
                              textAlign: TextAlign.center,
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!_allCorrect)
                      const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TapScale(
                        onTap: _finish,
                        child: Container(
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
                    ),
                  ],
                )
              : TapScale(
                  onTap: _checkOrder,
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
                      'Check Order',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStepCard(int index) {
    final step = _currentOrder[index];
    final text = step['text'] as String? ?? '';

    Color borderColor = AppColors.immersiveBorder;
    Color? numberBg;
    Color numberColor = _accentColor;

    if (_checked && _positionCorrect.length > index) {
      final correct = _positionCorrect[index];
      borderColor = correct
          ? AppColors.success.withValues(alpha: 0.5)
          : AppColors.error.withValues(alpha: 0.5);
      numberBg = correct
          ? AppColors.success.withValues(alpha: 0.2)
          : AppColors.error.withValues(alpha: 0.2);
      numberColor = correct ? AppColors.success : AppColors.error;
    }

    return Padding(
      key: ValueKey(step['id']),
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Step number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: numberBg ?? _accentColor.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: AppTypography.labelMedium.copyWith(
                    color: numberColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            if (!_checked)
              Icon(
                Icons.drag_handle_rounded,
                size: 20,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            if (_checked && _positionCorrect.length > index)
              Icon(
                _positionCorrect[index]
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 18,
                color: _positionCorrect[index]
                    ? AppColors.success
                    : AppColors.error,
              ),
          ],
        ),
      ),
    );
  }
}
