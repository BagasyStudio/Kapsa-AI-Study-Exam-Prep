import 'package:flutter/material.dart';
import '../theme/app_animations.dart';

/// Animates a number counting up from 0 (or [begin]) to [value].
///
/// Great for stats, scores, and progress displays.
/// Uses deceleration curve for a satisfying "landing" feel.
class AnimatedCounter extends StatelessWidget {
  final int value;
  final int begin;
  final Duration duration;
  final TextStyle? style;
  final String? suffix;
  final String? prefix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.begin = 0,
    this.duration = AppAnimations.durationLong,
    this.style,
    this.suffix,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: begin, end: value),
      duration: duration,
      curve: AppAnimations.curveDecelerate,
      builder: (context, val, _) {
        return Text(
          '${prefix ?? ''}$val${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}
