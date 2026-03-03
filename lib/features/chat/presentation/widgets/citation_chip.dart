import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// A citation reference chip shown below AI messages.
///
/// Displays a source name with a smart icon based on the file type,
/// indicating the material from which the AI sourced its response.
class CitationChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const CitationChip({
    super.key,
    required this.label,
    this.onTap,
  });

  /// Returns the appropriate icon and color based on the file extension in [label].
  ({IconData icon, Color color}) _iconForLabel() {
    final lower = label.toLowerCase();

    if (lower.contains('.pdf')) {
      return (icon: Icons.picture_as_pdf, color: AppColors.pdfRed);
    }
    if (lower.contains('.mp3') ||
        lower.contains('.wav') ||
        lower.contains('.m4a') ||
        lower.contains('audio')) {
      return (icon: Icons.audiotrack, color: AppColors.audioPurple);
    }
    if (lower.contains('.jpg') ||
        lower.contains('.png') ||
        lower.contains('.jpeg')) {
      return (icon: Icons.image_outlined, color: AppColors.notesBlue);
    }

    return (icon: Icons.edit_note, color: AppColors.primary);
  }

  @override
  Widget build(BuildContext context) {
    final (:icon, :color) = _iconForLabel();

    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
