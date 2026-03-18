import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/generation_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../courses/presentation/providers/course_provider.dart';

// =============================================================================
// Quiz Quick Create Sheet
// =============================================================================
//
// A bottom sheet for quickly generating a quiz. Lets the user:
//   1. Select a course from their course list.
//   2. Choose a question count via a slider (5-20, default 10).
//   3. Tap "Generate Quiz" to kick off background generation.
//
// Follows the same immersive dark visual style used throughout the app.
// =============================================================================

class QuizQuickCreateSheet extends ConsumerStatefulWidget {
  const QuizQuickCreateSheet({super.key});

  /// Show the quiz creation sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuizQuickCreateSheet(),
    );
  }

  @override
  ConsumerState<QuizQuickCreateSheet> createState() =>
      _QuizQuickCreateSheetState();
}

class _QuizQuickCreateSheetState extends ConsumerState<QuizQuickCreateSheet> {
  String? _selectedCourseId;
  String? _selectedCourseName;
  double _questionCount = 10;

  void _onGenerate() {
    if (_selectedCourseId == null || _selectedCourseName == null) return;

    HapticFeedback.mediumImpact();

    final started = ref
        .read(generationProvider.notifier)
        .generateQuiz(_selectedCourseId!, _selectedCourseName!);

    if (!started) {
      // A quiz generation is already running for this course
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A quiz is already being generated for this course.',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.immersiveCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
      return;
    }

    // Show feedback snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generating quiz...',
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.immersiveCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Pop the sheet
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.immersiveBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        bottomPadding + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ──
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Title ──
          Center(
            child: Text(
              'Generate Quiz',
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxs),

          Center(
            child: Text(
              'Create a quiz from your course materials',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Course selector ──
          Text(
            'COURSE',
            style: AppTypography.sectionHeader.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          coursesAsync.when(
            loading: () => _buildCourseDropdownPlaceholder(),
            error: (_, __) => _buildCourseDropdownError(),
            data: (courses) => _buildCourseDropdown(courses),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Question count slider ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUESTIONS',
                style: AppTypography.sectionHeader.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '${_questionCount.round()}',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.immersiveBorder,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
              ),
            ),
            child: Slider(
              value: _questionCount,
              min: 5,
              max: 20,
              divisions: 15,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _questionCount = value);
              },
            ),
          ),

          // Slider labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '5',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedDark,
                  ),
                ),
                Text(
                  '20',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Generate button ──
          TapScale(
            onTap: _selectedCourseId != null ? _onGenerate : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _selectedCourseId != null
                    ? AppColors.ctaLime
                    : AppColors.immersiveCard,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: _selectedCourseId != null
                      ? AppColors.ctaLime
                      : AppColors.immersiveBorder,
                ),
                boxShadow: _selectedCourseId != null
                    ? [
                        BoxShadow(
                          color: AppColors.ctaLime.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: _selectedCourseId != null
                        ? AppColors.ctaLimeText
                        : AppColors.textMutedDark,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Generate Quiz',
                    style: AppTypography.labelLarge.copyWith(
                      color: _selectedCourseId != null
                          ? AppColors.ctaLimeText
                          : AppColors.textMutedDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Course dropdown ──

  Widget _buildCourseDropdown(List<CourseModel> courses) {
    if (courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: Text(
          'No courses yet. Create a course first.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMutedDark,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _selectedCourseId != null
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.immersiveBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCourseId,
          hint: Text(
            'Select a course',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMutedDark,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondaryDark,
          ),
          isExpanded: true,
          dropdownColor: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          items: courses.map((course) {
            return DropdownMenuItem<String>(
              value: course.id,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: course.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      course.icon,
                      size: 16,
                      color: course.color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      course.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            HapticFeedback.selectionClick();
            final course = courses.firstWhere((c) => c.id == value);
            setState(() {
              _selectedCourseId = value;
              _selectedCourseName = course.displayTitle;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCourseDropdownPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.immersiveBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textMutedDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Loading courses...',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMutedDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseDropdownError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Failed to load courses',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
