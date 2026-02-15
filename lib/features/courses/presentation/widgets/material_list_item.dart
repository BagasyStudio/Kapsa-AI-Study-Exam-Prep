import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Type of course material for icon/color differentiation.
enum CourseMaterialKind { pdf, audio, notes }

/// A material list item card for the Course Detail materials tab.
///
/// Shows icon, title, metadata, and optional "Generate Quiz" action.
class MaterialListItem extends StatelessWidget {
  final String title;
  final String timeLabel;
  final String typeLabel;
  final CourseMaterialKind kind;
  final bool isReviewed;
  final VoidCallback? onTap;
  final VoidCallback? onGenerateQuiz;
  final VoidCallback? onDelete;

  const MaterialListItem({
    super.key,
    required this.title,
    required this.timeLabel,
    required this.typeLabel,
    required this.kind,
    this.isReviewed = false,
    this.onTap,
    this.onGenerateQuiz,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = TapScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.borderRadiusLg,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: AppRadius.borderRadiusLg,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            child: Opacity(
              opacity: isReviewed ? 0.8 : 1.0,
              child: Column(
                children: [
                  // Top row: icon + info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _iconBgColor,
                          borderRadius: AppRadius.borderRadiusLg,
                        ),
                        child: Icon(_icon, color: _iconColor, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Title + metadata
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTypography.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Time/status
                                if (isReviewed)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 12,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Reviewed',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.schedule,
                                        size: 12,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeLabel,
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),

                                // Separator dot
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFD1D5DB),
                                  ),
                                ),

                                // Type label
                                Text(typeLabel, style: AppTypography.caption),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Action button (if not reviewed)
                  if (!isReviewed && onGenerateQuiz != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TapScale(
                        onTap: onGenerateQuiz,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.borderRadiusPill,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.psychology,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Generate Quiz',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (onDelete == null) return card;

    return Dismissible(
      key: ValueKey(title),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Material'),
            content: Text('Are you sure you want to delete "$title"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: AppRadius.borderRadiusLg,
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.error,
        ),
      ),
      child: card,
    );
  }

  Color get _iconBgColor => switch (kind) {
        CourseMaterialKind.pdf => const Color(0xFFFEE2E2),
        CourseMaterialKind.audio => const Color(0xFFF3E8FF),
        CourseMaterialKind.notes => const Color(0xFFDBEAFE),
      };

  Color get _iconColor => switch (kind) {
        CourseMaterialKind.pdf => AppColors.pdfRed,
        CourseMaterialKind.audio => AppColors.audioPurple,
        CourseMaterialKind.notes => AppColors.notesBlue,
      };

  IconData get _icon => switch (kind) {
        CourseMaterialKind.pdf => Icons.picture_as_pdf,
        CourseMaterialKind.audio => Icons.headset,
        CourseMaterialKind.notes => Icons.edit_note,
      };
}
