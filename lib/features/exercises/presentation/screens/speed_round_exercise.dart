import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'exercise_screen.dart';

/// Speed Round exercise with countdown timer.
///
/// Data format: JSON array of `{"statement":"...","isTrue":bool,"explanation":"..."}`
/// 3-2-1 countdown, then statements with timer bar. TRUE/FALSE buttons.
///
/// Accessibility: time multiplier options (1x / 1.5x / 2x), haptic warnings
/// at 3s and 1s remaining, and a prominent countdown number when < 3s left.
class SpeedRoundExercise extends StatefulWidget {
  final dynamic data;
  final String courseId;
  final void Function(int score) onComplete;

  const SpeedRoundExercise({
    super.key,
    required this.data,
    required this.courseId,
    required this.onComplete,
  });

  @override
  State<SpeedRoundExercise> createState() => _SpeedRoundExerciseState();
}

class _SpeedRoundExerciseState extends State<SpeedRoundExercise>
    with TickerProviderStateMixin {
  static const _accentColor = Color(0xFFF97316);
  static const _baseSeconds = 5;

  /// Available time multipliers for accessibility.
  static const _timeMultipliers = <_TimeMultiplier>[
    _TimeMultiplier(label: 'Normal', multiplier: 1.0, icon: Icons.timer_outlined),
    _TimeMultiplier(label: 'Extended', multiplier: 1.5, icon: Icons.timer),
    _TimeMultiplier(label: 'Relaxed', multiplier: 2.0, icon: Icons.accessibility_new_rounded),
  ];

  List<Map<String, dynamic>> _items = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  int _comboCount = 0;
  bool _showingFeedback = false;
  bool? _lastAnswerCorrect;
  String _feedbackExplanation = '';
  bool _isComplete = false;

  // Time multiplier selection
  int _selectedMultiplierIndex = 0;
  double get _timeMultiplier =>
      _timeMultipliers[_selectedMultiplierIndex].multiplier;
  Duration get _questionDuration =>
      Duration(milliseconds: (_baseSeconds * _timeMultiplier * 1000).round());

  // Countdown state
  bool _showCountdown = true;
  int _countdownValue = 3;

  // Timer for each question
  AnimationController? _timerController;
  AnimationController? _feedbackAnimController;
  late Animation<double> _feedbackAnim;

  // Haptic feedback tracking — avoid repeated triggers per question
  bool _hapticTriggered3s = false;
  bool _hapticTriggered1s = false;

  @override
  void initState() {
    super.initState();
    _parseData();
    _feedbackAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _feedbackAnim = CurvedAnimation(
      parent: _feedbackAnimController!,
      curve: Curves.easeOutBack,
    );
    _startCountdown();
  }

  void _parseData() {
    try {
      final list = widget.data as List;
      _items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('SpeedRoundExercise: parseData failed: $e');
      _items = [];
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _countdownValue = 2);
      HapticFeedback.lightImpact();

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => _countdownValue = 1);
        HapticFeedback.lightImpact();

        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() => _showCountdown = false);
          HapticFeedback.heavyImpact();
          _startQuestionTimer();
        });
      });
    });
  }

  void _startQuestionTimer() {
    _timerController?.dispose();
    _hapticTriggered3s = false;
    _hapticTriggered1s = false;

    _timerController = AnimationController(
      vsync: this,
      duration: _questionDuration,
    );
    _timerController!.addListener(_checkTimerHaptics);
    _timerController!.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_showingFeedback) {
        _handleTimeout();
      }
    });
    _timerController!.forward();
  }

  /// Check remaining time and trigger haptic feedback at thresholds.
  void _checkTimerHaptics() {
    if (_timerController == null) return;
    final totalMs = _questionDuration.inMilliseconds;
    final elapsedMs = (_timerController!.value * totalMs).round();
    final remainingMs = totalMs - elapsedMs;
    final remainingSec = remainingMs / 1000.0;

    if (!_hapticTriggered3s && remainingSec <= 3.0) {
      _hapticTriggered3s = true;
      HapticFeedback.lightImpact();
    }
    if (!_hapticTriggered1s && remainingSec <= 1.0) {
      _hapticTriggered1s = true;
      HapticFeedback.mediumImpact();
    }

    // Rebuild for the countdown number overlay
    if (remainingSec <= 3.0) {
      setState(() {});
    }
  }

  void _handleTimeout() {
    _submitAnswer(null);
  }

  void _submitAnswer(bool? userAnswer) {
    if (_showingFeedback) return;
    _timerController?.stop();

    final item = _items[_currentIndex];
    final correctAnswer = item['isTrue'] as bool;
    final explanation = item['explanation'] as String? ?? '';
    final isCorrect = userAnswer == correctAnswer;

    if (isCorrect) {
      _correctCount++;
      _comboCount++;
    } else {
      _comboCount = 0;
    }

    setState(() {
      _showingFeedback = true;
      _lastAnswerCorrect = userAnswer == null ? false : isCorrect;
      _feedbackExplanation = userAnswer == null
          ? "Time's up! ${correctAnswer ? 'TRUE' : 'FALSE'} — $explanation"
          : explanation;
    });

    _feedbackAnimController!.forward(from: 0);
    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _feedbackAnimController!.reset();

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
          _feedbackExplanation = '';
        });
        _startQuestionTimer();
      }
    });
  }

  @override
  void dispose() {
    _timerController?.removeListener(_checkTimerHaptics);
    _timerController?.dispose();
    _feedbackAnimController?.dispose();
    super.dispose();
  }

  /// Compute remaining seconds for the current question timer.
  double get _remainingSeconds {
    if (_timerController == null || !_timerController!.isAnimating) {
      return _questionDuration.inMilliseconds / 1000.0;
    }
    final totalMs = _questionDuration.inMilliseconds;
    final elapsedMs = (_timerController!.value * totalMs).round();
    return (totalMs - elapsedMs) / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Column(
        children: [
          const ExerciseHeader(
            title: 'Speed Round',
            accentColor: _accentColor,
            icon: Icons.bolt_rounded,
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

    // ── Countdown screen ──
    if (_showCountdown) {
      return _buildCountdown();
    }

    // ── Complete screen ──
    if (_isComplete) {
      return Column(
        children: [
          const ExerciseHeader(
            title: 'Speed Round',
            accentColor: _accentColor,
            icon: Icons.bolt_rounded,
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
    final statement = item['statement'] as String? ?? '';
    final remaining = _remainingSeconds;
    final showCountdownNumber = remaining <= 3.0 && !_showingFeedback;

    return Column(
      children: [
        ExerciseHeader(
          title: 'Speed Round',
          subtitle: '${_currentIndex + 1}/${_items.length}',
          accentColor: _accentColor,
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Timer bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AnimatedBuilder(
            animation: _timerController!,
            builder: (context, _) {
              final progress = 1.0 - _timerController!.value;
              Color barColor;
              if (progress > 0.5) {
                barColor = AppColors.success;
              } else if (progress > 0.25) {
                barColor = AppColors.warning;
              } else {
                barColor = AppColors.error;
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(barColor),
                  minHeight: 6,
                ),
              );
            },
          ),
        ),

        // ── Prominent countdown when < 3 seconds ──
        if (showCountdownNumber)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '${remaining.ceil()}',
              style: AppTypography.h1.copyWith(
                color: remaining <= 1.0
                    ? AppColors.error
                    : AppColors.warning,
                fontSize: 40,
                fontWeight: FontWeight.w900,
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
                // ── Statement card ──
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
                  child: Text(
                    statement,
                    style: AppTypography.h4.copyWith(
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // ── Feedback ──
                if (_showingFeedback)
                  ScaleTransition(
                    scale: _feedbackAnim,
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
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                _feedbackExplanation,
                                style: AppTypography.bodySmall.copyWith(
                                  color: _lastAnswerCorrect == true
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.xxl),

                // ── TRUE / FALSE buttons ──
                if (!_showingFeedback)
                  Row(
                    children: [
                      Expanded(
                        child: TapScale(
                          onTap: () => _submitAnswer(true),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    AppColors.success.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.check_rounded,
                                    color: AppColors.success, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'TRUE',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TapScale(
                          onTap: () => _submitAnswer(false),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    AppColors.error.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.close_rounded,
                                    color: AppColors.error, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'FALSE',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    return Container(
      color: AppColors.immersiveBg,
      child: Column(
        children: [
          const Spacer(),

          // Time multiplier chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                Text(
                  'Timer Speed',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_timeMultipliers.length, (index) {
                    final option = _timeMultipliers[index];
                    final isSelected = index == _selectedMultiplierIndex;
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : AppSpacing.xs,
                      ),
                      child: TapScale(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                              () => _selectedMultiplierIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _accentColor.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? _accentColor.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                option.icon,
                                size: 16,
                                color: isSelected
                                    ? _accentColor
                                    : Colors.white38,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                option.label,
                                style: AppTypography.caption.copyWith(
                                  color: isSelected
                                      ? _accentColor
                                      : Colors.white60,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${option.multiplier}x',
                                style: AppTypography.caption.copyWith(
                                  color: isSelected
                                      ? _accentColor.withValues(alpha: 0.7)
                                      : Colors.white30,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${(_baseSeconds * _timeMultiplier).toStringAsFixed(
                    _timeMultiplier == 1.0 ? 0 : 1,
                  )}s per question',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Countdown number
          Center(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_countdownValue),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.5),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$_countdownValue',
                    style: AppTypography.h1.copyWith(
                      color: _accentColor,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

/// Describes a time multiplier option for the speed round.
class _TimeMultiplier {
  final String label;
  final double multiplier;
  final IconData icon;

  const _TimeMultiplier({
    required this.label,
    required this.multiplier,
    required this.icon,
  });
}
