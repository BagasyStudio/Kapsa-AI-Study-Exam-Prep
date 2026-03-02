import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../providers/test_provider.dart';

/// Setup screen for Practice Exam mode.
///
/// Allows users to select a course, number of questions, and time limit
/// before starting a timed exam simulation.
class PracticeExamSetupScreen extends ConsumerStatefulWidget {
  const PracticeExamSetupScreen({super.key});

  @override
  ConsumerState<PracticeExamSetupScreen> createState() =>
      _PracticeExamSetupScreenState();
}

class _PracticeExamSetupScreenState
    extends ConsumerState<PracticeExamSetupScreen> {
  String? _selectedCourseId;
  int _questionCount = 10;
  int? _timeLimitMinutes; // null = no limit
  bool _isGenerating = false;

  static const _questionOptions = [5, 10, 15, 20];
  static const _timeOptions = <int?>[15, 30, 60, null];
  static const _timeLabels = ['15 min', '30 min', '60 min', 'No Limit'];

  Future<void> _startExam() async {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Check feature access
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'quiz',
      context: context,
    );
    if (!canUse || !mounted) return;

    setState(() => _isGenerating = true);
    HapticFeedback.mediumImpact();

    try {
      final result = await ref.read(testRepositoryProvider).generateQuiz(
            courseId: _selectedCourseId!,
            count: _questionCount,
          );

      await recordFeatureUsage(ref: ref, feature: 'quiz');

      if (!mounted) return;

      // Navigate to quiz session with time limit
      final uri = Uri(
        path: '/quiz-session/${result.test.id}',
        queryParameters: {
          if (_timeLimitMinutes != null)
            'timeLimit': _timeLimitMinutes.toString(),
          'isPracticeExam': 'true',
        },
      );
      context.pushReplacement(uri.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      AppErrorHandler.showError(e, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.darkImmersive),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.xl, 0,
                ),
                child: Row(
                  children: [
                    TapScale(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: Icon(Icons.arrow_back,
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Practice Exam',
                      style: AppTypography.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Course Selection ──
                      _SectionLabel(label: 'SELECT COURSE'),
                      const SizedBox(height: AppSpacing.sm),
                      coursesAsync.when(
                        loading: () => Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        error: (e, _) => Text(
                          AppErrorHandler.friendlyMessage(e),
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        data: (courses) {
                          if (courses.isEmpty) {
                            return Text(
                              'Create a course first to take a practice exam.',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            );
                          }
                          return _CourseSelector(
                            courses: courses,
                            selectedId: _selectedCourseId,
                            onSelect: (id) =>
                                setState(() => _selectedCourseId = id),
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Question Count ──
                      _SectionLabel(label: 'NUMBER OF QUESTIONS'),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: _questionOptions.map((count) {
                          final isSelected = _questionCount == count;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: count != _questionOptions.last ? 8 : 0,
                              ),
                              child: TapScale(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _questionCount = count);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF6467F2),
                                              Color(0xFF8B5CF6),
                                            ],
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : Colors.white
                                              .withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Time Limit ──
                      _SectionLabel(label: 'TIME LIMIT'),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children:
                            List.generate(_timeOptions.length, (i) {
                          final time = _timeOptions[i];
                          final isSelected = _timeLimitMinutes == time;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: i != _timeOptions.length - 1 ? 8 : 0,
                              ),
                              child: TapScale(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _timeLimitMinutes = time);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF6467F2),
                                              Color(0xFF8B5CF6),
                                            ],
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : Colors.white
                                              .withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _timeLabels[i],
                                      style: AppTypography.caption.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: AppSpacing.xxl * 2),

                      // ── Summary ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Questions',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                                Text(
                                  '$_questionCount',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Time Limit',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                                Text(
                                  _timeLimitMinutes != null
                                      ? '$_timeLimitMinutes min'
                                      : 'No Limit',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Start Button ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  MediaQuery.of(context).padding.bottom + AppSpacing.md,
                ),
                child: _isGenerating
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6467F2),
                              Color(0xFF8B5CF6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : TapScale(
                        onTap: _startExam,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6467F2),
                                Color(0xFF8B5CF6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Start Exam',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: Colors.white.withValues(alpha: 0.4),
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        fontSize: 11,
      ),
    );
  }
}

class _CourseSelector extends StatelessWidget {
  final List<CourseModel> courses;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _CourseSelector({
    required this.courses,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: courses.map((course) {
        final isSelected = course.id == selectedId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TapScale(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(course.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: course.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(course.icon, size: 20, color: course.color),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (course.subtitle != null)
                          Text(
                            course.subtitle!,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle,
                        color: AppColors.primary, size: 22)
                  else
                    Icon(Icons.circle_outlined,
                        color: Colors.white.withValues(alpha: 0.2), size: 22),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
