import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated aurora gradient background used on the Home screen.
///
/// Mimics the CSS: `background: linear-gradient(-45deg, ...); background-size: 400% 400%;`
/// The oversized gradient slowly pans across, creating the aurora breathing effect.
class AuroraBackground extends StatefulWidget {
  final Widget child;

  const AuroraBackground({super.key, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
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
      builder: (context, child) {
        final t = _controller.value;

        // Simulate CSS background-size: 400% 400% with gradient-position animation.
        // Move the begin/end points across a much wider range to create
        // the feeling that the gradient is much larger than the viewport.
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // -45deg diagonal shifting
              begin: Alignment.lerp(
                const Alignment(-1.5, -1.5),
                const Alignment(1.5, -0.5),
                t,
              )!,
              end: Alignment.lerp(
                const Alignment(1.5, 1.5),
                const Alignment(-1.5, 0.5),
                t,
              )!,
              // Repeat the color stops to simulate the 400% oversized gradient
              colors: const [
                AppColors.auroraLavender,
                AppColors.auroraBlue,
                AppColors.auroraSky,
                AppColors.auroraPink,
                AppColors.auroraLavender,
                AppColors.auroraBlue,
              ],
              stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
