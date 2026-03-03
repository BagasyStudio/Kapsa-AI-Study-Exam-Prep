import 'package:flutter/material.dart';

/// Reveals text character by character in a typewriter effect.
///
/// The animation starts when [animate] is true and plays once.
/// Optionally calls [onCharTyped] for each new character (haptic feedback, etc.)
/// and shows a blinking cursor while typing.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool animate;
  final Duration charDelay;
  final Duration startDelay;

  /// Called each time a new visible character is revealed.
  /// Useful for triggering haptic feedback per keystroke.
  final VoidCallback? onCharTyped;

  /// Whether to show a blinking cursor at the end of the revealed text.
  final bool showCursor;

  /// Color of the blinking cursor. Defaults to primary color.
  final Color? cursorColor;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.center,
    this.animate = true,
    this.charDelay = const Duration(milliseconds: 30),
    this.startDelay = Duration.zero,
    this.onCharTyped,
    this.showCursor = false,
    this.cursorColor,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  AnimationController? _cursorController;
  bool _started = false;
  int _previousCharCount = 0;
  bool _isComplete = false;

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

    if (widget.showCursor) {
      _cursorController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 530),
      )..repeat(reverse: true);
    }

    _controller.addListener(_onAnimationTick);
    _controller.addStatusListener(_onAnimationStatus);

    if (widget.animate) _start();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_started) _start();
  }

  void _onAnimationTick() {
    if (widget.onCharTyped == null) return;
    final charCount = (widget.text.length * _controller.value).floor();
    if (charCount > _previousCharCount) {
      // Only fire for visible characters (not whitespace)
      final newChar = widget.text[charCount - 1];
      if (newChar.trim().isNotEmpty) {
        widget.onCharTyped!();
      }
      _previousCharCount = charCount;
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() => _isComplete = true);
      // Hide cursor after a brief pause
      if (widget.showCursor) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _cursorController?.stop();
          if (mounted) setState(() {});
        });
      }
    }
  }

  Future<void> _start() async {
    _started = true;
    _previousCharCount = 0;
    _isComplete = false;
    if (widget.startDelay > Duration.zero) {
      await Future.delayed(widget.startDelay);
    }
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimationTick);
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    _cursorController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final charCount =
            (widget.text.length * _controller.value).floor();
        final revealedText = widget.text.substring(0, charCount);

        if (!widget.showCursor || (_isComplete && !(_cursorController?.isAnimating ?? false))) {
          return Text(
            revealedText,
            style: widget.style,
            textAlign: widget.textAlign,
          );
        }

        // Show text with blinking cursor
        return AnimatedBuilder(
          animation: _cursorController!,
          builder: (context, _) {
            final cursorOpacity = _cursorController!.value;
            final cursorColor = widget.cursorColor ??
                Theme.of(context).colorScheme.primary;

            return Text.rich(
              TextSpan(
                text: revealedText,
                style: widget.style,
                children: [
                  TextSpan(
                    text: '\u258E',
                    style: widget.style?.copyWith(
                      color: cursorColor.withValues(alpha: cursorOpacity * 0.8),
                      fontWeight: FontWeight.w300,
                    ) ?? TextStyle(
                      color: cursorColor.withValues(alpha: cursorOpacity * 0.8),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
              textAlign: widget.textAlign,
            );
          },
        );
      },
    );
  }
}
