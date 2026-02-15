import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';

/// Animated AI orb avatar with pulsating glow effect.
///
/// A circular gradient sphere with a breathing glow animation
/// used as the AI assistant identity in the chat header.
class AnimatedOrbAvatar extends StatefulWidget {
  final double size;

  const AnimatedOrbAvatar({super.key, this.size = 64});

  @override
  State<AnimatedOrbAvatar> createState() => _AnimatedOrbAvatarState();
}

class _AnimatedOrbAvatarState extends State<AnimatedOrbAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _glowAnim,
      builder: (context, _) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.orbAvatar,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: _glowAnim.value),
                blurRadius: 24,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: const Color(0xFFA5A7FA)
                    .withValues(alpha: _glowAnim.value * 0.5),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withValues(alpha: 0.9),
              size: widget.size * 0.4,
            ),
          ),
        );
      },
    );
  }
}
