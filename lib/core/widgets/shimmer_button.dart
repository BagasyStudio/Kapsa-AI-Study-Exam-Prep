import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import 'tap_scale.dart';

/// Primary CTA with a traveling shimmer highlight.
///
/// A gradient sweep moves across the button every ~3 seconds, drawing
/// the user's eye to the most important action on the screen.
///
/// Usage:
/// ```dart
/// ShimmerButton(
///   label: 'Generate Flashcards',
///   icon: Icons.auto_awesome,
///   onPressed: () => ...,
/// )
/// ```
class ShimmerButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final List<Color>? gradientColors;
  final double height;

  const ShimmerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.gradientColors,
    this.height = 54,
  });

  @override
  State<ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<ShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Delay first shimmer slightly so the button appears stable first
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _shimmerController.repeat();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ??
        [const Color(0xFF6467F2), const Color(0xFF8B5CF6)];

    return TapScale(
      onTap: widget.onPressed != null
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      scaleDown: 0.96,
      child: AnimatedBuilder(
        animation: _shimmerAnim,
        builder: (context, child) {
          return Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: AppRadius.borderRadiusPill,
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shimmer sweep overlay — simple gradient layer
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: AppRadius.borderRadiusPill,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            begin: Alignment(_shimmerAnim.value - 0.3, 0),
                            end: Alignment(_shimmerAnim.value + 0.3, 0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                Row(
                  mainAxisSize:
                      widget.expanded ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: AppTypography.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
