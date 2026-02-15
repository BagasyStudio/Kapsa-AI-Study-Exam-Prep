import 'package:flutter/material.dart';

/// Wraps a message bubble with a scale + fade entrance animation.
///
/// Each message appears to "pop in" from a slightly smaller scale,
/// creating a lively chat experience.
class MessageBubbleEntrance extends StatefulWidget {
  final Widget child;
  final bool fromLeft; // AI messages come from left, user from right

  const MessageBubbleEntrance({
    super.key,
    required this.child,
    this.fromLeft = true,
  });

  @override
  State<MessageBubbleEntrance> createState() => _MessageBubbleEntranceState();
}

class _MessageBubbleEntranceState extends State<MessageBubbleEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.fromLeft ? -0.15 : 0.15, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: widget.fromLeft
              ? Alignment.bottomLeft
              : Alignment.bottomRight,
          child: widget.child,
        ),
      ),
    );
  }
}
