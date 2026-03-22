import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../providers/home_state_provider.dart';

/// Horizontal scrollable pills to switch between courses on the home screen.
/// Hidden when the user has only one course.
class HomeCourseSelector extends ConsumerWidget {
  const HomeCourseSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider).valueOrNull ?? [];
    if (courses.length <= 1) return const SizedBox.shrink();

    final activeId = ref.watch(activeHomeCourseIdProvider);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final course = courses[index];
          final isActive = course.id == activeId;
          return _CoursePill(
            course: course,
            isActive: isActive,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(selectedHomeCourseIdProvider.notifier).state = course.id;
            },
          );
        },
      ),
    );
  }
}

class _CoursePill extends StatelessWidget {
  final CourseModel course;
  final bool isActive;
  final VoidCallback onTap;

  const _CoursePill({
    required this.course,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(course.colorHex);

    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.4) : AppColors.immersiveBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _courseIcon(course.iconName),
              color: isActive ? color : Colors.white38,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              course.title,
              style: AppTypography.labelMedium.copyWith(
                color: isActive ? color : Colors.white54,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  static IconData _courseIcon(String name) {
    const icons = {
      'book': Icons.menu_book_rounded,
      'science': Icons.science_rounded,
      'math': Icons.calculate_rounded,
      'code': Icons.code_rounded,
      'law': Icons.gavel_rounded,
      'medicine': Icons.medical_services_rounded,
      'art': Icons.palette_rounded,
      'language': Icons.translate_rounded,
      'music': Icons.music_note_rounded,
      'history': Icons.history_edu_rounded,
      'economics': Icons.trending_up_rounded,
      'psychology': Icons.psychology_rounded,
    };
    return icons[name] ?? Icons.menu_book_rounded;
  }
}
