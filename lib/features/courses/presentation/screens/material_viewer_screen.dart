import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/material_model.dart';
import '../providers/course_provider.dart';
import '../widgets/material_list_item.dart';

/// A beautiful full-screen viewer for course materials.
///
/// Shows the material content (extracted text, notes, paste) with a
/// premium glassmorphic design. Supports copy-to-clipboard, marking
/// as reviewed, and scrollable reading experience.
class MaterialViewerScreen extends ConsumerStatefulWidget {
  final String materialId;
  final String courseId;

  const MaterialViewerScreen({
    super.key,
    required this.materialId,
    required this.courseId,
  });

  @override
  ConsumerState<MaterialViewerScreen> createState() =>
      _MaterialViewerScreenState();
}

class _MaterialViewerScreenState extends ConsumerState<MaterialViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  bool _showCopied = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _copyContent(String content) {
    Clipboard.setData(ClipboardData(text: content));
    HapticFeedback.mediumImpact();
    setState(() => _showCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCopied = false);
    });
  }

  Future<void> _markReviewed(String materialId) async {
    HapticFeedback.lightImpact();
    await ref.read(materialRepositoryProvider).markReviewed(materialId);
    ref.invalidate(courseMaterialsProvider(widget.courseId));
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(courseMaterialsProvider(widget.courseId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Ethereal background gradients
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: -40,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),

          // Main content
          SafeArea(
            bottom: false,
            child: widget.courseId.isEmpty || widget.materialId.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: AppSpacing.md),
                        Text('Invalid material link',
                            style: AppTypography.bodyMedium),
                      ],
                    ),
                  )
                : materialsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (materials) {
                final matches = materials
                    .where((m) => m.id == widget.materialId);
                final MaterialModel? material =
                    matches.isNotEmpty ? matches.first : null;

                if (material == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: AppSpacing.md),
                        Text('Material not found',
                            style: AppTypography.bodyMedium),
                      ],
                    ),
                  );
                }

                return FadeTransition(
                  opacity: _fadeController,
                  child: _buildContent(context, material),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MaterialModel material) {
    final hasContent =
        material.content != null && material.content!.trim().isNotEmpty;
    final kind = _kindFromType(material.type);
    final typeColor = _colorForKind(kind);
    final typeIcon = _iconForKind(kind);

    return Column(
      children: [
        // Header bar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              TapScale(
                onTap: () => context.pop(),
                scaleDown: 0.90,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: AppColors.textSecondary),
                ),
              ),
              const Spacer(),
              if (hasContent) ...[
                // Copy button
                TapScale(
                  onTap: () => _copyContent(material.content!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _showCopied
                          ? AppColors.success.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: AppRadius.borderRadiusPill,
                      border: Border.all(
                        color: _showCopied
                            ? AppColors.success.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showCopied
                              ? Icons.check_rounded
                              : Icons.copy_rounded,
                          size: 16,
                          color: _showCopied
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showCopied ? 'Copied!' : 'Copy',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _showCopied
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              // Mark reviewed button
              if (!material.isReviewed)
                TapScale(
                  onTap: () => _markReviewed(material.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.borderRadiusPill,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mark Reviewed',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Material header card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  // Type icon badge
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 26),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GradientText(
                          material.title,
                          style: AppTypography.h2.copyWith(fontSize: 22),
                          gradient: AppGradients.textDark,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: AppRadius.borderRadiusPill,
                              ),
                              child: Text(
                                material.typeLabel,
                                style: AppTypography.caption.copyWith(
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (material.sizeLabel.isNotEmpty) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                material.sizeLabel,
                                style: AppTypography.caption,
                              ),
                            ],
                            if (material.isReviewed) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Icon(Icons.check_circle,
                                  size: 14, color: AppColors.success),
                              const SizedBox(width: 3),
                              Text(
                                'Reviewed',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (material.createdAt != null) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                _formatDate(material.createdAt!),
                                style: AppTypography.caption,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.textMuted.withValues(alpha: 0.15),
                  AppColors.textMuted.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Content area
        Expanded(
          child: hasContent
              ? _ContentReader(content: material.content!)
              : _EmptyContent(type: material.type, fileUrl: material.fileUrl),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  CourseMaterialKind _kindFromType(String type) {
    switch (type) {
      case 'pdf':
        return CourseMaterialKind.pdf;
      case 'audio':
        return CourseMaterialKind.audio;
      default:
        return CourseMaterialKind.notes;
    }
  }

  Color _colorForKind(CourseMaterialKind kind) => switch (kind) {
        CourseMaterialKind.pdf => AppColors.pdfRed,
        CourseMaterialKind.audio => AppColors.audioPurple,
        CourseMaterialKind.notes => AppColors.notesBlue,
      };

  IconData _iconForKind(CourseMaterialKind kind) => switch (kind) {
        CourseMaterialKind.pdf => Icons.picture_as_pdf_rounded,
        CourseMaterialKind.audio => Icons.headset_rounded,
        CourseMaterialKind.notes => Icons.edit_note_rounded,
      };
}

/// Scrollable content reader with glassmorphic card styling.
class _ContentReader extends StatelessWidget {
  final String content;

  const _ContentReader({required this.content});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderRadiusXxl,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: AppRadius.borderRadiusXxl,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SelectableText(
              content,
              style: AppTypography.bodyMedium.copyWith(
                height: 1.75,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty content state when material has no extracted text.
class _EmptyContent extends StatelessWidget {
  final String type;
  final String? fileUrl;

  const _EmptyContent({required this.type, this.fileUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textMuted.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.text_snippet_outlined,
                size: 36,
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No text content available',
              style: AppTypography.h4.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              type == 'pdf'
                  ? 'The PDF text extraction may still be processing.'
                  : type == 'audio'
                      ? 'The audio transcription may still be processing.'
                      : 'This material has no text content yet.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
