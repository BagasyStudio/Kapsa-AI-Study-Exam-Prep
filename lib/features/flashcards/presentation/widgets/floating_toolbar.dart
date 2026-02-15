import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Floating glass toolbar at the bottom of the flashcard session.
///
/// Contains refresh, edit, and share icon buttons.
class FloatingToolbar extends StatelessWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;

  const FloatingToolbar({
    super.key,
    this.onRefresh,
    this.onEdit,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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

  const _ToolbarButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      scaleDown: 0.85,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Icon(
          icon,
          size: 22,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}
