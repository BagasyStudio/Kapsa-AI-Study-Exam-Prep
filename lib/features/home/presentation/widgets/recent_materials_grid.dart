import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'material_thumbnail.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../../core/utils/error_handler.dart';

/// 2x2 grid of recent study materials on the Home screen.
class RecentMaterialsGrid extends ConsumerWidget {
  const RecentMaterialsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(recentMaterialsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT MATERIALS', style: AppTypography.sectionHeader),
        const SizedBox(height: AppSpacing.md),
        materialsAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 200,
            child: Center(
              child: Text(AppErrorHandler.friendlyMessage(e), style: AppTypography.bodySmall),
            ),
          ),
          data: (materials) {
            if (materials.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description,
                        size: 40,
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No materials yet',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use Capture to add study materials',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Show up to 3 items + "New Folder" placeholder
            final displayMaterials = materials.take(3).toList();

            return GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.82,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final material in displayMaterials)
                  MaterialThumbnail(
                    title: material.title,
                    subtitle: _timeAgo(material.createdAt),
                    type: _mapType(material.type),
                    onTap: () => context.push(
                      Routes.materialViewerPath(
                          material.courseId, material.id),
                    ),
                  ),
                // "New Folder" placeholder
                MaterialThumbnail(
                  title: 'New Folder',
                  subtitle: '',
                  type: StudyMaterialType.folder,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Create folder coming soon')),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  StudyMaterialType _mapType(String type) {
    switch (type) {
      case 'pdf':
      case 'notes':
      case 'paste':
        return StudyMaterialType.document;
      case 'audio':
        return StudyMaterialType.audio;
      default:
        return StudyMaterialType.document;
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
