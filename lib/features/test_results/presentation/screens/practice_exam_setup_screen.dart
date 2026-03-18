import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/shimmer_button.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../providers/test_provider.dart';

/// Setup screen for Practice Exam mode.
///
/// Allows users to select a course, number of questions, and time limit
/// before starting a timed exam simulation.
class PracticeExamSetupScreen extends ConsumerStatefulWidget {
  final String? initialCourseId;

  const PracticeExamSetupScreen({super.key, this.initialCourseId});

  @override
  ConsumerState<PracticeExamSetupScreen> createState() =>
      _PracticeExamSetupScreenState();
}

/// Exam mode determines quiz session behaviour.
enum ExamMode {
  /// Linear progression, all questions in order.
  standard,

  /// Shows correct answer after each question for learning.
  review,

  /// Timer is stricter (75% of selected time).
  challenge,
}

class _PracticeExamSetupScreenState
    extends ConsumerState<PracticeExamSetupScreen> {
  late String? _selectedCourseId = widget.initialCourseId;
  double _questionCount = 10;
  int? _timeLimitMinutes; // null = no limit
  double _goalPercent = 80; // UX-82: Pre-exam goal setting (50-100, step 5)
  ExamMode _selectedExamMode = ExamMode.standard; // UX-81: Exam format selector
  bool _isGenerating = false;

  static const _timeOptions = <int?>[15, 30, 60, null];

  Future<void> _startExam() async {
    final l = AppLocalizations.of(context)!;
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.practiceExamSelectCourseFirst),
          backgroundColor: const Color(0xFFEF4444),
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
            count: _questionCount.round(),
            isPracticeExam: true,
          );

      await recordFeatureUsage(ref: ref, feature: 'quiz');

      if (!mounted) return;

      // Navigate to quiz session with time limit, goal, and exam mode
      // Challenge mode applies 75% of the selected time limit
      final effectiveTimeLimit = _selectedExamMode == ExamMode.challenge &&
              _timeLimitMinutes != null
          ? (_timeLimitMinutes! * 0.75).round()
          : _timeLimitMinutes;

      final uri = Uri(
        path: '/quiz-session/${result.test.id}',
        queryParameters: {
          if (effectiveTimeLimit != null)
            'timeLimit': effectiveTimeLimit.toString(),
          'isPracticeExam': 'true',
          'goal': _goalPercent.round().toString(),
          'examMode': _selectedExamMode.name,
        },
      );
      context.pushReplacement(uri.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      AppErrorHandler.showError(e, context: context);
    }
  }

  List<String> _timeLabels(AppLocalizations l) => [
        l.practiceExamTime15,
        l.practiceExamTime30,
        l.practiceExamTime60,
        l.practiceExamNoLimit,
      ];

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final l = AppLocalizations.of(context)!;

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
                      l.practiceExamTitle,
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
                      _SectionLabel(label: l.practiceExamSelectCourse),
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
                              l.practiceExamNoCourses,
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

                      // ── Question Count — Slider ──
                      _SectionLabel(label: l.practiceExamQuestionCount),
                      const SizedBox(height: AppSpacing.lg),
                      _QuestionSlider(
                        value: _questionCount,
                        label: l.practiceExamQuestions,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _questionCount = v);
                        },
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Time Limit ──
                      _SectionLabel(label: l.practiceExamTimeLimit),
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
                                      _timeLabels(l)[i],
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

                      const SizedBox(height: AppSpacing.xxl),

                      // ── UX-81: Exam Mode Selector ──
                      _SectionLabel(label: 'EXAM MODE'),
                      const SizedBox(height: AppSpacing.sm),
                      _ExamModeSelector(
                        selected: _selectedExamMode,
                        onSelect: (mode) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedExamMode = mode);
                        },
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── UX-82: Your Goal ──
                      _SectionLabel(label: 'YOUR GOAL'),
                      const SizedBox(height: AppSpacing.sm),
                      _GoalSlider(
                        value: _goalPercent,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _goalPercent = v);
                        },
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Motivational Card ──
                      _MotivationalCard(
                        selectedCourseId: _selectedCourseId,
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
                    : ShimmerButton(
                        label: l.practiceExamStartExam,
                        icon: Icons.play_arrow_rounded,
                        onPressed: _startExam,
                        height: 58,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Question Count Slider — Immersive design with large number display
// ═══════════════════════════════════════════════════════════════════════════════

class _QuestionSlider extends StatelessWidget {
  final double value;
  final String label;
  final ValueChanged<double> onChanged;

  const _QuestionSlider({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          // Large number display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${value.round()}',
                style: AppTypography.h1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 48,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF6467F2),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF6467F2).withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: value,
              min: 5,
              max: 30,
              divisions: 25,
              onChanged: onChanged,
            ),
          ),

          // Min/Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('5', style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                )),
                Text('30', style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UX-82: Goal Slider — Target percentage with motivational tips
// ═══════════════════════════════════════════════════════════════════════════════

class _GoalSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _GoalSlider({
    required this.value,
    required this.onChanged,
  });

  String _motivationalTip(int goal) {
    if (goal < 70) {
      return 'Start with the basics \u2014 you\'ve got this!';
    } else if (goal <= 85) {
      return 'A solid target! Focus on your weak areas.';
    } else {
      return 'Ambitious! Make sure to review all topics.';
    }
  }

  IconData _tipIcon(int goal) {
    if (goal < 70) return Icons.emoji_nature_rounded;
    if (goal <= 85) return Icons.track_changes_rounded;
    return Icons.rocket_launch_rounded;
  }

  Color _tipColor(int goal) {
    if (goal < 70) return const Color(0xFF34D399);
    if (goal <= 85) return const Color(0xFF60A5FA);
    return const Color(0xFFFBBF24);
  }

  @override
  Widget build(BuildContext context) {
    final goal = value.round();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          // Target display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Target:',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$goal%',
                style: AppTypography.h1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 48,
                  height: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF6467F2),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF6467F2).withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: value,
              min: 50,
              max: 100,
              divisions: 10, // 50 to 100 in steps of 5
              onChanged: onChanged,
            ),
          ),

          // Min/Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('50%', style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                )),
                Text('100%', style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                )),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Motivational tip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _tipColor(goal).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _tipColor(goal).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _tipIcon(goal),
                  color: _tipColor(goal),
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _motivationalTip(goal),
                    style: AppTypography.bodySmall.copyWith(
                      color: _tipColor(goal),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                          course.displayTitle,
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

class _MotivationalCard extends ConsumerWidget {
  final String? selectedCourseId;

  const _MotivationalCard({required this.selectedCourseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    Widget motivationalContent;

    if (selectedCourseId == null) {
      motivationalContent = _buildMessage(
        icon: Icons.touch_app_rounded,
        text: l.practiceExamSelectToStart,
        color: Colors.white.withValues(alpha: 0.5),
      );
    } else {
      final testsAsync = ref.watch(courseTestsProvider(selectedCourseId!));
      motivationalContent = testsAsync.when(
        loading: () => _buildMessage(
          icon: Icons.hourglass_empty_rounded,
          text: l.practiceExamLoadingHistory,
          color: Colors.white.withValues(alpha: 0.4),
        ),
        error: (_, __) => _buildMessage(
          icon: Icons.auto_awesome,
          text: l.practiceExamFirstAttempt,
          color: const Color(0xFF60A5FA),
        ),
        data: (tests) {
          final completedTests =
              tests.where((t) => t.score != null).toList();
          if (completedTests.isEmpty) {
            return _buildMessage(
              icon: Icons.auto_awesome,
              text: l.practiceExamFirstAttempt,
              color: const Color(0xFF60A5FA),
            );
          }

          final lastTest = completedTests.first;
          final pct = lastTest.percentage;

          final Color scoreColor;
          final String encouragement;
          if (pct >= 80) {
            scoreColor = const Color(0xFF34D399);
            encouragement = l.practiceExamKeepItUp;
          } else if (pct >= 50) {
            scoreColor = const Color(0xFFFBBF24);
            encouragement = l.practiceExamCanDoBetter;
          } else {
            scoreColor = const Color(0xFFEF4444);
            encouragement = l.practiceExamPracticeMakesPerfect;
          }

          return _buildMessage(
            icon: Icons.emoji_events_rounded,
            text: l.practiceExamLastScore(pct, encouragement),
            color: scoreColor,
          );
        },
      );
    }

    return Container(
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
          motivationalContent,
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.practiceExamEstimatedDifficulty,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.practiceExamMedium,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFFFBBF24),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UX-81: Exam Mode Selector — Three tappable mode cards
// ═══════════════════════════════════════════════════════════════════════════════

class _ExamModeSelector extends StatelessWidget {
  final ExamMode selected;
  final ValueChanged<ExamMode> onSelect;

  const _ExamModeSelector({
    required this.selected,
    required this.onSelect,
  });

  static const _modes = [
    _ExamModeOption(
      mode: ExamMode.standard,
      icon: Icons.linear_scale_rounded,
      title: 'Standard',
      subtitle: 'All questions in order',
      accentColor: Color(0xFF6467F2),
    ),
    _ExamModeOption(
      mode: ExamMode.review,
      icon: Icons.visibility_rounded,
      title: 'Review Mode',
      subtitle: 'See answers as you go',
      accentColor: Color(0xFF34D399),
    ),
    _ExamModeOption(
      mode: ExamMode.challenge,
      icon: Icons.local_fire_department_rounded,
      title: 'Challenge',
      subtitle: 'Stricter timer (75%)',
      accentColor: Color(0xFFFBBF24),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _modes.map((option) {
        final isSelected = selected == option.mode;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TapScale(
            onTap: () => onSelect(option.mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? option.accentColor.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? option.accentColor.withValues(alpha: 0.40)
                      : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Icon container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? option.accentColor.withValues(alpha: 0.20)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      option.icon,
                      size: 20,
                      color: isSelected
                          ? option.accentColor
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: AppTypography.labelLarge.copyWith(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option.subtitle,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? option.accentColor.withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Selection indicator
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isSelected
                        ? Icon(
                            Icons.check_circle,
                            key: const ValueKey('selected'),
                            color: option.accentColor,
                            size: 22,
                          )
                        : Icon(
                            Icons.circle_outlined,
                            key: const ValueKey('unselected'),
                            color: Colors.white.withValues(alpha: 0.2),
                            size: 22,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Data class for exam mode display options.
class _ExamModeOption {
  final ExamMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _ExamModeOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });
}
