import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_limits.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

/// Bottom sheet modal for capturing new study materials.
///
/// Covers 92% of screen, shows 2x2 action grid + recent captures.
class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  bool _isProcessing = false;

  Future<void> _scanPages(List<CourseModel> courses) async {
    // Check feature access for OCR
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'ocr',
      context: context,
    );
    if (!canUse) return;

    final courseId = await _pickCourse(courses);
    if (courseId == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    // Validate file size
    final imageBytes = await image.readAsBytes();
    if (imageBytes.length > AppLimits.maxFileSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File too large. Maximum size is ${AppLimits.maxFileSizeMB} MB.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Upload to Supabase Storage
      final client = ref.read(supabaseClientProvider);
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage
          .from('course-materials')
          .uploadBinary(fileName, imageBytes);
      final fileUrl =
          client.storage.from('course-materials').getPublicUrl(fileName);

      // Process with OCR Edge Function
      final material = await ref
          .read(materialRepositoryProvider)
          .processCapture(
            courseId: courseId,
            type: 'ocr',
            fileUrl: fileUrl,
            title: 'Scanned Page',
          );

      // Record usage after success
      await recordFeatureUsage(ref: ref, feature: 'ocr');

      if (mounted) {
        Navigator.of(context)
            .pop('Scanned and processed: ${material.title}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _recordAndTranscribe(List<CourseModel> courses) async {
    // Check feature access for whisper
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'whisper',
      context: context,
    );
    if (!canUse) return;

    final courseId = await _pickCourse(courses);
    if (courseId == null) return;

    // For now, show a coming soon message since audio recording
    // requires more complex setup with the record package
    if (mounted) {
      Navigator.of(context)
          .pop('Audio recording requires microphone permissions. Coming soon!');
    }
  }

  Future<void> _uploadPdf(List<CourseModel> courses) async {
    // Check feature access for OCR (PDF processing)
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'ocr',
      context: context,
    );
    if (!canUse) return;

    final courseId = await _pickCourse(courses);
    if (courseId == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    // Validate file size (25 MB max)
    if (file.bytes!.length > AppLimits.maxFileSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF too large. Maximum size is ${AppLimits.maxFileSizeMB} MB.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.pdf';
      await client.storage
          .from('course-materials')
          .uploadBinary(fileName, file.bytes!);
      final fileUrl =
          client.storage.from('course-materials').getPublicUrl(fileName);

      // Process with OCR Edge Function
      final material = await ref
          .read(materialRepositoryProvider)
          .processCapture(
            courseId: courseId,
            type: 'ocr',
            fileUrl: fileUrl,
            title: file.name,
          );

      // Record usage after success
      await recordFeatureUsage(ref: ref, feature: 'ocr');

      if (mounted) {
        Navigator.of(context)
            .pop('Uploaded and processed: ${material.title}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _quickPaste(List<CourseModel> courses) async {
    final courseId = await _pickCourse(courses);
    if (courseId == null) return;

    final result = await _showPasteDialog();
    if (result == null || result.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      final material = await ref
          .read(materialRepositoryProvider)
          .createMaterial(
            courseId: courseId,
            userId: user.id,
            title: 'Quick Note - ${DateTime.now().day}/${DateTime.now().month}',
            type: 'paste',
            content: result,
          );

      if (mounted) {
        Navigator.of(context)
            .pop('Saved: ${material.title}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String?> _pickCourse(List<CourseModel> courses) async {
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Create a course first before adding materials')),
      );
      return null;
    }

    if (courses.length == 1) return courses.first.id;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Course'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: courses.length,
            itemBuilder: (_, i) {
              final course = courses[i];
              return ListTile(
                leading: Icon(course.icon, color: course.color),
                title: Text(course.title),
                subtitle:
                    course.subtitle != null ? Text(course.subtitle!) : null,
                onTap: () => Navigator.of(ctx).pop(course.id),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<String?> _showPasteDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quick Paste'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          maxLength: AppLimits.maxPasteLength,
          inputFormatters: [
            LengthLimitingTextInputFormatter(AppLimits.maxPasteLength),
          ],
          decoration: const InputDecoration(
            hintText: 'Paste or type your notes here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final recentAsync = ref.watch(recentMaterialsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: AppRadius.borderRadiusSheet,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: AppRadius.borderRadiusSheet,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 8),
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: AppRadius.borderRadiusPill,
                      ),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: _isProcessing
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  'Processing...',
                                  style: AppTypography.h3,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'AI is extracting text from your material',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            children: [
                              const SizedBox(height: AppSpacing.md),

                              // Header
                              Center(
                                child: Text(
                                  'New Capture',
                                  style: AppTypography.h2
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Text(
                                  'Choose how you want to add materials',
                                  style: AppTypography.bodySmall,
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xxxl),

                              // 2x2 Action Grid
                              coursesAsync.when(
                                loading: () => const SizedBox(
                                  height: 300,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                                error: (e, _) => Center(
                                  child: Text('Error loading courses: $e'),
                                ),
                                data: (courses) => GridView.count(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: AppSpacing.lg,
                                  crossAxisSpacing: AppSpacing.lg,
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  children: [
                                    _CaptureAction(
                                      icon: Icons.photo_camera_rounded,
                                      label: 'Scan Pages',
                                      onTap: () => _scanPages(courses),
                                    ),
                                    _CaptureAction(
                                      icon: Icons.graphic_eq_rounded,
                                      label: 'Record &\nTranscribe',
                                      onTap: () =>
                                          _recordAndTranscribe(courses),
                                    ),
                                    _CaptureAction(
                                      icon: Icons.picture_as_pdf_rounded,
                                      label: 'Upload PDF',
                                      onTap: () => _uploadPdf(courses),
                                    ),
                                    _CaptureAction(
                                      icon: Icons.content_paste_rounded,
                                      label: 'Quick Paste',
                                      onTap: () => _quickPaste(courses),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xxl),

                              // Recent section
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'RECENT',
                                    style: AppTypography.sectionHeader,
                                  ),
                                  Text(
                                    'View All',
                                    style:
                                        AppTypography.labelMedium.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Recent items from real data
                              recentAsync.when(
                                loading: () =>
                                    const CircularProgressIndicator(),
                                error: (e, _) =>
                                    Text('Error: $e'),
                                data: (materials) {
                                  if (materials.isEmpty) {
                                    return _RecentItem(
                                      icon: Icons.info_outline,
                                      title: 'No recent materials',
                                      subtitle:
                                          'Capture something to get started',
                                    );
                                  }
                                  return Column(
                                    children: materials
                                        .take(3)
                                        .map((m) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: AppSpacing.sm),
                                              child: _RecentItem(
                                                icon: _iconForType(m.type),
                                                title: m.title,
                                                subtitle: m.sizeLabel.isNotEmpty
                                                    ? m.sizeLabel
                                                    : m.typeLabel,
                                              ),
                                            ))
                                        .toList(),
                                  );
                                },
                              ),

                              const SizedBox(height: AppSpacing.xxl),

                              // Cancel button
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey
                                        .withValues(alpha: 0.1),
                                    borderRadius: AppRadius.borderRadiusPill,
                                    border: Border.all(
                                      color: Colors.grey
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Cancel',
                                      style:
                                          AppTypography.labelLarge.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'audio':
        return Icons.graphic_eq;
      case 'notes':
        return Icons.edit_note;
      case 'paste':
        return Icons.content_paste;
      default:
        return Icons.description;
    }
  }
}

class _CaptureAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CaptureAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecentItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RecentItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
