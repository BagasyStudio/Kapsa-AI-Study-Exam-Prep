import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/study_task_model.dart';
import '../providers/study_plan_provider.dart';

/// Card on the Home screen showing today's study plan.
///
/// Renders a list of study tasks computed from existing data:
/// due flashcards, suggested quizzes, and calendar events.
/// Tracks local completion state with animated checkboxes and XP rewards.
class StudyPlanCard extends ConsumerStatefulWidget {
  const StudyPlanCard({super.key});

  @override
  ConsumerState<StudyPlanCard> createState() => _StudyPlanCardState();
}

class _StudyPlanCardState extends ConsumerState<StudyPlanCard> {
  /// Tracks which task indices are marked as completed (local only).
  final Set<int> _completedIndices = {};

  void _toggleTask(int index) {
    setState(() {
      if (_completedIndices.contains(index)) {
        _completedIndices.remove(index);
      } else {
        _completedIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(studyPlanProvider);
    final brightness = Theme.of(context).brightness;

    return planAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: ShimmerCard(height: 200, borderRadius: BorderRadius.circular(20)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();

        final displayTasks = tasks.take(5).toList();
        final completedCount = _completedIndices
            .where((i) => i < displayTasks.length)
            .length;
        final totalCount = displayTasks.length;
        final progress =
            totalCount > 0 ? completedCount / totalCount : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: GlassPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _HeaderRow(
                  completedCount: completedCount,
                  totalCount: totalCount,
                  progress: progress,
                  brightness: brightness,
                ),

                const SizedBox(height: AppSpacing.md),

                // Task list (max 5)
                ...List.generate(displayTasks.length, (index) {
                  return _TaskRow(
                    task: displayTasks[index],
                    isCompleted: _completedIndices.contains(index),
                    onToggle: () => _toggleTask(index),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Header with progress text and mini linear progress bar
// ---------------------------------------------------------------------------

class _HeaderRow extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final double progress;
  final Brightness brightness;

  const _HeaderRow({
    required this.completedCount,
    required this.totalCount,
    required this.progress,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                "Today's Study Plan",
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimaryFor(brightness),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Builder(builder: (context) {
              // Dynamic pill color: red (0 done), amber (partial), green (all)
              final pillColor = totalCount == 0
                  ? const Color(0xFFF59E0B)
                  : completedCount == 0
                      ? const Color(0xFFEF4444)
                      : completedCount < totalCount
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: pillColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$completedCount of $totalCount done',
                  style: AppTypography.caption.copyWith(
                    color: pillColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        // Mini linear progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completedCount == totalCount && totalCount > 0
                      ? AppColors.success
                      : AppColors.primary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual task row with animated circular checkbox
// ---------------------------------------------------------------------------

class _TaskRow extends StatefulWidget {
  final StudyTask task;
  final bool isCompleted;
  final VoidCallback onToggle;

  const _TaskRow({
    required this.task,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnim;

  late final AnimationController _xpController;
  late final Animation<double> _xpOpacity;
  late final Animation<Offset> _xpSlide;

  late final AnimationController _strikeController;
  late final Animation<double> _strikeAnim;

  bool _showXp = false;

  @override
  void initState() {
    super.initState();

    // Bounce animation for checkbox
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOut,
    ));

    // XP float-up animation
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _xpOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_xpController);
    _xpSlide = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(
      parent: _xpController,
      curve: Curves.easeOutCubic,
    ));

    // Strikethrough animation
    _strikeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _strikeAnim = CurvedAnimation(
      parent: _strikeController,
      curve: Curves.easeOut,
    );

    // Set initial state if already completed
    if (widget.isCompleted) {
      _strikeController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _TaskRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted) {
      if (widget.isCompleted) {
        _strikeController.forward();
      } else {
        _strikeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _xpController.dispose();
    _strikeController.dispose();
    super.dispose();
  }

  void _handleCheckboxTap() {
    HapticFeedback.mediumImpact();
    final wasCompleted = widget.isCompleted;
    widget.onToggle();

    if (!wasCompleted) {
      // Play bounce
      _bounceController.forward(from: 0);
      // Show +10 XP
      setState(() => _showXp = true);
      _xpController.forward(from: 0).then((_) {
        if (mounted) setState(() => _showXp = false);
      });
    }
  }

  IconData get _icon {
    switch (widget.task.type) {
      case StudyTaskType.flashcardReview:
        return Icons.style;
      case StudyTaskType.quiz:
        return Icons.quiz;
      case StudyTaskType.calendarExam:
        return Icons.event;
      case StudyTaskType.calendarTask:
        return Icons.task_alt;
    }
  }

  Color _accentColor(StudyTaskType type) {
    switch (type) {
      case StudyTaskType.flashcardReview:
        return const Color(0xFFF59E0B); // amber
      case StudyTaskType.quiz:
        return const Color(0xFF6467F2); // primary
      case StudyTaskType.calendarExam:
        return const Color(0xFFEF4444); // red
      case StudyTaskType.calendarTask:
        return const Color(0xFF22C55E); // green
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final accent = _accentColor(widget.task.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TapScale(
        onTap: () {
          HapticFeedback.lightImpact();
          if (widget.task.route != null) {
            context.push(widget.task.route!);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              // Circular checkbox
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: _handleCheckboxTap,
                    behavior: HitTestBehavior.opaque,
                    child: ScaleTransition(
                      scale: _bounceAnim,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isCompleted
                              ? AppColors.success
                              : Colors.transparent,
                          border: Border.all(
                            color: widget.isCompleted
                                ? AppColors.success
                                : accent.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: widget.isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Floating +10 XP text
                  if (_showXp)
                    Positioned(
                      left: -2,
                      top: -4,
                      child: SlideTransition(
                        position: _xpSlide,
                        child: FadeTransition(
                          opacity: _xpOpacity,
                          child: Text(
                            '+10 XP',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.xpGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              // Task type icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, size: 18, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _strikeAnim,
                      builder: (context, child) {
                        return Text(
                          widget.task.title,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimaryFor(brightness)
                                .withValues(
                              alpha: widget.isCompleted ? 0.5 : 1.0,
                            ),
                            fontWeight: FontWeight.w600,
                            decoration: _strikeAnim.value > 0.05
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor:
                                AppColors.textMutedFor(brightness),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _strikeAnim,
                      builder: (context, child) {
                        return Text(
                          widget.task.subtitle,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMutedFor(brightness)
                                .withValues(
                              alpha: widget.isCompleted ? 0.4 : 1.0,
                            ),
                            fontSize: 11,
                            decoration: _strikeAnim.value > 0.05
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor:
                                AppColors.textMutedFor(brightness),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Arrow (hidden when completed)
              AnimatedOpacity(
                opacity: widget.isCompleted ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textMutedFor(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
