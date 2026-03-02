import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../capture/presentation/screens/capture_sheet.dart';

/// Quick action buttons row on the home screen.
/// 4 circular buttons: Snap & Solve, Quick Quiz, SRS Review, New Capture.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickAction(
            icon: Icons.camera_alt_rounded,
            label: 'Snap Solve',
            color: const Color(0xFFF59E0B),
            onTap: () => context.push(Routes.snapSolve),
          ),
          _QuickAction(
            icon: Icons.bolt,
            label: 'Oracle',
            color: const Color(0xFF8B5CF6),
            onTap: () => context.push(Routes.oracle),
          ),
          _QuickAction(
            icon: Icons.groups_rounded,
            label: 'Groups',
            color: const Color(0xFF3B82F6),
            onTap: () => context.push(Routes.groupsList),
          ),
          _QuickAction(
            icon: Icons.add_rounded,
            label: 'Capture',
            color: const Color(0xFF10B981),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useRootNavigator: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.black.withValues(alpha: 0.3),
              builder: (_) => const CaptureSheet(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return TapScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryFor(brightness),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
