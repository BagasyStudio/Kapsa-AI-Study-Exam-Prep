import 'package:flutter/material.dart';

/// Wraps a child and shakes it horizontally on error.
///
/// Call [ShakeWidgetState.shake()] to trigger the shake animation.
/// Use with a GlobalKey to access the state.
///
/// ```dart
/// final _shakeKey = GlobalKey<ShakeWidgetState>();
/// ShakeWidget(key: _shakeKey, child: myField);
/// _shakeKey.currentState?.shake();
/// ```
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final double shakeOffset;

  const ShakeWidget({
    super.key,
    required this.child,
    this.shakeOffset = 10.0,
  });

  @override
  ShakeWidgetState createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -1, end: 1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1, end: -0.6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.6, end: 0.4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void shake() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * widget.shakeOffset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
