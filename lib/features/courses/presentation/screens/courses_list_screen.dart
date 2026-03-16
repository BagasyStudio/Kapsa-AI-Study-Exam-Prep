import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../../data/models/course_model.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../home/presentation/widgets/flashcard_quick_access_section.dart';
import '../../../home/presentation/widgets/recent_materials_grid.dart';

/// Available icons for course creation (name → IconData).
const _courseIconNames = <String>[
  'menu_book',
  'science',
  'calculate',
  'history_edu',
  'language',
  'palette',
  'computer',
  'psychology',
  'biotech',
  'music_note',
  'sports_soccer',
  'architecture',
];

const _courseIcons = <IconData>[
  Icons.menu_book,
  Icons.science,
  Icons.calculate,
  Icons.history_edu,
  Icons.language,
  Icons.palette,
  Icons.computer,
  Icons.psychology,
  Icons.biotech,
  Icons.music_note,
  Icons.sports_soccer,
  Icons.architecture,
];

/// Available colors for course creation.
const _courseColors = <Color>[
  Color(0xFF6467F2), // Primary
  Color(0xFF10B981), // Emerald
  Color(0xFFF97316), // Orange
  Color(0xFFEF4444), // Red
  Color(0xFF8B5CF6), // Purple
  Color(0xFF3B82F6), // Blue
  Color(0xFFEC4899), // Pink
  Color(0xFF14B8A6), // Teal
];

/// Courses list screen — shows real courses from Supabase.
class CoursesListScreen extends ConsumerWidget {
  const CoursesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(coursesProvider);
            // Wait a moment for the provider to refetch
            await ref.read(coursesProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Courses',
                  style: AppTypography.h1.copyWith(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                coursesAsync.when(
                  loading: () => const ShimmerList(count: 3, itemHeight: 90),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child:
                          Text(AppErrorHandler.friendlyMessage(e), style: AppTypography.bodyMedium),
                    ),
                  ),
                  data: (courses) {
                    if (courses.isEmpty) {
                      return _EmptyState(
                        onCreateCourse: () =>
                            _showCreateCourseSheet(context, ref),
                      );
                    }
                    return StaggeredColumn(
                      children: [
                        for (final course in courses) ...[
                          _CourseCard(
                            course: course,
                            onTap: () => context
                                .push(Routes.courseDetailPath(course.id)),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    );
                  },
                ),

                // Flashcard Quick Access — one-tap deck access
                const SizedBox(height: AppSpacing.lg),
                const FlashcardQuickAccessSection(),

                // Recent Materials Grid
                const SizedBox(height: AppSpacing.xxl),
                RecentMaterialsGrid(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: () => _showCreateCourseSheet(context, ref),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showCreateCourseSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => const CreateCourseSheet(),
    );
  }
}

/// Bottom sheet for creating a new course with icon, color, and optional exam date.
class CreateCourseSheet extends ConsumerStatefulWidget {
  const CreateCourseSheet({super.key});

  @override
  ConsumerState<CreateCourseSheet> createState() => CreateCourseSheetState();
}

class CreateCourseSheetState extends ConsumerState<CreateCourseSheet> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  int _selectedIconIndex = 0;
  int _selectedColorIndex = 0;
  DateTime? _examDate;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _pickExamDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );
      if (time != null && mounted) {
        setState(() {
          _examDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createCourse() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a course name')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final subtitle = _subtitleController.text.trim();
      await ref.read(courseRepositoryProvider).createCourse(
            userId: user.id,
            title: title,
            subtitle: subtitle.isEmpty ? null : subtitle,
            iconName: _courseIconNames[_selectedIconIndex],
            colorHex: _colorToHex(_courseColors[_selectedColorIndex]),
            examDate: _examDate,
          );
      ref.invalidate(coursesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorHandler.friendlyMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: AppColors.immersiveSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Center(
                child: Text(
                  'New Course',
                  style: AppTypography.h2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Course name
              TextField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Course Name',
                  labelStyle: const TextStyle(color: Colors.white60),
                  hintText: 'e.g. Biology 101',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: AppColors.immersiveCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.immersiveBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.immersiveBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Subject
              TextField(
                controller: _subtitleController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Subject (optional)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  hintText: 'e.g. Cell Structure & Function',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: AppColors.immersiveCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.immersiveBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.immersiveBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Icon picker
              Text(
                'ICON',
                style: AppTypography.sectionHeader,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_courseIcons.length, (i) {
                  final isSelected = _selectedIconIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _courseColors[_selectedColorIndex]
                                .withValues(alpha: 0.15)
                            : AppColors.immersiveCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _courseColors[_selectedColorIndex]
                              : AppColors.immersiveBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        _courseIcons[i],
                        size: 22,
                        color: isSelected
                            ? _courseColors[_selectedColorIndex]
                            : Colors.white38,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Color picker
              Text(
                'COLOR',
                style: AppTypography.sectionHeader,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: List.generate(_courseColors.length, (i) {
                  final isSelected = _selectedColorIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _courseColors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _courseColors[i]
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Exam date picker
              Text(
                'EXAM DATE (optional)',
                style: AppTypography.sectionHeader,
              ),
              const SizedBox(height: AppSpacing.sm),
              TapScale(
                onTap: _pickExamDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.immersiveCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.immersiveBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 20,
                        color: _examDate != null
                            ? AppColors.primary
                            : Colors.white38,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _examDate != null
                              ? _formatDate(_examDate!)
                              : 'Select exam date',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _examDate != null
                                ? Colors.white
                                : Colors.white38,
                          ),
                        ),
                      ),
                      if (_examDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _examDate = null),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white38,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Create button
              TapScale(
                onTap: _isCreating ? null : _createCourse,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Create Course',
                            style: AppTypography.button.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  String _colorToHex(Color c) {
    final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '$r$g$b';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${months[date.month - 1]} ${date.day}, ${date.year} · $displayHour:$minute $period';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateCourse;

  const _EmptyState({required this.onCreateCourse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.menu_book,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No courses yet',
              style: AppTypography.h3.copyWith(
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create your first course to start studying',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TapScale(
              onTap: onCreateCourse,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child:
                    Text('Create Course', style: AppTypography.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCount = ref
        .watch(dueCardsCountProvider(course.id))
        .whenOrNull(data: (c) => c) ?? 0;

    return TapScale(
      onTap: onTap,
      child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.immersiveCard,
              borderRadius: AppRadius.borderRadiusXxl,
              border: Border.all(
                color: AppColors.immersiveBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: course.color.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon with optional SRS badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Hero(
                      tag: 'course-icon-${course.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: course.color.withValues(alpha: 0.1),
                            borderRadius: AppRadius.borderRadiusLg,
                          ),
                          child: Icon(course.icon, color: course.color, size: 28),
                        ),
                      ),
                    ),
                    // SRS due badge
                    if (dueCount > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$dueCount',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
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
                        ),
                      ),
                      if (course.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          course.subtitle!,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      ],
                      // Exam urgency
                      if (course.examDate != null) ...[
                        const SizedBox(height: 4),
                        _ExamUrgencyRow(examDate: course.examDate!),
                      ],
                      // Due cards info
                      if (dueCount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.replay_rounded, size: 12,
                                color: const Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              '$dueCount card${dueCount == 1 ? '' : 's'} due',
                              style: AppTypography.caption.copyWith(
                                color: const Color(0xFFF59E0B),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: AppRadius.borderRadiusPill,
                              child: LinearProgressIndicator(
                                value: course.progress,
                                backgroundColor:
                                    course.color.withValues(alpha: 0.1),
                                valueColor:
                                    AlwaysStoppedAnimation(course.color),
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(course.progress * 100).round()}%',
                            style: AppTypography.caption.copyWith(
                              color: _progressColor(course.progress),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
    );
  }
}

Color _progressColor(double progress) {
  if (progress >= 0.71) return const Color(0xFF10B981); // Green
  if (progress >= 0.31) return const Color(0xFFF59E0B); // Amber
  return const Color(0xFFEF4444); // Red
}

class _ExamUrgencyRow extends StatelessWidget {
  final DateTime examDate;

  const _ExamUrgencyRow({required this.examDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = examDate.difference(now);
    final days = diff.inDays;

    if (days < 0) return const SizedBox.shrink(); // Past exam

    final Color urgencyColor;
    if (days < 3) {
      urgencyColor = const Color(0xFFEF4444); // Red
    } else if (days < 7) {
      urgencyColor = const Color(0xFFF97316); // Orange
    } else if (days < 14) {
      urgencyColor = const Color(0xFFF59E0B); // Yellow/Amber
    } else {
      urgencyColor = Colors.white.withValues(alpha: 0.4);
    }

    final String label;
    if (days == 0) {
      label = 'Exam today!';
    } else if (days == 1) {
      label = 'Exam tomorrow';
    } else {
      label = '$days days left';
    }

    return Row(
      children: [
        Icon(Icons.event, size: 12, color: urgencyColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: urgencyColor,
            fontWeight: days < 7 ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
