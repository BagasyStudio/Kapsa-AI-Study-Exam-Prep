import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/material_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../../core/navigation/routes.dart';
import '../widgets/course_tab_bar.dart';
import '../widgets/course_stats_banner.dart';
import '../widgets/material_list_item.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../providers/course_provider.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../capture/presentation/screens/capture_sheet.dart';
import '../../../flashcards/presentation/widgets/parent_deck_card.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/providers/generation_provider.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  int _selectedTab = 0;

  void _showEditCourseDialog(BuildContext context) {
    final course = ref.read(courseProvider(widget.courseId)).valueOrNull;
    if (course == null) return;

    final titleController = TextEditingController(text: course.title);
    final subtitleController = TextEditingController(text: course.subtitle ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.only(top: 120),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Edit Course',
                style: AppTypography.h2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextField(
                controller: titleController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Course Name',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: AppColors.immersiveSurface,
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
              TextField(
                controller: subtitleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Subject (optional)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: AppColors.immersiveSurface,
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
              const SizedBox(height: AppSpacing.xxl),
              TapScale(
                onTap: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;
                  Navigator.pop(ctx);
                  await ref.read(courseRepositoryProvider).updateCourse(
                        widget.courseId,
                        title: title,
                        subtitle: subtitleController.text.trim().isEmpty
                            ? null
                            : subtitleController.text.trim(),
                      );
                  ref.invalidate(courseProvider(widget.courseId));
                  ref.invalidate(coursesProvider);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Text(
                      'Save Changes',
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
    ).then((_) {
      titleController.dispose();
      subtitleController.dispose();
    });
  }

  void _showDeleteCourseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.immersiveCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Course',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
          ),
        ),
        content: Text(
          'This will permanently delete this course and all its materials, flashcards, and quizzes. This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white38,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white38,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(courseRepositoryProvider).deleteCourse(widget.courseId);
                ref.invalidate(coursesProvider);
                if (context.mounted) context.pop();
              } catch (e) {
                if (context.mounted) {
                  AppErrorHandler.showError(e, context: context);
                }
              }
            },
            child: Text(
              'Delete',
              style: AppTypography.labelLarge.copyWith(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseProvider(widget.courseId));
    final materialsAsync = ref.watch(courseMaterialsProvider(widget.courseId));

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: Stack(
        children: [
          // Ethereal background gradients
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back/more buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => context.pop(),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_horiz, color: Colors.white70),
                        color: AppColors.immersiveCard,
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditCourseDialog(context);
                          } else if (value == 'delete') {
                            _showDeleteCourseDialog(context);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
                                const SizedBox(width: 8),
                                Text('Edit Course', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete Course',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Course title + exam info
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: courseAsync.when(
                    loading: () => const SizedBox(height: 60),
                    error: (e, _) => Text(AppErrorHandler.friendlyMessage(e)),
                    data: (course) {
                      if (course == null) return const Text('Course not found');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Hero(
                                tag: 'course-icon-${course.id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: course.color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(course.icon,
                                        color: course.color, size: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: GradientText(
                                  course.displayTitle,
                                  style:
                                      AppTypography.h1.copyWith(fontSize: 30),
                                  gradient: AppGradients.textLight,
                                ),
                              ),
                            ],
                          ),
                          if (course.examDate != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.event,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Next Exam: ',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white60,
                                  ),
                                ),
                                Text(
                                  _formatExamDate(course.examDate!),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Tab bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: CourseTabBar(
                    selectedIndex: _selectedTab,
                    onTap: (index) => setState(() => _selectedTab = index),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Tab content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_selectedTab),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          0,
                          AppSpacing.xl,
                          120,
                        ),
                        child: _buildTabContent(materialsAsync),
                      ),
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

  String _formatExamDate(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${weekdays[date.weekday - 1]}, $displayHour:$minute $period';
  }

  Widget _buildTabContent(AsyncValue materialsAsync) {
    switch (_selectedTab) {
      case 0:
        return _MaterialsTab(
          courseId: widget.courseId,
          materialsAsync: materialsAsync,
        );
      case 1:
        return _StudyToolsTab(courseId: widget.courseId);
      case 2:
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                Text('AI Chat', style: AppTypography.h3.copyWith(color: Colors.white)),
                const SizedBox(height: AppSpacing.md),
                TapScale(
                  onTap: () =>
                      context.push(Routes.chatPath(widget.courseId)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Open Chat',
                      style: AppTypography.button,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Sort modes for the materials list.
enum _MaterialSortMode { recent, nameAz, type }

/// Materials tab with AI insight, search/filter, and material list.
class _MaterialsTab extends ConsumerStatefulWidget {
  final String courseId;
  final AsyncValue materialsAsync;

  const _MaterialsTab({
    required this.courseId,
    required this.materialsAsync,
  });

  @override
  ConsumerState<_MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends ConsumerState<_MaterialsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  _MaterialSortMode _sortMode = _MaterialSortMode.recent;
  Timer? _debounce;

  static const _filterOptions = ['All', 'PDF', 'Audio', 'Notes', 'Paste'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text.trim());
      }
    });
  }

  List<MaterialModel> _filterMaterials(List<MaterialModel> materials) {
    var filtered = List<MaterialModel>.from(materials);

    // Filter by type
    if (_selectedFilter != 'All') {
      final filterType = _selectedFilter.toLowerCase();
      filtered = filtered.where((m) => m.type == filterType).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((m) =>
              m.title.toLowerCase().contains(query) ||
              m.displayTitle.toLowerCase().contains(query))
          .toList();
    }

    // Apply sort
    switch (_sortMode) {
      case _MaterialSortMode.recent:
        filtered.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(2000);
          final bDate = b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
      case _MaterialSortMode.nameAz:
        filtered.sort((a, b) =>
            a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()));
      case _MaterialSortMode.type:
        // Define type ordering: PDF, Audio, Notes, Paste
        const typeOrder = {'pdf': 0, 'audio': 1, 'notes': 2, 'paste': 3};
        filtered.sort((a, b) {
          final aOrder = typeOrder[a.type] ?? 99;
          final bOrder = typeOrder[b.type] ?? 99;
          if (aOrder != bOrder) return aOrder.compareTo(bOrder);
          // Within same type, sort by name
          return a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase());
        });
    }

    return filtered;
  }

  void _openCapture(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => CaptureSheet(courseId: widget.courseId),
    );
  }

  Widget _buildSortChips() {
    const sortData = <_MaterialSortMode, (String, IconData)>{
      _MaterialSortMode.recent: ('Recent', Icons.schedule_rounded),
      _MaterialSortMode.nameAz: ('A-Z', Icons.sort_by_alpha_rounded),
      _MaterialSortMode.type: ('Type', Icons.category_rounded),
    };

    return Row(
      children: [
        Icon(Icons.sort_rounded, size: 14, color: Colors.white38),
        const SizedBox(width: AppSpacing.xs),
        ...sortData.entries.map((entry) {
          final isSelected = _sortMode == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _sortMode = entry.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entry.value.$2,
                      size: 12,
                      color: isSelected ? AppColors.primary : Colors.white38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.value.$1,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? AppColors.primary : Colors.white60,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Shared helper to launch background generation from material actions.
  void _launchBackground(
    BuildContext context,
    WidgetRef ref,
    GenerationType type, {
    String? materialId,
  }) {
    final notifier = ref.read(generationProvider.notifier);
    if (notifier.isRunning(type, widget.courseId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Already generating ${type.name}...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final course = ref.read(courseProvider(widget.courseId)).valueOrNull;
    final courseName = course?.displayTitle ?? 'Course';

    switch (type) {
      case GenerationType.flashcards:
        notifier.generateFlashcards(widget.courseId, courseName, materialId: materialId);
      case GenerationType.quiz:
        notifier.generateQuiz(widget.courseId, courseName);
      case GenerationType.summary:
        notifier.generateSummary(widget.courseId, courseName);
      case GenerationType.glossary:
        notifier.generateGlossary(widget.courseId, courseName);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating ${type.name} in background...'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _generateFromBanner(BuildContext context, WidgetRef ref) async {
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'flashcards',
      context: context,
    );
    if (!canUse || !context.mounted) return;

    final notifier = ref.read(generationProvider.notifier);
    if (notifier.isRunning(GenerationType.flashcards, widget.courseId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already generating flashcards...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final course = ref.read(courseProvider(widget.courseId)).valueOrNull;
    notifier.generateFlashcards(widget.courseId, course?.displayTitle ?? 'Course');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating flashcards in background...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFiltering = _searchQuery.isNotEmpty || _selectedFilter != 'All';

    return StaggeredColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Stats Banner
        CourseStatsBanner(
          courseId: widget.courseId,
          onGenerateTap: () => _generateFromBanner(context, ref),
        ),

        const SizedBox(height: AppSpacing.xl),

        // "Materials" header with add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Materials',
              style: AppTypography.h4.copyWith(
                color: Colors.white,
              ),
            ),
            TapScale(
              onTap: () => _openCapture(context),
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
                    Icon(Icons.add_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Add Material',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Search bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.immersiveCard,
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(color: AppColors.immersiveBorder),
          ),
          child: TextField(
            controller: _searchController,
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search materials...',
              hintStyle: AppTypography.bodySmall.copyWith(color: Colors.white38),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Filter chips with counts
        widget.materialsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (materials) {
            // Calculate counts per type
            final typeCounts = <String, int>{};
            for (final m in materials) {
              final label = m.type == 'pdf'
                  ? 'PDF'
                  : m.type == 'audio'
                      ? 'Audio'
                      : m.type == 'notes'
                          ? 'Notes'
                          : m.type == 'paste'
                              ? 'Paste'
                              : m.type.toUpperCase();
              typeCounts[label] = (typeCounts[label] ?? 0) + 1;
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final count = filter == 'All'
                      ? materials.length
                      : typeCounts[filter] ?? 0;

                  // Hide chips with 0 items (except "All")
                  if (filter != 'All' && count == 0) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '$filter ($count)',
                        style: AppTypography.caption.copyWith(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.immersiveCard,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.immersiveBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        // Sort chips
        _buildSortChips(),

        const SizedBox(height: AppSpacing.md),

        // Material list with animated transitions
        widget.materialsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(AppErrorHandler.friendlyMessage(e)),
          data: (materials) {
            if (materials.isEmpty) {
              return _EmptyMaterials(
                onAddMaterial: () => _openCapture(context),
              );
            }

            final filtered = _filterMaterials(materials);

            // Animated transition when filter changes
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey('$_selectedFilter-$_searchQuery-${filtered.length}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFiltering)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          '${filtered.length} material${filtered.length == 1 ? '' : 's'} found',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      ),

                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xl),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 40, color: Colors.white24),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'No materials match your search',
                                style: AppTypography.bodySmall.copyWith(color: Colors.white38),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Use ListView.builder for efficient rendering of long lists
                      ..._buildMaterialList(filtered),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  /// Build the material list, inserting type headers when grouped by type.
  List<Widget> _buildMaterialList(List<MaterialModel> filtered) {
    final widgets = <Widget>[];

    if (_sortMode == _MaterialSortMode.type) {
      // Insert type group headers
      String? lastType;
      for (var i = 0; i < filtered.length; i++) {
        final material = filtered[i];
        if (material.type != lastType) {
          lastType = material.type;
          final count = filtered.where((m) => m.type == material.type).length;
          widgets.add(
            Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    _iconForType(material.type),
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    material.typeLabel,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($count)',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        widgets.add(_buildMaterialItem(material, i));
      }
    } else {
      for (var i = 0; i < filtered.length; i++) {
        widgets.add(_buildMaterialItem(filtered[i], i));
      }
    }

    return widgets;
  }

  Widget _buildMaterialItem(MaterialModel material, int index) {
    return EntranceAnimation(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: MaterialListItem(
          title: material.displayTitle,
          timeLabel: material.sizeLabel,
          typeLabel: material.typeLabel,
          kind: _kindFromType(material.type),
          isReviewed: material.isReviewed,
          wordCount: _estimateWordCount(material),
          readingTimeMinutes: _estimateReadingTime(material),
          fileSize: material.fileSize,
          durationSeconds: material.durationSeconds,
          onTap: () {
            context.push(
              Routes.materialViewerPath(widget.courseId, material.id),
            );
          },
          onGenerateQuiz: () async {
            final canUse = await checkFeatureAccess(
              ref: ref,
              feature: 'flashcards',
              context: context,
            );
            if (!canUse || !mounted) return;
            _launchBackground(context, ref, GenerationType.flashcards,
                materialId: material.id);
          },
          onGenerateFlashcards: () async {
            final canUse = await checkFeatureAccess(
              ref: ref,
              feature: 'flashcards',
              context: context,
            );
            if (!canUse || !mounted) return;
            _launchBackground(context, ref, GenerationType.flashcards,
                materialId: material.id);
          },
          onGenerateSummary: () async {
            final canUse = await checkFeatureAccess(
              ref: ref,
              feature: 'summary',
              context: context,
            );
            if (!canUse || !mounted) return;
            _launchBackground(context, ref, GenerationType.summary);
          },
          onAudioSummary: () {
            context.push(
              Routes.audioPlayerPath(
                  material.id, widget.courseId, material.displayTitle),
            );
          },
          onPracticeQuiz: () async {
            final canUse = await checkFeatureAccess(
              ref: ref,
              feature: 'quiz',
              context: context,
            );
            if (!canUse || !mounted) return;
            _launchBackground(context, ref, GenerationType.quiz);
          },
          onDelete: () async {
            await ref
                .read(materialRepositoryProvider)
                .deleteMaterial(material.id);
            ref.invalidate(courseMaterialsProvider(widget.courseId));
          },
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'audio':
        return Icons.headphones_rounded;
      case 'notes':
        return Icons.note_rounded;
      case 'paste':
        return Icons.content_paste_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  int? _estimateWordCount(MaterialModel material) {
    if (material.content == null || material.content!.trim().isEmpty) return null;
    return material.content!.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  int? _estimateReadingTime(MaterialModel material) {
    final wordCount = _estimateWordCount(material);
    if (wordCount == null || wordCount == 0) return null;
    final minutes = (wordCount / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  CourseMaterialKind _kindFromType(String type) {
    switch (type) {
      case 'pdf':
        return CourseMaterialKind.pdf;
      case 'audio':
        return CourseMaterialKind.audio;
      case 'paste':
        return CourseMaterialKind.paste;
      case 'notes':
      default:
        return CourseMaterialKind.notes;
    }
  }
}

/// Study Tools tab with generate flashcards and quiz buttons,
/// plus history of past decks and quizzes.
class _StudyToolsTab extends ConsumerWidget {
  final String courseId;

  const _StudyToolsTab({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(parentDecksProvider(courseId));
    final dueCountAsync = ref.watch(dueCardsCountProvider(courseId));
    final dueCount = dueCountAsync.whenOrNull(data: (c) => c) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SRS Review button — prominent CTA when cards are due
          dueCountAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (dueCount) {
              if (dueCount == 0) return const SizedBox.shrink();
              return Column(
                children: [
                  TapScale(
                    onTap: () => context.push(Routes.srsReviewPath(courseId)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.replay_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Review Due Cards',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$dueCount card${dueCount == 1 ? '' : 's'} ready for review',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '$dueCount',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            },
          ),

          // Study Tools Grid (2x4)
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              _StudyToolGridItem(
                icon: Icons.style,
                label: 'Flashcards',
                color: const Color(0xFF3B82F6),
                onTap: () => _generateFlashcards(context, ref),
              ),
              _StudyToolGridItem(
                icon: Icons.quiz,
                label: 'Quiz',
                color: const Color(0xFF10B981),
                onTap: () => _generateQuiz(context, ref),
              ),
              _StudyToolGridItem(
                icon: Icons.timer,
                label: 'Practice Exam',
                color: const Color(0xFFF97316),
                onTap: () => context.push(Routes.practiceExam),
              ),
              _StudyToolGridItem(
                icon: Icons.replay_rounded,
                label: 'SRS Review',
                color: const Color(0xFF8B5CF6),
                badge: dueCount > 0 ? '$dueCount due' : null,
                onTap: () => context.push(Routes.srsReviewPath(courseId)),
              ),
              _StudyToolGridItem(
                icon: Icons.headphones,
                label: 'Audio Summary',
                color: const Color(0xFF14B8A6),
                onTap: () => _openAudioSummary(context, ref),
              ),
              _StudyToolGridItem(
                icon: Icons.grid_view_rounded,
                label: 'Occlusion',
                color: const Color(0xFFEC4899),
                onTap: () => context.push(Routes.occlusionEditorPath(courseId)),
              ),
              _StudyToolGridItem(
                icon: Icons.camera_alt_rounded,
                label: 'Snap & Solve',
                color: const Color(0xFFF59E0B),
                onTap: () => context.push(Routes.snapSolve),
              ),
              _StudyToolGridItem(
                icon: Icons.auto_stories,
                label: 'Summary',
                color: const Color(0xFF06B6D4),
                onTap: () => _generateSummary(context, ref),
              ),
              _StudyToolGridItem(
                icon: Icons.menu_book,
                label: 'Glossary',
                color: const Color(0xFF8B5CF6),
                onTap: () => _generateGlossary(context, ref),
              ),
              _StudyToolGridItem(
                icon: Icons.share_rounded,
                label: 'Share Deck',
                color: const Color(0xFF6366F1),
                onTap: () => context.push(Routes.deckListPath(courseId)),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Past flashcard decks
          decksAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (decks) {
              if (decks.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Past Decks',
                        style: AppTypography.h4.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      if (decks.length > 3)
                        TapScale(
                          onTap: () =>
                              context.push(Routes.deckListPath(courseId)),
                          child: Text(
                            'View All',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...decks.take(3).map((deck) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ParentDeckCard(deck: deck),
                      )),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  void _openAudioSummary(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.read(courseMaterialsProvider(courseId));
    materialsAsync.whenData((materials) {
      if (materials.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add study materials first to generate audio summaries')),
        );
        return;
      }
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: AppColors.immersiveCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Choose Material', style: AppTypography.h3.copyWith(
                color: Colors.white,
              )),
              const SizedBox(height: AppSpacing.md),
              ...materials.take(10).map((m) => ListTile(
                leading: Icon(Icons.description_outlined, color: AppColors.primary),
                title: Text(m.displayTitle, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(Routes.audioPlayerPath(m.id, courseId, m.displayTitle));
                },
              )),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + AppSpacing.lg),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _generateFlashcards(BuildContext context, WidgetRef ref) async {
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'flashcards',
      context: context,
    );
    if (!canUse || !context.mounted) return;

    // Show count selector bottom sheet
    final selectedCount = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FlashcardCountSelector(
        isPro: ref.read(isProProvider).whenOrNull(data: (v) => v) ?? false,
      ),
    );
    if (selectedCount == null || !context.mounted) return;

    _startBackgroundGeneration(
      context, ref, GenerationType.flashcards, 'flashcards',
      flashcardCount: selectedCount,
    );
  }

  Future<void> _generateQuiz(BuildContext context, WidgetRef ref) async {
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'quiz',
      context: context,
    );
    if (!canUse || !context.mounted) return;
    _startBackgroundGeneration(
      context, ref, GenerationType.quiz, 'quiz',
    );
  }

  Future<void> _generateSummary(BuildContext context, WidgetRef ref) async {
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'summary',
      context: context,
    );
    if (!canUse || !context.mounted) return;
    _startBackgroundGeneration(
      context, ref, GenerationType.summary, 'summary',
    );
  }

  Future<void> _generateGlossary(BuildContext context, WidgetRef ref) async {
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'glossary',
      context: context,
    );
    if (!canUse || !context.mounted) return;
    _startBackgroundGeneration(
      context, ref, GenerationType.glossary, 'glossary',
    );
  }

  /// Shared helper to launch a background generation task.
  void _startBackgroundGeneration(
    BuildContext context,
    WidgetRef ref,
    GenerationType type,
    String featureName, {
    int? flashcardCount,
  }) {
    final notifier = ref.read(generationProvider.notifier);

    // Prevent duplicate generation
    if (notifier.isRunning(type, courseId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Already generating ${type.name}...'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Get course name for the banner
    final course = ref.read(courseProvider(courseId)).valueOrNull;
    final courseName = course?.displayTitle ?? 'Course';

    // Start background generation
    final started = switch (type) {
      GenerationType.flashcards => notifier.generateFlashcards(
          courseId, courseName, count: flashcardCount),
      GenerationType.quiz => notifier.generateQuiz(courseId, courseName),
      GenerationType.summary => notifier.generateSummary(courseId, courseName),
      GenerationType.glossary => notifier.generateGlossary(courseId, courseName),
    };

    if (started) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generating ${type.name} in background...'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Grid item for the Study Tools 2x4 grid with colored icon.
class _StudyToolGridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _StudyToolGridItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.immersiveBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badge != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      badge!,
                      style: AppTypography.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small circular icon button for header.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      scaleDown: 0.90,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: Icon(icon, color: Colors.white70),
      ),
    );
  }
}

/// Beautiful empty state for the materials tab with a CTA to add materials.
class _EmptyMaterials extends StatelessWidget {
  final VoidCallback onAddMaterial;

  const _EmptyMaterials({required this.onAddMaterial});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: TapScale(
        onTap: onAddMaterial,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xxl,
            horizontal: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: AppColors.immersiveCard,
            borderRadius: AppRadius.borderRadiusXxl,
            border: Border.all(
              color: AppColors.immersiveBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Get started in 3 steps',
                style: AppTypography.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _StepRow(
                number: 1,
                emoji: '📄',
                title: 'Upload Material',
                subtitle: 'PDFs, scans, audio, or paste notes',
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(height: AppSpacing.md),
              const _StepRow(
                number: 2,
                emoji: '🧠',
                title: 'AI Generates Study Tools',
                subtitle: 'Flashcards, quizzes & summaries — automatically',
                color: Color(0xFF8B5CF6),
              ),
              const SizedBox(height: AppSpacing.md),
              const _StepRow(
                number: 3,
                emoji: '🎯',
                title: 'Study & Review',
                subtitle: 'Master content with spaced repetition',
                color: Color(0xFF22C55E),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.borderRadiusPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Add Material',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Flashcard Count Selector Bottom Sheet
// =============================================================================

class _FlashcardCountSelector extends StatefulWidget {
  final bool isPro;

  const _FlashcardCountSelector({required this.isPro});

  @override
  State<_FlashcardCountSelector> createState() =>
      _FlashcardCountSelectorState();
}

class _FlashcardCountSelectorState extends State<_FlashcardCountSelector> {
  int _selected = 30;

  static const _options = [20, 30, 50, 80];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'How many flashcards?',
            style: AppTypography.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose the number of cards to generate',
            style: AppTypography.caption.copyWith(color: Colors.white38),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Count pills
          Row(
            children: _options.map((count) {
              final isSelected = _selected == count;
              final isLocked = !widget.isPro && count > 30;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: isLocked
                        ? null
                        : () => setState(() => _selected = count),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.ctaLime.withValues(alpha: 0.12)
                            : isLocked
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.ctaLime.withValues(alpha: 0.50)
                              : isLocked
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white.withValues(alpha: 0.10),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$count',
                            style: AppTypography.h4.copyWith(
                              color: isSelected
                                  ? AppColors.ctaLime
                                  : isLocked
                                      ? Colors.white24
                                      : Colors.white70,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (isLocked) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFF97316),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'PRO',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Generate button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(_selected),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.ctaLime,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ctaLime.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Generate $_selected Flashcards',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.ctaLimeText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Step Row for Empty Materials Guide
// =============================================================================

class _StepRow extends StatelessWidget {
  final int number;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _StepRow({
    required this.number,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
