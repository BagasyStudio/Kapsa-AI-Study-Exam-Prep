import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

/// Countdown timer widget for practice exams.
///
/// Displays MM:SS, turns red when < 2 minutes remain,
/// and pulses when < 30 seconds remain.
/// Calls [onTimeUp] when the timer reaches zero.
class ExamTimerWidget extends StatefulWidget {
  final int totalMinutes;
  final VoidCallback onTimeUp;

  const ExamTimerWidget({
    super.key,
    required this.totalMinutes,
    required this.onTimeUp,
  });

  @override
  State<ExamTimerWidget> createState() => _ExamTimerWidgetState();
}

class _ExamTimerWidgetState extends State<ExamTimerWidget>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _pulseController;
  bool _timeUpCalled = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalMinutes * 60;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });

      // Start pulsing when < 30 seconds
      if (_remainingSeconds <= 30 && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }

      if (_remainingSeconds <= 0) {
        timer.cancel();
        if (!_timeUpCalled) {
          _timeUpCalled = true;
          widget.onTimeUp();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color get _timerColor {
    if (_remainingSeconds <= 30) return const Color(0xFFEF4444);
    if (_remainingSeconds <= 120) return const Color(0xFFF59E0B);
    return Colors.white.withValues(alpha: 0.8);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale =
            _remainingSeconds <= 30 ? 1.0 + _pulseController.value * 0.08 : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _remainingSeconds <= 30
                  ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                  : _remainingSeconds <= 120
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: _remainingSeconds <= 30
                    ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: _timerColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _formattedTime,
                  style: AppTypography.labelLarge.copyWith(
                    color: _timerColor,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
