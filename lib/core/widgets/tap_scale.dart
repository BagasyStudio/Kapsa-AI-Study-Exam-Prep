import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_animations.dart';

/// Wraps any widget with iOS-style press-down scale animation.
///
/// On tap down, the child scales to [scaleDown] (default 0.97).
/// On release, it springs back to 1.0 with a subtle bounce (easeOutBack).
/// Includes haptic feedback for a premium feel.
///
/// Usage:
/// ```dart
/// TapScale(
///   onTap: () => doSomething(),
///   child: MyCard(...),
/// )
/// ```
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Scale factor when pressed (default 0.97, lower = more dramatic).
  final double scaleDown;

  /// Whether to trigger haptic feedback on tap (default true).
  final bool enableHaptics;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.97,
    this.enableHaptics = true,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: _isPressed
            ? AppAnimations.durationFast
            : AppAnimations.durationMedium,
        curve: _isPressed ? Curves.easeOut : AppAnimations.curveBounce,
        child: widget.child,
      ),
    );
  }
}
