import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Floating glass toolbar at the bottom of the flashcard session.
///
/// Contains refresh, edit, and share icon buttons.
class FloatingToolbar extends StatelessWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onSpeak;
  final bool isSpeaking;

  const FloatingToolbar({
    super.key,
    this.onRefresh,
    this.onEdit,
    this.onShare,
    this.onSpeak,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolbarButton(icon: Icons.refresh, onTap: onRefresh),
              _Divider(),
              _ToolbarButton(icon: Icons.edit, onTap: onEdit),
              _Divider(),
              _ToolbarButton(
                icon: isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                onTap: onSpeak,
                isActive: isSpeaking,
              ),
              _Divider(),
              _ToolbarButton(icon: Icons.share, onTap: onShare),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;

  const _ToolbarButton({required this.icon, this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return TapScale(
      onTap: onTap,
      scaleDown: 0.85,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Icon(
          icon,
          size: 22,
          color: isActive
              ? AppColors.primary
              : AppColors.textSecondaryFor(brightness),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: isDark
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.1),
    );
  }
}
