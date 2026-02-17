import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'focus_flow_card.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../../core/utils/error_handler.dart';

/// Horizontal scrollable carousel of Focus Flow cards.
///
/// Uses PageView with viewportFraction 0.85 for the peek effect.
/// Applies scale and opacity transitions so the non-active card
/// peeks at 70% opacity and 95% scale (matching the HTML mockup).
class FocusFlowCarousel extends ConsumerStatefulWidget {
  const FocusFlowCarousel({super.key});

  @override
  ConsumerState<FocusFlowCarousel> createState() => _FocusFlowCarouselState();
}

class _FocusFlowCarouselState extends ConsumerState<FocusFlowCarousel> {
  late final PageController _controller;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.85);
    _controller.addListener(() {
      setState(() {
        _currentPage = _controller.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FOCUS FLOW',
                style: AppTypography.sectionHeader,
              ),
              TapScale(
                onTap: () => context.go(Routes.courses),
                child: Text(
                  'See all',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Card carousel
        SizedBox(
          height: 380,
          child: coursesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(AppErrorHandler.friendlyMessage(e), style: AppTypography.bodySmall),
            ),
            data: (courses) {
              if (courses.isEmpty) {
                return Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school,
                            size: 48,
                            color: AppColors.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No courses yet',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Create your first course to get started!',
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

              // Show up to 5 courses in carousel
              final displayCourses = courses.take(5).toList();
              return PageView.builder(
                controller: _controller,
                clipBehavior: Clip.none,
                itemCount: displayCourses.length,
                itemBuilder: (context, index) {
                  final course = displayCourses[index];
                  final diff =
                      (index - _currentPage).abs().clamp(0.0, 1.0);
                  final scale = 1.0 - (diff * 0.05);
                  final opacity = 1.0 - (diff * 0.30);

                  final hasExam = course.examDate != null;
                  final tag = hasExam ? 'Exam Coming' : 'In Progress';
                  final tagColor = hasExam
                      ? const Color(0xFFFEF3C7).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.5);
                  final tagTextColor = hasExam
                      ? const Color(0xFFEA580C)
                      : AppColors.primary;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        alignment: index < _currentPage
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: FocusFlowCard(
                          tag: tag,
                          tagColor: tagColor,
                          tagTextColor: tagTextColor,
                          title: course.title,
                          subtitle: course.subtitle ?? '',
                          progress: course.progress,
                          ctaLabel: 'Continue',
                          isSecondary: index > 0,
                          onCtaTap: () => context
                              .push(Routes.courseDetailPath(course.id)),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
