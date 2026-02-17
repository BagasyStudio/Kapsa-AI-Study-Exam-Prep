import 'package:flutter/material.dart';
import '../theme/app_animations.dart';

/// A Column whose children fade + slide in sequentially on first build.
///
/// Drop-in replacement for [Column] that adds staggered entrance animations.
/// Each child appears with a [staggerDelay] offset from the previous one.
/// Animates only once on first build (not on rebuilds).
///
/// Usage:
/// ```dart
/// StaggeredColumn(
///   children: [
///     Text('First'),  // appears at 0ms
///     Text('Second'), // appears at 60ms
///     Text('Third'),  // appears at 120ms
///   ],
/// )
/// ```
class StaggeredColumn extends StatefulWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  /// Duration each item takes to animate in (default 500ms).
  final Duration itemDuration;

  /// Delay between consecutive items (default 60ms).
  final Duration staggerDelay;

  /// Direction to slide from. Positive Y = slides up from below.
  final Offset slideOffset;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.itemDuration = AppAnimations.durationEntrance,
    this.staggerDelay = AppAnimations.staggerInterval,
    this.slideOffset = const Offset(0, 20),
  });

  @override
  State<StaggeredColumn> createState() => _StaggeredColumnState();
}

class _StaggeredColumnState extends State<StaggeredColumn>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  @override
  void didUpdateWidget(StaggeredColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      final oldCount = _controllers.length;
      final newCount = widget.children.length;

      if (newCount > oldCount) {
        // Add controllers for new children
        for (int i = oldCount; i < newCount; i++) {
          final controller = AnimationController(
            vsync: this,
            duration: widget.itemDuration,
          );
          _controllers.add(controller);
          _fadeAnimations.add(CurvedAnimation(
            parent: controller,
            curve: AppAnimations.curveEntrance,
          ));
          _slideAnimations.add(Tween<Offset>(
            begin: widget.slideOffset,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: AppAnimations.curveEntrance,
          )));

          // Animate new items in
          if (i >= AppAnimations.maxStaggerItems) {
            controller.value = 1.0;
          } else {
            final delay = widget.staggerDelay * (i - oldCount);
            Future.delayed(delay, () {
              if (mounted) controller.forward();
            });
          }
        }
      } else if (newCount < oldCount) {
        // Remove excess controllers
        for (int i = oldCount - 1; i >= newCount; i--) {
          _controllers[i].dispose();
          _controllers.removeAt(i);
          _fadeAnimations.removeAt(i);
          _slideAnimations.removeAt(i);
        }
      }
    }
  }

  void _initAnimations() {
    final count = widget.children.length;
    _controllers = List.generate(count, (i) {
      return AnimationController(
        vsync: this,
        duration: widget.itemDuration,
      );
    });

    _fadeAnimations = _controllers.map((c) {
      return CurvedAnimation(
        parent: c,
        curve: AppAnimations.curveEntrance,
      );
    }).toList();

    _slideAnimations = _controllers.map((c) {
      return Tween<Offset>(
        begin: widget.slideOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: c,
        curve: AppAnimations.curveEntrance,
      ));
    }).toList();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      final delay = widget.staggerDelay * i;
      if (i >= AppAnimations.maxStaggerItems) {
        // Items beyond max stagger appear instantly
        _controllers[i].value = 1.0;
      } else {
        Future.delayed(delay, () {
          if (mounted) _controllers[i].forward();
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      mainAxisAlignment: widget.mainAxisAlignment,
      mainAxisSize: widget.mainAxisSize,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          AnimatedBuilder(
            animation: _controllers[i],
            builder: (context, _) {
              return Transform.translate(
                offset: _slideAnimations[i].value,
                child: Opacity(
                  opacity: _fadeAnimations[i].value,
                  child: widget.children[i],
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Animates a single widget with fade + slide on first build.
///
/// For use inside [ListView.builder] or similar dynamic lists.
/// The [index] determines the stagger delay.
///
/// Usage:
/// ```dart
/// ListView.builder(
///   itemBuilder: (context, index) => EntranceAnimation(
///     index: index,
///     child: MyListTile(...),
///   ),
/// )
/// ```
class EntranceAnimation extends StatefulWidget {
  final Widget child;

  /// Position in the list, used to calculate stagger delay.
  final int index;

  /// Duration of the animation (default 500ms).
  final Duration duration;

  /// Delay between items (default 60ms).
  final Duration staggerDelay;

  /// Direction to slide from. Positive Y = slides up from below.
  final Offset slideFrom;

  const EntranceAnimation({
    super.key,
    required this.child,
    required this.index,
    this.duration = AppAnimations.durationEntrance,
    this.staggerDelay = AppAnimations.staggerInterval,
    this.slideFrom = const Offset(0, 20),
  });

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveEntrance,
    );

    _slide = Tween<Offset>(
      begin: widget.slideFrom,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveEntrance,
    ));

    if (widget.index >= AppAnimations.maxStaggerItems) {
      _controller.value = 1.0;
    } else {
      final delay = widget.staggerDelay * widget.index;
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.translate(
          offset: _slide.value,
          child: Opacity(
            opacity: _fade.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
