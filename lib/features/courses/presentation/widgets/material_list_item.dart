import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final int cardCount;
  final int quizCount;
  final VoidCallback? onTap;
  final VoidCallback? onGenerateQuiz;
  final VoidCallback? onDelete;
  final VoidCallback? onGenerateFlashcards;
  final VoidCallback? onAudioSummary;
  final VoidCallback? onPracticeQuiz;

  const MaterialListItem({
    super.key,
    required this.title,
    required this.timeLabel,
    required this.typeLabel,
    required this.kind,
    this.isReviewed = false,
    this.cardCount = 0,
    this.quizCount = 0,
    this.onTap,
    this.onGenerateQuiz,
    this.onDelete,
    this.onGenerateFlashcards,
    this.onAudioSummary,
    this.onPracticeQuiz,
  });

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 16),
              // Material title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                color: Colors.white.withValues(alpha: 0.08),
                height: 1,
              ),
              // Action items
              if (onGenerateFlashcards != null)
                _ContextMenuItem(
                  icon: Icons.style_rounded,
                  label: 'Generate Flashcards',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.pop(ctx);
                    onGenerateFlashcards?.call();
                  },
                ),
              if (onAudioSummary != null)
                _ContextMenuItem(
                  icon: Icons.headphones_rounded,
                  label: 'Audio Summary',
                  color: const Color(0xFF14B8A6),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAudioSummary?.call();
                  },
                ),
              if (onPracticeQuiz != null)
                _ContextMenuItem(
                  icon: Icons.quiz_rounded,
                  label: 'Practice Quiz',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.pop(ctx);
                    onPracticeQuiz?.call();
                  },
                ),
              if (onDelete != null) ...[
                Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  height: 1,
                ),
                _ContextMenuItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(context);
                  },
                ),
              ],
              const SizedBox(height: 8),
              // Cancel button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.immersiveCard,
        title: const Text('Delete Material', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "$title"?',
            style: const TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete?.call();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: TapScale(
      onTap: onTap,
      child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.immersiveCard,
              borderRadius: AppRadius.borderRadiusLg,
              border: Border.all(
                color: AppColors.immersiveBorder,
              ),
            ),
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
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                // Status chip
                                _StatusChip(
                                  icon: isReviewed
                                      ? Icons.check_circle
                                      : Icons.schedule,
                                  label: isReviewed ? 'Reviewed' : timeLabel,
                                  color: isReviewed
                                      ? AppColors.success
                                      : Colors.white38,
                                ),

                                // Type chip
                                _StatusChip(
                                  icon: _icon,
                                  label: typeLabel,
                                  color: _iconColor,
                                ),

                                // Flashcard count chip
                                if (cardCount > 0)
                                  _StatusChip(
                                    icon: Icons.style_rounded,
                                    label: '$cardCount cards',
                                    color: const Color(0xFF3B82F6),
                                  ),

                                // Quiz count chip
                                if (quizCount > 0)
                                  _StatusChip(
                                    icon: Icons.quiz_rounded,
                                    label: '$quizCount quiz${quizCount > 1 ? 'zes' : ''}',
                                    color: const Color(0xFF10B981),
                                  ),
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
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Generate Quiz',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
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
    );

    if (onDelete == null) return card;

    return Dismissible(
      key: ValueKey(title),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.immersiveCard,
            title: const Text('Delete Material', style: TextStyle(color: Colors.white)),
            content: Text('Are you sure you want to delete "$title"?',
                style: const TextStyle(color: Colors.white60)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
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
        CourseMaterialKind.pdf => AppColors.pdfRed.withValues(alpha: 0.12),
        CourseMaterialKind.audio => AppColors.audioPurple.withValues(alpha: 0.12),
        CourseMaterialKind.notes => AppColors.notesBlue.withValues(alpha: 0.12),
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

/// Compact status chip for material metadata.
class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action item row for the long-press context menu bottom sheet.
class _ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
