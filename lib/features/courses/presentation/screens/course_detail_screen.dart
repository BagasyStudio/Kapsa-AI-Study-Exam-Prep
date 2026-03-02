import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/theme_provider.dart';
import '../widgets/course_tab_bar.dart';
import '../widgets/course_stats_banner.dart';
import '../widgets/material_list_item.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../providers/course_provider.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../test_results/presentation/providers/test_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../capture/presentation/screens/capture_sheet.dart';
import '../../../flashcards/data/models/deck_model.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/error_handler.dart';

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
          color: context.isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
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
                  color: const Color(0xFF94A3B8).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Edit Course',
                style: AppTypography.h2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(Theme.of(ctx).brightness),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextField(
                controller: titleController,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimaryFor(Theme.of(ctx).brightness)),
                decoration: InputDecoration(
                  labelText: 'Course Name',
                  filled: true,
                  fillColor: context.isDark ? AppColors.cardDark : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.textMutedFor(Theme.of(ctx).brightness).withValues(alpha: 0.2),
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
                style: TextStyle(color: AppColors.textPrimaryFor(Theme.of(ctx).brightness)),
                decoration: InputDecoration(
                  labelText: 'Subject (optional)',
                  filled: true,
                  fillColor: context.isDark ? AppColors.cardDark : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.textMutedFor(Theme.of(ctx).brightness).withValues(alpha: 0.2),
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
        backgroundColor: context.isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Course',
          style: AppTypography.h3.copyWith(
            color: AppColors.textPrimaryFor(Theme.of(context).brightness),
          ),
        ),
        content: Text(
          'This will permanently delete this course and all its materials, flashcards, and quizzes. This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMutedFor(Theme.of(context).brightness),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textMutedFor(Theme.of(context).brightness),
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

    final brightness = Theme.of(context).brightness;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
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
                color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.15),
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
                color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.05 : 0.1),
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
                color: AppColors.primary.withValues(alpha: isDark ? 0.05 : 0.1),
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
                        icon: Icon(Icons.more_horiz, color: AppColors.textSecondary),
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
                                const Icon(Icons.edit_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text('Edit Course', style: AppTypography.bodyMedium),
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
                                  course.title,
                                  style:
                                      AppTypography.h1.copyWith(fontSize: 30),
                                  gradient: AppGradients.textFor(brightness),
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
                Text('AI Chat', style: AppTypography.h3),
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

/// Materials tab with AI insight and material list.
class _MaterialsTab extends ConsumerWidget {
  final String courseId;
  final AsyncValue materialsAsync;

  const _MaterialsTab({
    required this.courseId,
    required this.materialsAsync,
  });

  void _openCapture(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => CaptureSheet(courseId: courseId),
    );
  }

  void _generateFromBanner(BuildContext context, WidgetRef ref) async {
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'flashcards',
      context: context,
    );
    if (!canUse || !context.mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => _GeneratingOverlay(
          type: 'flashcards',
          future: ref
              .read(flashcardRepositoryProvider)
              .generateFlashcards(courseId: courseId, count: 10),
          onResult: (deck) async {
            await recordFeatureUsage(ref: ref, feature: 'flashcards');
            ref.invalidate(flashcardDecksProvider(courseId));
            navigator.pop();
            if (context.mounted) {
              context.push(Routes.flashcardSessionPath(deck.id));
            }
          },
          onError: (e) {
            navigator.pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppErrorHandler.friendlyMessage(e))),
              );
            }
          },
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StaggeredColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Stats Banner
        CourseStatsBanner(
          courseId: courseId,
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
                color: AppColors.textPrimaryFor(Theme.of(context).brightness),
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

        // Material list
        materialsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(AppErrorHandler.friendlyMessage(e)),
          data: (materials) {
            if (materials.isEmpty) {
              return _EmptyMaterials(
                onAddMaterial: () => _openCapture(context),
              );
            }
            // Use ListView.builder for efficient rendering of long lists
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: materials.length,
              itemBuilder: (context, index) {
                final material = materials[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: MaterialListItem(
                    title: material.title,
                    timeLabel: material.sizeLabel,
                    typeLabel: material.typeLabel,
                    kind: _kindFromType(material.type),
                    isReviewed: material.isReviewed,
                    onTap: () {
                      context.push(
                        Routes.materialViewerPath(courseId, material.id),
                      );
                    },
                    onGenerateQuiz: () async {
                      final canUse = await checkFeatureAccess(
                        ref: ref,
                        feature: 'flashcards',
                        context: context,
                      );
                      if (!canUse || !context.mounted) return;

                      final navigator =
                          Navigator.of(context, rootNavigator: true);
                      navigator.push(
                        PageRouteBuilder(
                          opaque: true,
                          pageBuilder: (_, __, ___) => _GeneratingOverlay(
                            type: 'flashcards',
                            future: ref
                                .read(flashcardRepositoryProvider)
                                .generateFlashcards(
                                  courseId: courseId,
                                  count: 10,
                                  materialId: material.id,
                                ),
                            onResult: (deck) async {
                              await recordFeatureUsage(
                                  ref: ref, feature: 'flashcards');
                              ref.invalidate(flashcardDecksProvider(courseId));
                              navigator.pop();
                              if (context.mounted) {
                                context.push(
                                    Routes.flashcardSessionPath(deck.id));
                              }
                            },
                            onError: (e) {
                              navigator.pop();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppErrorHandler.friendlyMessage(e))),
                                );
                              }
                            },
                          ),
                          transitionsBuilder: (_, animation, __, child) =>
                              FadeTransition(
                                  opacity: animation, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 300),
                        ),
                      );
                    },
                    onDelete: () async {
                      await ref
                          .read(materialRepositoryProvider)
                          .deleteMaterial(material.id);
                      ref.invalidate(courseMaterialsProvider(courseId));
                    },
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  CourseMaterialKind _kindFromType(String type) {
    switch (type) {
      case 'pdf':
        return CourseMaterialKind.pdf;
      case 'audio':
        return CourseMaterialKind.audio;
      case 'notes':
      case 'paste':
        return CourseMaterialKind.notes;
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
    final decksAsync = ref.watch(flashcardDecksProvider(courseId));
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
                          color: AppColors.textPrimaryFor(Theme.of(context).brightness),
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
                        child: _PastDeckItem(deck: deck),
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
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final brightness = Theme.of(context).brightness;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF94A3B8).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Choose Material', style: AppTypography.h3.copyWith(
                color: AppColors.textPrimaryFor(brightness),
              )),
              const SizedBox(height: AppSpacing.md),
              ...materials.take(10).map((m) => ListTile(
                leading: Icon(Icons.description_outlined, color: AppColors.primary),
                title: Text(m.title, style: TextStyle(color: AppColors.textPrimaryFor(brightness))),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(Routes.audioPlayerPath(m.id, courseId, m.title));
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
    if (!canUse) return;

    if (!context.mounted) return;

    // Show generating animation
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => _GeneratingOverlay(
          type: 'flashcards',
          future: ref
              .read(flashcardRepositoryProvider)
              .generateFlashcards(courseId: courseId, count: 10),
          onResult: (deck) async {
            await recordFeatureUsage(ref: ref, feature: 'flashcards');
            ref.invalidate(flashcardDecksProvider(courseId));
            navigator.pop(); // Close overlay
            if (context.mounted) {
              context.push(Routes.flashcardSessionPath(deck.id));
            }
          },
          onError: (e) {
            navigator.pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppErrorHandler.friendlyMessage(e))),
              );
            }
          },
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _generateQuiz(BuildContext context, WidgetRef ref) async {
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'quiz',
      context: context,
    );
    if (!canUse) return;

    if (!context.mounted) return;

    // Show generating animation
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => _GeneratingOverlay(
          type: 'quiz',
          future: ref
              .read(testRepositoryProvider)
              .generateQuiz(courseId: courseId, count: 5),
          onResult: (result) async {
            await recordFeatureUsage(ref: ref, feature: 'quiz');
            navigator.pop(); // Close overlay
            if (context.mounted) {
              // Navigate to quiz session (answer questions), NOT results
              context.push(Routes.quizSessionPath(result.test.id));
            }
          },
          onError: (e) {
            navigator.pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppErrorHandler.friendlyMessage(e))),
              );
            }
          },
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

/// Full-screen generating overlay with animation.
class _GeneratingOverlay<T> extends StatefulWidget {
  final String type;
  final Future<T> future;
  final void Function(T result) onResult;
  final void Function(Object error) onError;

  const _GeneratingOverlay({
    required this.type,
    required this.future,
    required this.onResult,
    required this.onError,
  });

  @override
  State<_GeneratingOverlay<T>> createState() => _GeneratingOverlayState<T>();
}

class _GeneratingOverlayState<T> extends State<_GeneratingOverlay<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _stepIndex = 0;
  bool _completed = false;

  List<String> get _steps {
    if (widget.type == 'flashcards') {
      return [
        'Reading your materials...',
        'Identifying key concepts...',
        'Crafting questions...',
        'Creating flashcards...',
      ];
    } else {
      return [
        'Analyzing your materials...',
        'Generating questions...',
        'Creating answer keys...',
        'Building your quiz...',
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Cycle through step messages
    _cycleSteps();

    // Wait for future to complete
    widget.future.then((result) {
      if (!mounted) return;
      setState(() => _completed = true);
      // Small delay for UX
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onResult(result);
      });
    }).catchError((e) {
      if (mounted) widget.onError(e);
    });
  }

  void _cycleSteps() async {
    for (int i = 1; i < _steps.length; i++) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || _completed) return;
      setState(() => _stepIndex = i);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B1E),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  Color(0xFF1A1B3A),
                  Color(0xFF0A0B1E),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing orb
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final pulse = _pulseController.value;
                      final scale = 0.88 + (pulse * 0.12);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.5),
                                const Color(0xFF6467F2)
                                    .withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6467F2)
                                    .withValues(alpha: 0.25 + pulse * 0.15),
                                blurRadius: 50 + pulse * 20,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              widget.type == 'flashcards'
                                  ? Icons.style
                                  : Icons.quiz,
                              size: 42,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Title
                  Text(
                    widget.type == 'flashcards'
                        ? 'Creating Flashcards'
                        : 'Creating Quiz',
                    style: AppTypography.h2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Status text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _completed ? 'Ready!' : _steps[_stepIndex],
                      key: ValueKey(_completed ? 'done' : _stepIndex),
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFFA5A7FA),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _stepIndex ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i <= _stepIndex
                              ? const Color(0xFF6467F2)
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
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
}

/// Small card showing a past flashcard deck.
class _PastDeckItem extends StatelessWidget {
  final DeckModel deck;

  const _PastDeckItem({required this.deck});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final brightness = Theme.of(context).brightness;
    return TapScale(
      onTap: () => context.push(Routes.flashcardSessionPath(deck.id)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.style, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.title,
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimaryFor(brightness),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${deck.cardCount} cards • ${_timeAgo(deck.createdAt)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(brightness),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_arrow_rounded,
                size: 22, color: AppColors.primary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
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
    final isDark = context.isDark;
    final brightness = Theme.of(context).brightness;
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.8),
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
                color: AppColors.textPrimaryFor(brightness),
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
          color: Colors.transparent,
        ),
        child: Icon(icon, color: AppColors.textSecondary),
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
    final isDark = context.isDark;
    final brightness = Theme.of(context).brightness;
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
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: AppRadius.borderRadiusXxl,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
                child: Icon(
                  Icons.note_add_rounded,
                  size: 30,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No materials yet',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondaryFor(brightness),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tap here to upload PDFs, scan pages, record audio, or paste notes',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedFor(brightness),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
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
