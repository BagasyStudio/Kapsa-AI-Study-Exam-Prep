import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../../core/navigation/routes.dart';
import '../widgets/course_tab_bar.dart';
import '../widgets/ai_insight_banner.dart';
import '../widgets/material_list_item.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../providers/course_provider.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../test_results/presentation/providers/test_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

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
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                style: AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Course Name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
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
              TextField(
                controller: subtitleController,
                decoration: InputDecoration(
                  labelText: 'Subject (optional)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
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
    );
  }

  void _showDeleteCourseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Course',
          style: AppTypography.h3.copyWith(color: const Color(0xFF0F172A)),
        ),
        content: Text(
          'This will permanently delete this course and all its materials, flashcards, and quizzes. This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(courseRepositoryProvider).deleteCourse(widget.courseId);
              ref.invalidate(coursesProvider);
              if (context.mounted) context.pop();
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
      backgroundColor: AppColors.backgroundLight,
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
                color: AppColors.primary.withValues(alpha: 0.15),
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
                color: const Color(0xFFEC4899).withValues(alpha: 0.1),
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
                color: AppColors.primary.withValues(alpha: 0.1),
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
                    error: (e, _) => Text('Error: $e'),
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
                                  gradient: AppGradients.textDark,
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
          ref: ref,
        );
      case 1:
        return _StudyToolsTab(courseId: widget.courseId, ref: ref);
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
class _MaterialsTab extends StatelessWidget {
  final String courseId;
  final AsyncValue materialsAsync;
  final WidgetRef ref;

  const _MaterialsTab({
    required this.courseId,
    required this.materialsAsync,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Insight Banner
        AiInsightBanner(
          weakTopic: 'Review Materials',
          recommendation:
              'Upload course materials to unlock AI-powered flashcards, quizzes, and study insights.',
          onReviewTap: () =>
              context.push(Routes.flashcardSessionPath('$courseId-review')),
        ),

        const SizedBox(height: AppSpacing.xl),

        // "Materials" header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Materials', style: AppTypography.h4),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Material list
        materialsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (materials) {
            if (materials.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    'No materials yet. Use Capture to add content.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                    onGenerateQuiz: () => context.push(
                        Routes.flashcardSessionPath('$courseId-${material.id}')),
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

/// Study Tools tab with generate flashcards and quiz buttons.
class _StudyToolsTab extends StatelessWidget {
  final String courseId;
  final WidgetRef ref;

  const _StudyToolsTab({required this.courseId, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          children: [
            _ToolButton(
              icon: Icons.style,
              label: 'Generate Flashcards',
              subtitle: 'AI creates flashcards from your materials',
              onTap: () async {
                // Check feature access
                final canUse = await checkFeatureAccess(
                  ref: ref,
                  feature: 'flashcards',
                  context: context,
                );
                if (!canUse) return;

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating flashcards...')),
                  );
                }
                try {
                  final deck = await ref
                      .read(flashcardRepositoryProvider)
                      .generateFlashcards(courseId: courseId, count: 10);
                  if (context.mounted) {
                    context.push(Routes.flashcardSessionPath(deck.id));
                  }
                  // Record usage after success
                  await recordFeatureUsage(ref: ref, feature: 'flashcards');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _ToolButton(
              icon: Icons.quiz,
              label: 'Generate Quiz',
              subtitle: 'Test your knowledge with AI-generated questions',
              onTap: () async {
                // Check feature access
                final canUse = await checkFeatureAccess(
                  ref: ref,
                  feature: 'quiz',
                  context: context,
                );
                if (!canUse) return;

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating quiz...')),
                  );
                }
                try {
                  final result = await ref
                      .read(testRepositoryProvider)
                      .generateQuiz(courseId: courseId, count: 5);
                  if (context.mounted) {
                    context.push(Routes.testResultsPath(result.test.id));
                  }
                  // Record usage after success
                  await recordFeatureUsage(ref: ref, feature: 'quiz');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.labelLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
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
