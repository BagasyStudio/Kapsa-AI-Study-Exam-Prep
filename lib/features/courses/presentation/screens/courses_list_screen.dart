import 'dart:ui';
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

/// Available icons for course creation.
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
      backgroundColor: AppColors.backgroundLight,
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
                  style: AppTypography.h1.copyWith(fontFamily: 'Outfit'),
                ),
                const SizedBox(height: AppSpacing.xl),
                coursesAsync.when(
                  loading: () => const ShimmerList(count: 3, itemHeight: 90),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child:
                          Text('Error: $e', style: AppTypography.bodyMedium),
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
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCourseSheet(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateCourseSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateCourseSheet(ref: ref),
    );
  }
}

/// Bottom sheet for creating a new course with icon, color, and optional exam date.
class _CreateCourseSheet extends StatefulWidget {
  final WidgetRef ref;

  const _CreateCourseSheet({required this.ref});

  @override
  State<_CreateCourseSheet> createState() => _CreateCourseSheetState();
}

class _CreateCourseSheetState extends State<_CreateCourseSheet> {
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
      final user = widget.ref.read(currentUserProvider);
      if (user == null) return;

      final subtitle = _subtitleController.text.trim();
      await widget.ref.read(courseRepositoryProvider).createCourse(
            userId: user.id,
            title: title,
            subtitle: subtitle.isEmpty ? null : subtitle,
            iconName: _courseIcons[_selectedIconIndex].codePoint.toString(),
            colorHex: _colorToHex(_courseColors[_selectedColorIndex]),
            examDate: _examDate,
          );
      widget.ref.invalidate(coursesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
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
                    color: const Color(0xFF94A3B8).withValues(alpha: 0.3),
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
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Course name
              TextField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Course Name',
                  hintText: 'e.g. Biology 101',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.2),
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
                decoration: InputDecoration(
                  labelText: 'Subject (optional)',
                  hintText: 'e.g. Cell Structure & Function',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.2),
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
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _courseColors[_selectedColorIndex]
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        _courseIcons[i],
                        size: 22,
                        color: isSelected
                            ? _courseColors[_selectedColorIndex]
                            : const Color(0xFF64748B),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 20,
                        color: _examDate != null
                            ? AppColors.primary
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _examDate != null
                              ? _formatDate(_examDate!)
                              : 'Select exam date',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _examDate != null
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      if (_examDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _examDate = null),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: const Color(0xFF94A3B8),
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
              style:
                  AppTypography.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create your first course to start studying',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textMuted),
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

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.borderRadiusXxl,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: AppRadius.borderRadiusXxl,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
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
                      child:
                          Icon(course.icon, color: course.color, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.title, style: AppTypography.labelLarge),
                      if (course.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(course.subtitle!,
                            style: AppTypography.caption),
                      ],
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: AppRadius.borderRadiusPill,
                        child: LinearProgressIndicator(
                          value: course.progress,
                          backgroundColor:
                              course.color.withValues(alpha: 0.1),
                          valueColor:
                              AlwaysStoppedAnimation(course.color),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
