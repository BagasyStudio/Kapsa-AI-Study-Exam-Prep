import 'package:flutter/material.dart';

/// Reveals text character by character in a typewriter effect.
///
/// The animation starts when [animate] is true and plays once.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool animate;
  final Duration charDelay;
  final Duration startDelay;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.center,
    this.animate = true,
    this.charDelay = const Duration(milliseconds: 30),
    this.startDelay = Duration.zero,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final totalDuration = Duration(
      milliseconds: widget.text.length * widget.charDelay.inMilliseconds,
    );
    _controller = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    if (widget.animate) _start();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_started) _start();
  }

  Future<void> _start() async {
    _started = true;
    if (widget.startDelay > Duration.zero) {
      await Future.delayed(widget.startDelay);
    }
    if (mounted) _controller.forward();
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
        final charCount =
            (widget.text.length * _controller.value).floor();
        return Text(
          widget.text.substring(0, charCount),
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}
