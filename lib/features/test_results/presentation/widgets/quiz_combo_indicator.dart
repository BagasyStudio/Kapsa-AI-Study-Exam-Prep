import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_typography.dart';

/// Animated combo/streak indicator shown during quiz sessions.
///
/// Displays a floating pill badge that grows and pulses as the user
/// answers consecutive questions. Provides satisfying visual feedback
/// to encourage momentum.
///
/// Hidden when [count] < 2.
class QuizComboIndicator extends StatefulWidget {
  final int count;

  const QuizComboIndicator({super.key, required this.count});

  @override
  State<QuizComboIndicator> createState() => _QuizComboIndicatorState();
}

class _QuizComboIndicatorState extends State<QuizComboIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _entryController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _entryAnimation;
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
        tween: Tween(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
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

    if (widget.count >= 2) {
      _entryController.forward();
    }
  }

  @override
  void didUpdateWidget(QuizComboIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.count != _prevCount) {
      if (widget.count >= 2 && _prevCount < 2) {
        // Entering combo state — animate in
        _entryController.forward(from: 0);
        HapticFeedback.lightImpact();
      } else if (widget.count < 2 && _prevCount >= 2) {
        // Leaving combo state — animate out
        _entryController.reverse();
      } else if (widget.count > _prevCount && widget.count >= 2) {
        // Combo increased — pulse
        _pulseController.forward(from: 0);
        // Extra haptic at milestones
        if (_isMilestone(widget.count)) {
          HapticFeedback.mediumImpact();
        }
      }
    }
    _prevCount = widget.count;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  bool _isMilestone(int count) =>
      count == 3 || count == 5 || count == 7 || count == 10 || count % 5 == 0;

  // ── Visual tiers ───────────────────────────────────────────────────

  String _emoji(int count) {
    if (count >= 10) return '\u{1F3C6}'; // 🏆
    if (count >= 7) return '\u{26A1}'; // ⚡
    if (count >= 5) return '\u{1F525}'; // 🔥
    return '\u{1F4AA}'; // 💪
  }

  String _label(int count) {
    if (count >= 10) return 'LEGEND!';
    if (count >= 7) return 'Unstoppable!';
    if (count >= 5) return 'On fire!';
    if (count >= 3) return 'Nice streak!';
    return 'Combo!';
  }

  List<Color> _gradientColors(int count) {
    if (count >= 10) {
      return const [Color(0xFFF59E0B), Color(0xFFEF4444)]; // gold → red
    }
    if (count >= 7) {
      return const [Color(0xFFEF4444), Color(0xFFEC4899)]; // red → pink
    }
    if (count >= 5) {
      return const [Color(0xFFF97316), Color(0xFFEF4444)]; // orange → red
    }
    return const [Color(0xFF10B981), Color(0xFF06B6D4)]; // emerald → cyan
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.count;
    if (count < 2) {
      // Still keep widget in tree for exit animation
      return ScaleTransition(
        scale: _entryAnimation,
        child: const SizedBox(width: 0, height: 0),
      );
    }

    final gradient = _gradientColors(count);
    final emoji = _emoji(count);
    final label = _label(count);

    return ScaleTransition(
      scale: _entryAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
