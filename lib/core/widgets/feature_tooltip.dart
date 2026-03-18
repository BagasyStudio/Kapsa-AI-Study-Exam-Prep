import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A one-time tooltip overlay that highlights a new feature.
///
/// Wraps a [child] widget and shows a tooltip message the first time
/// the widget is displayed. Uses SharedPreferences to persist the
/// "seen" state so the tooltip only appears once per feature.
///
/// Usage:
/// ```dart
/// FeatureTooltip(
///   featureId: 'swipe_ratings',
///   message: 'Swipe right for Good, left for Again!',
///   child: MyWidget(),
/// )
/// ```
class FeatureTooltip extends StatefulWidget {
  /// Unique identifier for this feature tooltip (stored in SharedPreferences).
  final String featureId;

  /// The tooltip message to display.
  final String message;

  /// The child widget to wrap.
  final Widget child;

  /// Whether the tooltip should appear above (true) or below (false) the child.
  final bool showAbove;

  const FeatureTooltip({
    super.key,
    required this.featureId,
    required this.message,
    required this.child,
    this.showAbove = true,
  });

  @override
  State<FeatureTooltip> createState() => _FeatureTooltipState();
}

class _FeatureTooltipState extends State<FeatureTooltip>
    with SingleTickerProviderStateMixin {
  bool _show = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _checkSeen();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'seen_tooltip_${widget.featureId}';
    if (prefs.getBool(key) == true) return;

    // Small delay so the parent layout is ready
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _show = true);
      _animController.forward();
    }
  }

  Future<void> _dismiss() async {
    await _animController.reverse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_tooltip_${widget.featureId}', true);
    if (mounted) setState(() => _show = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return widget.child;

    final tooltip = _buildTooltipBubble();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          left: 0,
          right: 0,
          bottom: widget.showAbove ? 0 : null,
          top: widget.showAbove ? null : 0,
          child: Transform.translate(
            offset: Offset(0, widget.showAbove ? -8 : 44),
            child: tooltip,
          ),
        ),
      ],
    );
  }

  Widget _buildTooltipBubble() {
    return GestureDetector(
      onTap: _dismiss,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          alignment:
              widget.showAbove ? Alignment.bottomCenter : Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.message,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Got it',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
