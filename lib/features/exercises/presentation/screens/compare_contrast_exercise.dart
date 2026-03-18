import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'exercise_screen.dart';

/// Compare & Contrast exercise.
///
/// Data format: JSON object with `conceptA`, `conceptB`,
/// `traits` (array of {text, belongsTo: "A"|"B"|"both"}).
/// User taps a trait to cycle through A, B, both. Then checks answers.
class CompareContrastExercise extends StatefulWidget {
  final dynamic data;
  final String courseId;
  final void Function(int score) onComplete;

  const CompareContrastExercise({
    super.key,
    required this.data,
    required this.courseId,
    required this.onComplete,
  });

  @override
  State<CompareContrastExercise> createState() =>
      _CompareContrastExerciseState();
}

class _CompareContrastExerciseState extends State<CompareContrastExercise>
    with SingleTickerProviderStateMixin {
  static const _accentColor = Color(0xFF06B6D4);
  static const _colorA = Color(0xFF3B82F6);
  static const _colorB = Color(0xFFF97316);
  static const _colorBoth = Color(0xFF8B5CF6);

  String _conceptA = '';
  String _conceptB = '';
  List<Map<String, dynamic>> _traits = [];
  List<int> _shuffledOrder = [];

  // User placements: trait index -> "A", "B", "both", or null (unplaced)
  final Map<int, String?> _placements = {};
  bool _checked = false;
  bool _isComplete = false;
  int _correctCount = 0;

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
      _conceptA = map['conceptA'] as String? ?? 'Concept A';
      _conceptB = map['conceptB'] as String? ?? 'Concept B';
      final traits = map['traits'] as List;
      _traits =
          traits.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      // Shuffle the order
      _shuffledOrder = List.generate(_traits.length, (i) => i);
      _shuffledOrder.shuffle();
      for (int i = 0; i < _traits.length; i++) {
        _placements[i] = null;
      }
    } catch (_) {
      _traits = [];
      _shuffledOrder = [];
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  static const _cycle = ['A', 'B', 'both'];

  void _cycleTrait(int index) {
    if (_checked) return;
    HapticFeedback.selectionClick();
    setState(() {
      final current = _placements[index];
      if (current == null) {
        _placements[index] = _cycle[0];
      } else {
        final nextIdx = (_cycle.indexOf(current) + 1) % _cycle.length;
        // If we've cycled past 'both', go back to null then A
        if (nextIdx == 0 && current == 'both') {
          _placements[index] = null;
        } else {
          _placements[index] = _cycle[nextIdx];
        }
      }
    });
  }

  void _check() {
    if (_checked) return;
    HapticFeedback.mediumImpact();

    _correctCount = 0;
    for (int i = 0; i < _traits.length; i++) {
      final correct =
          (_traits[i]['belongsTo'] as String?)?.toUpperCase() ?? '';
      final placed = _placements[i]?.toUpperCase() ?? '';
      if (correct == placed) _correctCount++;
    }

    setState(() => _checked = true);
    _feedbackController.forward();
  }

  void _finish() {
    final score = _traits.isEmpty
        ? 0
        : ((_correctCount / _traits.length) * 100).round();
    setState(() => _isComplete = true);
    widget.onComplete(score);
  }

  Color _colorForZone(String? zone) {
    switch (zone?.toUpperCase()) {
      case 'A':
        return _colorA;
      case 'B':
        return _colorB;
      case 'BOTH':
        return _colorBoth;
      default:
        return Colors.white24;
    }
  }

  String _labelForZone(String? zone) {
    switch (zone?.toUpperCase()) {
      case 'A':
        return _conceptA;
      case 'B':
        return _conceptB;
      case 'BOTH':
        return 'Both';
      default:
        return 'Tap to assign';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_traits.isEmpty) {
      return Column(
        children: [
          const ExerciseHeader(
            title: 'Compare & Contrast',
            accentColor: _accentColor,
            icon: Icons.compare_arrows_rounded,
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
            title: 'Compare & Contrast',
            accentColor: _accentColor,
            icon: Icons.compare_arrows_rounded,
          ),
          Expanded(
            child: ExerciseCompleteCard(
              score: _correctCount,
              total: _traits.length,
              accentColor: _accentColor,
              courseId: widget.courseId,
              onFinish: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      );
    }

    final allPlaced = _placements.values.every((v) => v != null);

    return Column(
      children: [
        ExerciseHeader(
          title: 'Compare & Contrast',
          subtitle: _checked
              ? '$_correctCount/${_traits.length} correct'
              : 'Sort each trait',
          accentColor: _accentColor,
          icon: Icons.compare_arrows_rounded,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Column headers ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: _buildColumnHeader(_conceptA, _colorA),
              ),
              const SizedBox(width: 8),
              _buildColumnHeader('Both', _colorBoth, compact: true),
              const SizedBox(width: 8),
              Expanded(
                child: _buildColumnHeader(_conceptB, _colorB),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Shuffled trait cards ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: _shuffledOrder.length,
            itemBuilder: (context, listIndex) {
              final traitIndex = _shuffledOrder[listIndex];
              return _buildTraitCard(traitIndex);
            },
          ),
        ),

        // ── Bottom button ──
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _checked
              ? Column(
                  children: [
                    FadeTransition(
                      opacity: _feedbackAnim,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: (_correctCount == _traits.length
                                  ? AppColors.success
                                  : AppColors.warning)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _correctCount == _traits.length
                                  ? Icons.check_circle_rounded
                                  : Icons.info_rounded,
                              color: _correctCount == _traits.length
                                  ? AppColors.success
                                  : AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$_correctCount/${_traits.length} correct',
                                style: AppTypography.labelMedium.copyWith(
                                  color: _correctCount == _traits.length
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                )
              : TapScale(
                  onTap: allPlaced ? _check : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: allPlaced
                          ? _accentColor
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: allPlaced
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
                      'Check',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge.copyWith(
                        color: allPlaced
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

  Widget _buildColumnHeader(String label, Color color,
      {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTraitCard(int traitIndex) {
    final trait = _traits[traitIndex];
    final text = trait['text'] as String? ?? '';
    final correctZone =
        (trait['belongsTo'] as String?)?.toUpperCase() ?? '';
    final placement = _placements[traitIndex];

    Color? resultBorderColor;
    if (_checked) {
      final isCorrect = placement?.toUpperCase() == correctZone;
      resultBorderColor = isCorrect ? AppColors.success : AppColors.error;
    }

    final zoneColor = _colorForZone(placement);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TapScale(
        onTap: _checked ? null : () => _cycleTrait(traitIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: placement != null
                ? zoneColor.withValues(alpha: 0.06)
                : AppColors.immersiveCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _checked
                  ? resultBorderColor!.withValues(alpha: 0.5)
                  : placement != null
                      ? zoneColor.withValues(alpha: 0.3)
                      : AppColors.immersiveBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tag showing current assignment
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: placement != null
                          ? zoneColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: placement != null
                            ? zoneColor.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      _labelForZone(placement),
                      style: AppTypography.caption.copyWith(
                        color: placement != null
                            ? zoneColor
                            : Colors.white38,
                        fontWeight: placement != null
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_checked) ...[
                    const SizedBox(width: 6),
                    Icon(
                      placement?.toUpperCase() == correctZone
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 18,
                      color: resultBorderColor,
                    ),
                  ],
                ],
              ),

              // Show correct answer if wrong after check
              if (_checked && placement?.toUpperCase() != correctZone)
                FadeTransition(
                  opacity: _feedbackAnim,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Correct: ${_labelForZone(correctZone)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
