import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'exercise_screen.dart';

/// Match Blitz exercise — two-column matching game.
///
/// Data format:
/// ```json
/// {
///   "pairs": [
///     {"id": "1", "concept": "Photosynthesis", "definition": "Process of converting light to energy"},
///     ...
///   ]
/// }
/// ```
/// User taps a concept, then taps its matching definition.
class MatchBlitzExercise extends StatefulWidget {
  final dynamic data;
  final String courseId;
  final void Function(int score) onComplete;

  const MatchBlitzExercise({
    super.key,
    required this.data,
    required this.courseId,
    required this.onComplete,
  });

  @override
  State<MatchBlitzExercise> createState() => _MatchBlitzExerciseState();
}

class _MatchBlitzExerciseState extends State<MatchBlitzExercise>
    with TickerProviderStateMixin {
  static const _accentColor = Color(0xFF10B981);

  List<Map<String, dynamic>> _pairs = [];
  List<Map<String, dynamic>> _shuffledConcepts = [];
  List<Map<String, dynamic>> _shuffledDefinitions = [];

  // Selection state
  String? _selectedConceptId;
  String? _selectedDefinitionId;

  // Matched pairs
  final Set<String> _matchedIds = {};

  // Wrong match feedback
  String? _wrongConceptId;
  String? _wrongDefinitionId;

  // Stats
  int _attempts = 0;
  int _correctMatches = 0;
  int _comboCount = 0;
  bool _isComplete = false;

  // Timer
  final Stopwatch _stopwatch = Stopwatch();
  late final Stream<void> _timerStream;
  late final StreamSubscription<void> _timerSubscription;
  String _elapsedText = '0:00';

  // Animations
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  late AnimationController _correctFlashController;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _correctFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _parseData();
    _stopwatch.start();

    // Update timer display every second
    _timerStream = Stream.periodic(const Duration(seconds: 1));
    _timerSubscription = _timerStream.listen((_) {
      if (!mounted || _isComplete) return;
      setState(() {
        final elapsed = _stopwatch.elapsed;
        final minutes = elapsed.inMinutes;
        final seconds = elapsed.inSeconds % 60;
        _elapsedText = '$minutes:${seconds.toString().padLeft(2, '0')}';
      });
    });
  }

  void _parseData() {
    try {
      final map = widget.data as Map;
      final pairs = map['pairs'] as List;
      _pairs =
          pairs.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Shuffle concepts and definitions independently
      final rng = Random();
      _shuffledConcepts = List.from(_pairs)..shuffle(rng);
      _shuffledDefinitions = List.from(_pairs)..shuffle(rng);
    } catch (e) {
      debugPrint('MatchBlitzExercise: parseData failed: $e');
      _pairs = [];
    }
  }

  @override
  void dispose() {
    _timerSubscription.cancel();
    _stopwatch.stop();
    _shakeController.dispose();
    _correctFlashController.dispose();
    super.dispose();
  }

  void _selectConcept(String id) {
    if (_matchedIds.contains(id)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedConceptId = id;
      _wrongConceptId = null;
      _wrongDefinitionId = null;

      // If a definition is already selected, check match
      if (_selectedDefinitionId != null) {
        _checkMatch();
      }
    });
  }

  void _selectDefinition(String id) {
    if (_matchedIds.contains(id)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDefinitionId = id;
      _wrongConceptId = null;
      _wrongDefinitionId = null;

      // If a concept is already selected, check match
      if (_selectedConceptId != null) {
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    if (_selectedConceptId == null || _selectedDefinitionId == null) return;

    _attempts++;

    if (_selectedConceptId == _selectedDefinitionId) {
      // Correct match
      HapticFeedback.mediumImpact();
      _correctMatches++;
      _comboCount++;
      _matchedIds.add(_selectedConceptId!);
      _correctFlashController.forward(from: 0);

      setState(() {
        _selectedConceptId = null;
        _selectedDefinitionId = null;
      });

      // Check if all matched
      if (_matchedIds.length >= _pairs.length) {
        _stopwatch.stop();
        final elapsed = _stopwatch.elapsed;
        final minutes = elapsed.inMinutes;
        final seconds = elapsed.inSeconds % 60;
        _elapsedText = '$minutes:${seconds.toString().padLeft(2, '0')}';

        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          final score =
              _pairs.isEmpty ? 0 : ((_correctMatches / _pairs.length) * 100).round();
          setState(() => _isComplete = true);
          widget.onComplete(score);
        });
      }
    } else {
      // Wrong match
      HapticFeedback.heavyImpact();
      _comboCount = 0;
      final wrongC = _selectedConceptId;
      final wrongD = _selectedDefinitionId;
      setState(() {
        _wrongConceptId = wrongC;
        _wrongDefinitionId = wrongD;
        _selectedConceptId = null;
        _selectedDefinitionId = null;
      });

      _shakeController.forward(from: 0);

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _wrongConceptId = null;
          _wrongDefinitionId = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pairs.isEmpty) {
      return Column(
        children: [
          const ExerciseHeader(
            title: 'Match Blitz',
            accentColor: _accentColor,
            icon: Icons.extension_rounded,
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
            title: 'Match Blitz',
            accentColor: _accentColor,
            icon: Icons.extension_rounded,
          ),
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                // Time bonus banner
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_rounded,
                          size: 18, color: _accentColor),
                      const SizedBox(width: 8),
                      Text(
                        'Completed in $_elapsedText',
                        style: AppTypography.labelMedium.copyWith(
                          color: _accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 16,
                        color: _accentColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$_attempts attempts',
                        style: AppTypography.labelMedium.copyWith(
                          color: _accentColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ExerciseCompleteCard(
                    score: _correctMatches,
                    total: _pairs.length,
                    accentColor: _accentColor,
                    courseId: widget.courseId,
                    onFinish: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ExerciseHeader(
          title: 'Match Blitz',
          subtitle: '${_matchedIds.length}/${_pairs.length} matched',
          accentColor: _accentColor,
          icon: Icons.extension_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Timer row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.timer_outlined,
                  size: 16, color: _accentColor.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                _elapsedText,
                style: AppTypography.labelMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Progress
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$_attempts attempts',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _pairs.isEmpty
                  ? 0
                  : _matchedIds.length / _pairs.length,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(_accentColor),
              minHeight: 4,
            ),
          ),
        ),

        // ── Combo indicator ──
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: ExerciseComboIndicator(count: _comboCount),
        ),

        const SizedBox(height: AppSpacing.md),

        // Two-column matching
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Concepts
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                        right: AppSpacing.xs,
                        bottom: AppSpacing.lg),
                    itemCount: _shuffledConcepts.length,
                    itemBuilder: (context, index) {
                      final item = _shuffledConcepts[index];
                      final id = item['id'] as String;
                      return _buildConceptCard(item, id);
                    },
                  ),
                ),

                // Right column: Definitions
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                        left: AppSpacing.xs,
                        bottom: AppSpacing.lg),
                    itemCount: _shuffledDefinitions.length,
                    itemBuilder: (context, index) {
                      final item = _shuffledDefinitions[index];
                      final id = item['id'] as String;
                      return _buildDefinitionCard(item, id);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConceptCard(Map<String, dynamic> item, String id) {
    final isMatched = _matchedIds.contains(id);
    final isSelected = _selectedConceptId == id;
    final isWrong = _wrongConceptId == id;

    Color borderColor;
    Color bgColor;
    if (isMatched) {
      borderColor = AppColors.success.withValues(alpha: 0.4);
      bgColor = AppColors.success.withValues(alpha: 0.08);
    } else if (isWrong) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.12);
    } else if (isSelected) {
      borderColor = _accentColor;
      bgColor = _accentColor.withValues(alpha: 0.12);
    } else {
      borderColor = AppColors.immersiveBorder;
      bgColor = AppColors.immersiveCard;
    }

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isSelected || isWrong ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          if (isMatched)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.check_circle_rounded,
                  size: 16, color: AppColors.success),
            ),
          Expanded(
            child: Text(
              item['concept'] as String? ?? '',
              style: AppTypography.bodySmall.copyWith(
                color: isMatched
                    ? AppColors.success
                    : Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: isMatched ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );

    // Apply shake animation for wrong matches
    if (isWrong) {
      card = AnimatedBuilder(
        animation: _shakeAnim,
        builder: (context, child) {
          final offset = sin(_shakeAnim.value * pi * 4) * 6;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: card,
      );
    }

    return TapScale(
      onTap: isMatched ? null : () => _selectConcept(id),
      child: card,
    );
  }

  Widget _buildDefinitionCard(Map<String, dynamic> item, String id) {
    final isMatched = _matchedIds.contains(id);
    final isSelected = _selectedDefinitionId == id;
    final isWrong = _wrongDefinitionId == id;

    Color borderColor;
    Color bgColor;
    if (isMatched) {
      borderColor = AppColors.success.withValues(alpha: 0.4);
      bgColor = AppColors.success.withValues(alpha: 0.08);
    } else if (isWrong) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.12);
    } else if (isSelected) {
      borderColor = _accentColor;
      bgColor = _accentColor.withValues(alpha: 0.12);
    } else {
      borderColor = AppColors.immersiveBorder;
      bgColor = AppColors.immersiveCard;
    }

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isSelected || isWrong ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          if (isMatched)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.check_circle_rounded,
                  size: 16, color: AppColors.success),
            ),
          Expanded(
            child: Text(
              item['definition'] as String? ?? '',
              style: AppTypography.caption.copyWith(
                color: isMatched
                    ? AppColors.success.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                height: 1.3,
                decoration: isMatched ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );

    // Apply shake animation for wrong matches
    if (isWrong) {
      card = AnimatedBuilder(
        animation: _shakeAnim,
        builder: (context, child) {
          final offset = sin(_shakeAnim.value * pi * 4) * 6;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: card,
      );
    }

    return TapScale(
      onTap: isMatched ? null : () => _selectDefinition(id),
      child: card,
    );
  }
}
