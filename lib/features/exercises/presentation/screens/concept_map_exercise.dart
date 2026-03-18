import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'exercise_screen.dart';

/// Concept Map exercise.
///
/// Data format:
/// ```json
/// {
///   "centralConcept": "Cellular Respiration",
///   "nodes": [
///     {"id": "1", "label": "Glycolysis"},
///     {"id": "2", "label": "Krebs Cycle"},
///     ...
///   ],
///   "connections": [
///     {"from": "1", "to": "2", "label": "produces", "isHidden": true},
///     {"from": "2", "to": "3", "label": "feeds into", "isHidden": false},
///     ...
///   ]
/// }
/// ```
/// Shows the central concept, nodes, and connections.
/// Hidden connections have dropdown/button selectors to fill in the label.
class ConceptMapExercise extends StatefulWidget {
  final dynamic data;
  final String courseId;
  final void Function(int score) onComplete;

  const ConceptMapExercise({
    super.key,
    required this.data,
    required this.courseId,
    required this.onComplete,
  });

  @override
  State<ConceptMapExercise> createState() => _ConceptMapExerciseState();
}

class _ConceptMapExerciseState extends State<ConceptMapExercise>
    with SingleTickerProviderStateMixin {
  static const _accentColor = Color(0xFF6366F1);

  String _centralConcept = '';
  List<Map<String, dynamic>> _nodes = [];
  List<Map<String, dynamic>> _connections = [];

  // Map node id -> label for quick lookup
  final Map<String, String> _nodeLabels = {};

  // Hidden connections tracking
  List<Map<String, dynamic>> _hiddenConnections = [];
  List<Map<String, dynamic>> _visibleConnections = [];

  // User answers: connection index -> selected label
  final Map<int, String?> _userAnswers = {};

  // All unique labels (shuffled) used as options
  List<String> _labelOptions = [];

  // State
  bool _checked = false;
  bool _isComplete = false;
  int _correctCount = 0;
  int _expandedConnectionIndex = -1;

  late AnimationController _revealController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _parseData();
  }

  void _parseData() {
    try {
      final map = widget.data as Map;
      _centralConcept = map['centralConcept'] as String? ?? '';

      final nodes = map['nodes'] as List;
      _nodes =
          nodes.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      for (final node in _nodes) {
        _nodeLabels[node['id'] as String] = node['label'] as String;
      }

      final connections = map['connections'] as List;
      _connections = connections
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      _hiddenConnections =
          _connections.where((c) => c['isHidden'] == true).toList();
      _visibleConnections =
          _connections.where((c) => c['isHidden'] != true).toList();

      // Collect all connection labels as options, shuffle
      final allLabels =
          _connections.map((c) => c['label'] as String).toSet().toList();
      allLabels.shuffle(Random());
      _labelOptions = allLabels;

      // Initialize user answers
      for (int i = 0; i < _hiddenConnections.length; i++) {
        _userAnswers[i] = null;
      }
    } catch (e) {
      debugPrint('ConceptMapExercise: parseData failed: $e');
      _centralConcept = '';
      _nodes = [];
      _connections = [];
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _selectAnswer(int connectionIndex, String label) {
    HapticFeedback.selectionClick();
    setState(() {
      _userAnswers[connectionIndex] = label;
      _expandedConnectionIndex = -1;
    });
  }

  void _toggleExpanded(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedConnectionIndex == index) {
        _expandedConnectionIndex = -1;
      } else {
        _expandedConnectionIndex = index;
      }
    });
  }

  void _checkAnswers() {
    HapticFeedback.mediumImpact();
    _correctCount = 0;

    for (int i = 0; i < _hiddenConnections.length; i++) {
      final correctLabel = _hiddenConnections[i]['label'] as String;
      final userLabel = _userAnswers[i];
      if (userLabel != null &&
          userLabel.toLowerCase() == correctLabel.toLowerCase()) {
        _correctCount++;
      }
    }

    setState(() => _checked = true);
    _revealController.forward();
  }

  void _finish() {
    final total = _hiddenConnections.length;
    final score = total > 0 ? ((_correctCount / total) * 100).round() : 100;
    setState(() => _isComplete = true);
    widget.onComplete(score);
  }

  bool get _allAnswered {
    for (int i = 0; i < _hiddenConnections.length; i++) {
      if (_userAnswers[i] == null) return false;
    }
    return _hiddenConnections.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_centralConcept.isEmpty && _nodes.isEmpty) {
      return Column(
        children: [
          const ExerciseHeader(
            title: 'Concept Map',
            accentColor: _accentColor,
            icon: Icons.hub_rounded,
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
            title: 'Concept Map',
            accentColor: _accentColor,
            icon: Icons.hub_rounded,
          ),
          Expanded(
            child: ExerciseCompleteCard(
              score: _correctCount,
              total: _hiddenConnections.length,
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
          title: 'Concept Map',
          subtitle: _checked
              ? '$_correctCount/${_hiddenConnections.length} correct'
              : 'Fill in the missing connections',
          accentColor: _accentColor,
          icon: Icons.hub_rounded,
        ),
        const SizedBox(height: AppSpacing.md),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Central concept
              _buildCentralConceptCard(),

              const SizedBox(height: AppSpacing.md),

              // Nodes grid
              _buildNodesGrid(),

              const SizedBox(height: AppSpacing.lg),

              // Connections section label
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded,
                        size: 16, color: _accentColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      'Connections',
                      style: AppTypography.labelMedium.copyWith(
                        color: _accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Visible connections
              ..._visibleConnections.map(
                (c) => _buildVisibleConnection(c),
              ),

              if (_visibleConnections.isNotEmpty &&
                  _hiddenConnections.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: _accentColor.withValues(alpha: 0.15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        child: Text(
                          'Fill in the blanks',
                          style: AppTypography.caption.copyWith(
                            color: _accentColor.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: _accentColor.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),

              // Hidden connections (interactive)
              ...List.generate(_hiddenConnections.length, (i) {
                return _buildHiddenConnection(i);
              }),

              const SizedBox(height: AppSpacing.lg),

              // Check / Finish button
              if (!_checked)
                TapScale(
                  onTap: _allAnswered ? _checkAnswers : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _allAnswered
                          ? _accentColor
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _allAnswered
                          ? [
                              BoxShadow(
                                color: _accentColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      'Check Answers',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge.copyWith(
                        color: _allAnswered ? Colors.white : Colors.white30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                TapScale(
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

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Central Concept
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCentralConceptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentColor.withValues(alpha: 0.15),
            _accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentColor.withValues(alpha: 0.2),
            ),
            child: Icon(Icons.hub_rounded, size: 22, color: _accentColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _centralConcept,
            style: AppTypography.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Central Concept',
            style: AppTypography.caption.copyWith(
              color: _accentColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Nodes Grid
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNodesGrid() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: _nodes.map((node) {
        final label = node['label'] as String? ?? '';
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.immersiveCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.immersiveBorder),
          ),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Visible Connection
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVisibleConnection(Map<String, dynamic> connection) {
    final fromId = connection['from'] as String? ?? '';
    final toId = connection['to'] as String? ?? '';
    final label = connection['label'] as String? ?? '';
    final fromLabel = _nodeLabels[fromId] ?? fromId;
    final toLabel = _nodeLabels[toId] ?? toId;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                fromLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded,
                size: 14, color: _accentColor.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded,
                size: 14, color: _accentColor.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                toLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Hidden Connection (interactive)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHiddenConnection(int index) {
    final connection = _hiddenConnections[index];
    final fromId = connection['from'] as String? ?? '';
    final toId = connection['to'] as String? ?? '';
    final correctLabel = connection['label'] as String? ?? '';
    final fromLabel = _nodeLabels[fromId] ?? fromId;
    final toLabel = _nodeLabels[toId] ?? toId;
    final userAnswer = _userAnswers[index];
    final isExpanded = _expandedConnectionIndex == index;

    bool? isCorrect;
    if (_checked && userAnswer != null) {
      isCorrect = userAnswer.toLowerCase() == correctLabel.toLowerCase();
    }

    Color borderColor;
    Color bgColor;
    if (_checked) {
      if (isCorrect == true) {
        borderColor = AppColors.success.withValues(alpha: 0.5);
        bgColor = AppColors.success.withValues(alpha: 0.06);
      } else if (isCorrect == false) {
        borderColor = AppColors.error.withValues(alpha: 0.5);
        bgColor = AppColors.error.withValues(alpha: 0.06);
      } else {
        borderColor = AppColors.immersiveBorder;
        bgColor = AppColors.immersiveCard;
      }
    } else if (userAnswer != null) {
      borderColor = _accentColor.withValues(alpha: 0.5);
      bgColor = _accentColor.withValues(alpha: 0.06);
    } else {
      borderColor = _accentColor.withValues(alpha: 0.3);
      bgColor = AppColors.immersiveCard;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        children: [
          // Connection row
          TapScale(
            onTap: _checked ? null : () => _toggleExpanded(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10),
                  bottomLeft: Radius.circular(isExpanded ? 0 : 10),
                  bottomRight: Radius.circular(isExpanded ? 0 : 10),
                ),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fromLabel,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14,
                      color: _accentColor.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),

                  // Answer slot
                  if (_checked && isCorrect == false) ...[
                    // Show wrong answer crossed out, then correct
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            userAnswer ?? '???',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            correctLabel,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: userAnswer != null
                            ? (_checked && isCorrect == true
                                ? AppColors.success.withValues(alpha: 0.15)
                                : _accentColor.withValues(alpha: 0.15))
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: userAnswer != null
                              ? (_checked && isCorrect == true
                                  ? AppColors.success
                                      .withValues(alpha: 0.4)
                                  : _accentColor.withValues(alpha: 0.4))
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userAnswer ?? '???',
                            style: AppTypography.caption.copyWith(
                              color: userAnswer != null
                                  ? (_checked && isCorrect == true
                                      ? AppColors.success
                                      : _accentColor)
                                  : Colors.white30,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          if (!_checked) ...[
                            const SizedBox(width: 4),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 14,
                              color: _accentColor.withValues(alpha: 0.6),
                            ),
                          ],
                          if (_checked && isCorrect == true)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.check_circle_rounded,
                                  size: 12, color: AppColors.success),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14,
                      color: _accentColor.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      toLabel,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded options
          if (isExpanded && !_checked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.immersiveSurface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                border: Border(
                  left: BorderSide(color: borderColor),
                  right: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _labelOptions.map((label) {
                  final isSelected = userAnswer == label;
                  return TapScale(
                    onTap: () => _selectAnswer(index, label),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _accentColor.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? _accentColor.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        label,
                        style: AppTypography.caption.copyWith(
                          color: isSelected
                              ? _accentColor
                              : Colors.white.withValues(alpha: 0.7),
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
