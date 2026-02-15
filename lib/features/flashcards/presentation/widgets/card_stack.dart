import 'package:flutter/material.dart';

/// Swipe direction result.
enum SwipeDirection { left, right }

/// Custom card stack with swipe-to-dismiss gesture.
///
/// Displays 3 layers: 2 background cards at slight rotations + 1 front card.
/// Pan gesture on the front card translates/rotates it. Past threshold,
/// it animates off-screen and triggers [onSwiped]. Left = "Study Again",
/// Right = "Mastered".
class CardStack extends StatefulWidget {
  final Widget frontCard;
  final VoidCallback? onTap;
  final ValueChanged<SwipeDirection>? onSwiped;

  /// 0.0 to 1.0 opacity for left (red) and right (green) swipe indicators.
  final ValueChanged<double>? onSwipeProgress;

  const CardStack({
    super.key,
    required this.frontCard,
    this.onTap,
    this.onSwiped,
    this.onSwipeProgress,
  });

  @override
  State<CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<CardStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;

  static const _swipeThreshold = 120.0;
  static const _maxRotation = 0.3; // radians (~17 degrees)

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _animController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = _dragOffset.dx / 600 * _maxRotation;
    });
    // Report swipe progress (-1 to 1) clamped
    final progress = (_dragOffset.dx / _swipeThreshold).clamp(-1.0, 1.0);
    widget.onSwipeProgress?.call(progress);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragOffset.dx.abs() > _swipeThreshold) {
      // Swiped past threshold — animate off screen
      final direction =
          _dragOffset.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
      _animateOffScreen(direction);
    } else {
      // Snap back
      _snapBack();
    }
  }

  void _animateOffScreen(SwipeDirection direction) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX =
        direction == SwipeDirection.right ? screenWidth * 1.5 : -screenWidth * 1.5;
    final targetAngle =
        direction == SwipeDirection.right ? _maxRotation : -_maxRotation;

    final startOffset = _dragOffset;
    final startAngle = _dragAngle;

    _animController.reset();
    _animController.duration = const Duration(milliseconds: 300);

    final animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    animation.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(
          startOffset,
          Offset(targetX, startOffset.dy - 50),
          animation.value,
        )!;
        _dragAngle = lerpDouble(startAngle, targetAngle, animation.value)!;
      });
    });

    _animController.forward().then((_) {
      // Reset and notify
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0;
      });
      widget.onSwipeProgress?.call(0);
      widget.onSwiped?.call(direction);
    });
  }

  void _snapBack() {
    final startOffset = _dragOffset;
    final startAngle = _dragAngle;

    _animController.reset();
    _animController.duration = const Duration(milliseconds: 400);

    final animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    animation.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(
          startOffset,
          Offset.zero,
          animation.value,
        )!;
        _dragAngle = lerpDouble(startAngle, 0, animation.value)!;
      });
    });

    _animController.forward().then((_) {
      widget.onSwipeProgress?.call(0);
    });
  }

  double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Back card 2 (deepest)
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(-0.05)
            ..scale(0.90),
          child: Opacity(
            opacity: 0.3,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
        ),

        // Back card 1 (middle)
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(0.03)
            ..scale(0.95),
          child: Opacity(
            opacity: 0.5,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
        ),

        // Front card (interactive)
        GestureDetector(
          onTap: widget.onTap,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(_dragOffset.dx, _dragOffset.dy)
              ..rotateZ(_dragAngle),
            child: widget.frontCard,
          ),
        ),
      ],
    );
  }
}
