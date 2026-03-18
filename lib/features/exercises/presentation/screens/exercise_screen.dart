import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../home/data/models/journey_node_model.dart';
import '../../../home/presentation/providers/exercise_provider.dart';
import 'fill_gaps_exercise.dart';
import 'speed_round_exercise.dart';
import 'mistake_spotter_exercise.dart';
import 'teach_bot_exercise.dart';
import 'compare_contrast_exercise.dart';
import 'timeline_exercise.dart';
import 'case_study_exercise.dart';
import 'match_blitz_exercise.dart';
import 'concept_map_exercise.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Exercise Difficulty
// ═══════════════════════════════════════════════════════════════════════════════

/// Difficulty levels available for exercises.
enum ExerciseDifficulty { easy, medium, hard }

/// Unified exercise screen that loads exercise data from the edge function
/// and delegates to the appropriate exercise widget.
///
/// Shows a difficulty selector before loading the exercise data.
class ExerciseScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String exerciseType;

  const ExerciseScreen({
    super.key,
    required this.courseId,
    required this.exerciseType,
  });

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  ExerciseDifficulty? _selectedDifficulty;
  bool _extendedTime = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: SafeArea(
        child: _selectedDifficulty == null
            ? _DifficultySelector(
                exerciseType: widget.exerciseType,
                extendedTime: _extendedTime,
                onExtendedTimeChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _extendedTime = value);
                },
                onSelect: (difficulty) {
                  HapticFeedback.mediumImpact();
                  setState(() => _selectedDifficulty = difficulty);
                },
              )
            : _ExerciseBody(
                courseId: widget.courseId,
                exerciseType: widget.exerciseType,
                difficulty: _selectedDifficulty!,
                extendedTime: _extendedTime,
              ),
      ),
    );
  }
}

/// The actual exercise body that loads data and renders the exercise.
class _ExerciseBody extends ConsumerWidget {
  final String courseId;
  final String exerciseType;
  final ExerciseDifficulty difficulty;
  final bool extendedTime;

  const _ExerciseBody({
    required this.courseId,
    required this.exerciseType,
    required this.difficulty,
    this.extendedTime = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final params = (
      courseId: courseId,
      exerciseType: exerciseType,
    );
    final exerciseAsync = ref.watch(exerciseDataProvider(params));

    return exerciseAsync.when(
      loading: () => _LoadingState(exerciseType: exerciseType),
      error: (e, _) => _ErrorState(
        message: l.exerciseCouldNotLoad,
        onRetry: () => ref.invalidate(exerciseDataProvider(params)),
      ),
      data: (data) {
        final exercise = data['exercise'];
        if (exercise == null) {
          return _ErrorState(
            message: l.exerciseCouldNotLoad,
            onRetry: () => ref.invalidate(exerciseDataProvider(params)),
          );
        }

        return _buildExercise(context, ref, exercise);
      },
    );
  }

  /// Time multiplier: 2x when extended time is on.
  double get timeMultiplier => extendedTime ? 2.0 : 1.0;

  Widget _buildExercise(BuildContext context, WidgetRef ref, dynamic rawExerciseData) {
    // Inject extendedTime multiplier into exercise data so child widgets
    // can read it. If data is a Map, add a '_timeMultiplier' key.
    final dynamic exerciseData;
    if (rawExerciseData is Map<String, dynamic>) {
      exerciseData = {
        ...rawExerciseData,
        '_timeMultiplier': timeMultiplier,
        '_extendedTime': extendedTime,
      };
    } else {
      exerciseData = rawExerciseData;
    }

    final onComplete = (int score) {
      // Save score
      ref
          .read(exerciseScoreProvider(courseId).notifier)
          .saveScore('${exerciseType}_${DateTime.now().millisecondsSinceEpoch}', score);

      // Save to exercise performance history (#73)
      _saveExerciseHistory(
        exerciseType: exerciseType,
        courseId: courseId,
        score: score,
        difficulty: difficulty.name,
      );

      // Increment streak
      ref.read(streakMultiplierProvider.notifier).increment();

      // Return result to journey
      Navigator.of(context).pop(JourneyResult.completed);
    };

    switch (exerciseType) {
      case 'fillGaps':
        return FillGapsExercise(
          data: exerciseData,
          courseId: courseId,
          onComplete: onComplete,
        );
      case 'speedRound':
        return SpeedRoundExercise(
          data: exerciseData,
          courseId: courseId,
          onComplete: onComplete,
        );
      case 'mistakeSpotter':
        return MistakeSpotterExercise(
          data: exerciseData,
          courseId: courseId,
          onComplete: onComplete,
        );
      case 'teachBot':
        return TeachBotExercise(
          data: exerciseData,
          courseId: courseId,
          onComplete: onComplete,
        );
      case 'compareContrast':
        return CompareContrastExercise(
          data: exerciseData,
          courseId: courseId,
          onComplete: onComplete,
        );
      case 'timeline':
        return TimelineExercise(
          data: exerciseData,
          courseId: courseId,
          onComplete: onComplete,
        );
      case 'caseStudy':
        return CaseStudyExercise(
          data: exerciseData,
          courseId: courseId,
          onComplete: onComplete,
        );
      case 'matchBlitz':
        return MatchBlitzExercise(
          data: exerciseData,
          courseId: courseId,
          onComplete: onComplete,
        );
      case 'conceptMap':
        return ConceptMapExercise(
          data: exerciseData,
          courseId: courseId,
          onComplete: onComplete,
        );
      default:
        return _ErrorState(
          message: 'Unknown exercise type: $exerciseType',
          onRetry: () => Navigator.of(context).pop(),
        );
    }
  }

  /// Save exercise score to SharedPreferences history (#73).
  static Future<void> _saveExerciseHistory({
    required String exerciseType,
    required String courseId,
    required int score,
    required String difficulty,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'exercise_${exerciseType}_${courseId}_history';
      final raw = prefs.getString(key);
      List<Map<String, dynamic>> history = [];
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          history = decoded.cast<Map<String, dynamic>>();
        }
      }
      history.add({
        'score': score,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'difficulty': difficulty,
      });
      // Keep max 30 entries (trim oldest)
      if (history.length > 30) {
        history = history.sublist(history.length - 30);
      }
      await prefs.setString(key, jsonEncode(history));
    } catch (_) {
      // Silently ignore storage errors
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Task 1: Difficulty Selector
// ═══════════════════════════════════════════════════════════════════════════════

class _DifficultySelector extends StatefulWidget {
  final String exerciseType;
  final ValueChanged<ExerciseDifficulty> onSelect;
  final bool extendedTime;
  final ValueChanged<bool> onExtendedTimeChanged;

  const _DifficultySelector({
    required this.exerciseType,
    required this.onSelect,
    this.extendedTime = false,
    required this.onExtendedTimeChanged,
  });

  @override
  State<_DifficultySelector> createState() => _DifficultySelectorState();
}

class _DifficultySelectorState extends State<_DifficultySelector>
    with SingleTickerProviderStateMixin {
  ExerciseDifficulty _chosen = ExerciseDifficulty.medium;
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final options = [
      _DifficultyOption(
        difficulty: ExerciseDifficulty.easy,
        label: l.exerciseDifficultyEasy,
        description: l.exerciseDifficultyEasyDesc,
        icon: Icons.sentiment_satisfied_alt_rounded,
        color: const Color(0xFF10B981),
      ),
      _DifficultyOption(
        difficulty: ExerciseDifficulty.medium,
        label: l.exerciseDifficultyMedium,
        description: l.exerciseDifficultyMediumDesc,
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _DifficultyOption(
        difficulty: ExerciseDifficulty.hard,
        label: l.exerciseDifficultyHard,
        description: l.exerciseDifficultyHardDesc,
        icon: Icons.bolt_rounded,
        color: const Color(0xFFEF4444),
      ),
    ];

    return FadeTransition(
      opacity: _entryAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_entryAnimation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              // Close button row
              Align(
                alignment: Alignment.centerLeft,
                child: TapScale(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Title
              Text(
                l.exerciseDifficultyTitle,
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _exerciseTypeLabel(widget.exerciseType),
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Difficulty cards
              ...List.generate(options.length, (i) {
                final opt = options[i];
                final isSelected = _chosen == opt.difficulty;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i < options.length - 1 ? AppSpacing.sm : 0,
                  ),
                  child: TapScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _chosen = opt.difficulty);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? opt.color.withValues(alpha: 0.12)
                            : AppColors.immersiveCard,
                        borderRadius: AppRadius.borderRadiusMd,
                        border: Border.all(
                          color: isSelected
                              ? opt.color.withValues(alpha: 0.6)
                              : AppColors.immersiveBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: opt.color.withValues(alpha: isSelected ? 0.2 : 0.1),
                            ),
                            child: Icon(
                              opt.icon,
                              size: 22,
                              color: opt.color,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt.label,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt.description,
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? opt.color
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? opt.color
                                    : Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.lg),

              // Extended Time toggle (#111)
              TapScale(
                onTap: () => widget.onExtendedTimeChanged(
                    !widget.extendedTime),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: widget.extendedTime
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                        : AppColors.immersiveCard,
                    borderRadius: AppRadius.borderRadiusMd,
                    border: Border.all(
                      color: widget.extendedTime
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                          : AppColors.immersiveBorder,
                      width: widget.extendedTime ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.extendedTime
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              size: 18,
                              color: widget.extendedTime
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white38,
                            ),
                            if (widget.extendedTime)
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF3B82F6),
                                    border: Border.all(
                                      color: AppColors.immersiveCard,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 7,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Extended Time',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '2x time for all timed exercises',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: widget.extendedTime
                              ? const Color(0xFF3B82F6)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          alignment: widget.extendedTime
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Start button (with extended time badge)
              TapScale(
                onTap: () => widget.onSelect(_chosen),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.ctaLime,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ctaLime.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.extendedTime) ...[
                        Icon(
                          Icons.timer_rounded,
                          size: 18,
                          color: AppColors.ctaLimeText.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        l.exerciseDifficultyStart,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.ctaLimeText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (widget.extendedTime) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.ctaLimeText.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '2x',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.ctaLimeText,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  String _exerciseTypeLabel(String type) {
    switch (type) {
      case 'fillGaps':
        return 'Fill the Gaps';
      case 'speedRound':
        return 'Speed Round';
      case 'mistakeSpotter':
        return 'Mistake Spotter';
      case 'teachBot':
        return 'Teach the Bot';
      case 'compareContrast':
        return 'Compare & Contrast';
      case 'timeline':
        return 'Timeline';
      case 'caseStudy':
        return 'Case Study';
      case 'matchBlitz':
        return 'Match Blitz';
      case 'conceptMap':
        return 'Concept Map';
      default:
        return type;
    }
  }
}

class _DifficultyOption {
  final ExerciseDifficulty difficulty;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _DifficultyOption({
    required this.difficulty,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared Exercise Widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Common header for all exercise screens.
class ExerciseHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color accentColor;
  final IconData icon;
  final VoidCallback? onClose;
  final bool extendedTime;

  const ExerciseHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.accentColor,
    required this.icon,
    this.onClose,
    this.extendedTime = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
      ),
      child: Row(
        children: [
          TapScale(
            onTap: onClose ?? () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Extended Time badge (#111)
          if (extendedTime)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_rounded,
                    size: 12,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '2x',
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Task 2: Exercise Combo Indicator
// ═══════════════════════════════════════════════════════════════════════════════

/// Animated combo/streak indicator shown during exercise sessions.
///
/// Follows the same visual pattern as [QuizComboIndicator] but adds
/// bonus XP milestone feedback. Hidden when [count] < 3.
class ExerciseComboIndicator extends StatefulWidget {
  final int count;

  const ExerciseComboIndicator({super.key, required this.count});

  @override
  State<ExerciseComboIndicator> createState() => _ExerciseComboIndicatorState();
}

class _ExerciseComboIndicatorState extends State<ExerciseComboIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _entryController;
  late AnimationController _bonusController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _entryAnimation;
  late Animation<double> _bonusAnimation;
  int _prevCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_pulseController);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    );

    _bonusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bonusAnimation = CurvedAnimation(
      parent: _bonusController,
      curve: Curves.easeOutCubic,
    );

    if (widget.count >= 3) {
      _entryController.forward();
    }
  }

  @override
  void didUpdateWidget(ExerciseComboIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.count != _prevCount) {
      if (widget.count >= 3 && _prevCount < 3) {
        // Entering combo state
        _entryController.forward(from: 0);
        HapticFeedback.lightImpact();
      } else if (widget.count < 3 && _prevCount >= 3) {
        // Leaving combo state
        _entryController.reverse();
      } else if (widget.count > _prevCount && widget.count >= 3) {
        // Combo increased — pulse
        _pulseController.forward(from: 0);

        // Show bonus XP at milestones
        if (_isBonusMilestone(widget.count)) {
          _bonusController.forward(from: 0);
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      }
    }
    _prevCount = widget.count;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entryController.dispose();
    _bonusController.dispose();
    super.dispose();
  }

  bool _isBonusMilestone(int count) =>
      count == 5 || count == 10 || count == 15 || count == 20;

  int _bonusXp(int count) {
    if (count >= 15) return 30;
    if (count >= 10) return 20;
    if (count >= 5) return 10;
    return 0;
  }

  String _emoji(int count) {
    if (count >= 15) return '\u{1F3C6}'; // trophy
    if (count >= 10) return '\u{26A1}'; // lightning
    if (count >= 5) return '\u{1F525}'; // fire
    return '\u{1F4AA}'; // muscle
  }

  List<Color> _gradientColors(int count) {
    if (count >= 15) {
      return const [Color(0xFFF59E0B), Color(0xFFEF4444)];
    }
    if (count >= 10) {
      return const [Color(0xFFEF4444), Color(0xFFEC4899)];
    }
    if (count >= 5) {
      return const [Color(0xFFF97316), Color(0xFFEF4444)];
    }
    return const [Color(0xFF10B981), Color(0xFF06B6D4)];
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.count;
    final l = AppLocalizations.of(context)!;

    if (count < 3) {
      return ScaleTransition(
        scale: _entryAnimation,
        child: const SizedBox(width: 0, height: 0),
      );
    }

    final gradient = _gradientColors(count);
    final emoji = _emoji(count);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bonus XP text (appears at milestones)
        if (_isBonusMilestone(count))
          FadeTransition(
            opacity: _bonusAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: const Offset(0, -0.3),
              ).animate(_bonusAnimation),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l.exerciseComboBonusXp(_bonusXp(count)),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.xpGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),

        // Main combo pill
        ScaleTransition(
          scale: _entryAnimation,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 5),
                  Text(
                    l.exerciseComboStreak(count),
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Task 3: Related Content Card (shown on exercise completion)
// ═══════════════════════════════════════════════════════════════════════════════

/// Card shown after exercise completion to link to related study content.
class ExerciseRelatedContentCard extends StatelessWidget {
  final String courseId;

  const ExerciseRelatedContentCard({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: AppColors.immersiveBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.exerciseRelatedTitle,
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _RelatedButton(
                  emoji: '\u{1F4DA}', // books
                  label: l.exerciseRelatedSummary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(Routes.summariesListPath(courseId));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _RelatedButton(
                  emoji: '\u{1F0CF}', // cards
                  label: l.exerciseRelatedFlashcards,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(Routes.deckListPath(courseId));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _RelatedButton(
                  emoji: '\u{1F4D6}', // open book
                  label: l.exerciseRelatedGlossary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(Routes.glossaryPath(courseId));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RelatedButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _RelatedButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Exercise Completion Card (updated with Related Content)
// ═══════════════════════════════════════════════════════════════════════════════

/// Exercise completion card shown at the end.
///
/// Now includes an optional [courseId] to display the [ExerciseRelatedContentCard]
/// and an optional [exerciseType] for performance trend tracking (#73).
class ExerciseCompleteCard extends StatefulWidget {
  final int score;
  final int total;
  final String? improvementText;
  final VoidCallback onFinish;
  final Color accentColor;
  final String? courseId;
  final String? exerciseType;

  const ExerciseCompleteCard({
    super.key,
    required this.score,
    required this.total,
    this.improvementText,
    required this.onFinish,
    this.accentColor = AppColors.primary,
    this.courseId,
    this.exerciseType,
  });

  @override
  State<ExerciseCompleteCard> createState() => _ExerciseCompleteCardState();
}

class _ExerciseCompleteCardState extends State<ExerciseCompleteCard> {
  _ExerciseTrend? _trend;

  @override
  void initState() {
    super.initState();
    _loadTrend();
  }

  Future<void> _loadTrend() async {
    if (widget.exerciseType == null || widget.courseId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'exercise_${widget.exerciseType}_${widget.courseId}_history';
      final raw = prefs.getString(key);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.length < 2) return;
      final history = decoded.cast<Map<String, dynamic>>();
      // Get last 3 scores (or fewer if not enough data)
      final recentCount = history.length >= 3 ? 3 : history.length;
      final recent = history.sublist(history.length - recentCount);
      final scores = recent.map((e) => (e['score'] as num).toInt()).toList();

      _ExerciseTrend trend;
      if (scores.length >= 3) {
        final isIncreasing = scores[2] > scores[1] && scores[1] > scores[0];
        final isDecreasing = scores[2] < scores[1] && scores[1] < scores[0];
        if (isIncreasing) {
          trend = _ExerciseTrend.improving;
        } else if (isDecreasing) {
          trend = _ExerciseTrend.declining;
        } else {
          trend = _ExerciseTrend.consistent;
        }
      } else if (scores.length == 2) {
        if (scores[1] > scores[0]) {
          trend = _ExerciseTrend.improving;
        } else if (scores[1] < scores[0]) {
          trend = _ExerciseTrend.declining;
        } else {
          trend = _ExerciseTrend.consistent;
        }
      } else {
        return;
      }

      if (mounted) {
        setState(() => _trend = trend);
      }
    } catch (e) {
      debugPrint('ExerciseScreen: load exercise trend failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final percent = widget.total > 0
        ? ((widget.score / widget.total) * 100).round()
        : 0;
    final isGood = percent >= 70;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Score circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isGood
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFFF59E0B), const Color(0xFFF97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isGood
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B))
                        .withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$percent%',
                    style: AppTypography.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                    ),
                  ),
                  Text(
                    '${widget.score}/${widget.total}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l.exerciseComplete,
              style: AppTypography.h3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isGood ? l.exerciseGoodJob : l.exerciseKeepPracticing,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white60,
              ),
            ),
            if (widget.improvementText != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  widget.improvementText!,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            // Performance trend indicator (#73)
            if (_trend != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _ExerciseTrendIndicator(trend: _trend!),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Related content card (Task 3)
            if (widget.courseId != null) ...[
              ExerciseRelatedContentCard(courseId: widget.courseId!),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Finish button
            Padding(
              padding: widget.courseId != null
                  ? const EdgeInsets.symmetric(horizontal: AppSpacing.xl)
                  : EdgeInsets.zero,
              child: TapScale(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onFinish();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.ctaLime,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ctaLime.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    l.exerciseFinish,
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
        ),
      ),
    );
  }
}

// ── Exercise Trend Types & Indicator (#73) ─────────────────────────────────

enum _ExerciseTrend { improving, consistent, declining }

class _ExerciseTrendIndicator extends StatelessWidget {
  final _ExerciseTrend trend;

  const _ExerciseTrendIndicator({required this.trend});

  @override
  Widget build(BuildContext context) {
    final String label;
    final String arrow;
    final Color color;

    switch (trend) {
      case _ExerciseTrend.improving:
        arrow = '\u2191'; // ↑
        label = 'Improving!';
        color = AppColors.success;
      case _ExerciseTrend.consistent:
        arrow = '\u2192'; // →
        label = 'Consistent';
        color = AppColors.primary;
      case _ExerciseTrend.declining:
        arrow = '\u2193'; // ↓
        label = 'Review needed';
        color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            arrow,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Loading & Error States
// ═══════════════════════════════════════════════════════════════════════════════

class _LoadingState extends StatefulWidget {
  final String exerciseType;

  const _LoadingState({required this.exerciseType});

  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FadeTransition(
            opacity: _pulseAnimation,
            child: Text(
              l.exerciseLoading,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.ctaLime,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.white38),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: AppSpacing.lg),
          TapScale(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Retry',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
