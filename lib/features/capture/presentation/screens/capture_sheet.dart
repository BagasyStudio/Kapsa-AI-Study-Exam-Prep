import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/constants/app_limits.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/services/sound_service.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../../core/utils/error_handler.dart';

/// Bottom sheet modal for capturing new study materials.
///
/// Covers 92% of screen, shows 2x2 action grid + recent captures.
class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  String _processingStatus = 'Processing...';
  int _processingStep = 0; // 0=uploading, 1=analyzing, 2=done
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
    // Compress at capture time: max 1920px, 75% quality
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 75,
    );
    if (image == null) return;

    // Check file size BEFORE reading bytes into memory
    final fileLength = await image.length();
    if (fileLength > AppLimits.maxFileSizeBytes) {
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

    setState(() {
      _isProcessing = true;
      _processingStep = 0;
      _processingStatus = 'Uploading image...';
    });

    try {
      final imageBytes = await image.readAsBytes();

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

      if (mounted) {
        setState(() {
          _processingStep = 1;
          _processingStatus = 'AI is extracting text...';
        });
      }

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

      // Refresh materials lists so new material appears immediately
      ref.invalidate(courseMaterialsProvider(courseId));
      ref.invalidate(recentMaterialsProvider);

      if (mounted) {
        SoundService.playProcessingComplete();
        Navigator.of(context)
            .pop('Scanned and processed: ${material.title}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppErrorHandler.showError(e, context: context);
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
    if (!canUse || !mounted) return;

    final courseId = await _pickCourse(courses);
    if (courseId == null || !mounted) return;

    // Show recording dialog
    final audioPath = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _AudioRecorderDialog(),
    );

    if (audioPath == null || !mounted) return;

    setState(() {
      _isProcessing = true;
      _processingStep = 0;
      _processingStatus = 'Uploading audio...';
    });

    try {
      final file = File(audioPath);
      final audioBytes = await file.readAsBytes();

      // Check file size
      if (audioBytes.length > AppLimits.maxFileSizeBytes) {
        throw Exception(
          'Audio too large. Maximum size is ${AppLimits.maxFileSizeMB} MB.',
        );
      }

      final client = ref.read(supabaseClientProvider);
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await client.storage
          .from('course-materials')
          .uploadBinary(fileName, audioBytes);
      final fileUrl =
          client.storage.from('course-materials').getPublicUrl(fileName);

      if (mounted) {
        setState(() {
          _processingStep = 1;
          _processingStatus = 'AI is transcribing audio...';
        });
      }

      // Process with Whisper Edge Function
      final material = await ref
          .read(materialRepositoryProvider)
          .processCapture(
            courseId: courseId,
            type: 'whisper',
            fileUrl: fileUrl,
            title: 'Recording - ${DateTime.now().day}/${DateTime.now().month}',
          );

      // Record usage after success
      await recordFeatureUsage(ref: ref, feature: 'whisper');

      // Clean up temp file
      try {
        await file.delete();
      } catch (_) {}

      // Refresh materials lists so new material appears immediately
      ref.invalidate(courseMaterialsProvider(courseId));
      ref.invalidate(recentMaterialsProvider);

      if (mounted) {
        SoundService.playProcessingComplete();
        Navigator.of(context)
            .pop('Transcribed: ${material.title}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppErrorHandler.showError(e, context: context);
      }
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

    setState(() {
      _isProcessing = true;
      _processingStep = 0;
      _processingStatus = 'Uploading PDF...';
    });

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

      if (mounted) {
        setState(() {
          _processingStep = 1;
          _processingStatus = 'AI is extracting text...';
        });
      }

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

      // Refresh materials lists so new material appears immediately
      ref.invalidate(courseMaterialsProvider(courseId));
      ref.invalidate(recentMaterialsProvider);

      if (mounted) {
        SoundService.playProcessingComplete();
        Navigator.of(context)
            .pop('Uploaded and processed: ${material.title}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppErrorHandler.showError(e, context: context);
      }
    }
  }

  Future<void> _quickPaste(List<CourseModel> courses) async {
    final courseId = await _pickCourse(courses);
    if (courseId == null) return;

    final result = await _showPasteDialog();
    if (result == null || result.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _processingStep = 1;
      _processingStatus = 'Saving note...';
    });

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

      // Refresh materials lists so new material appears immediately
      ref.invalidate(courseMaterialsProvider(courseId));
      ref.invalidate(recentMaterialsProvider);

      if (mounted) {
        SoundService.playProcessingComplete();
        Navigator.of(context)
            .pop('Saved: ${material.title}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppErrorHandler.showError(e, context: context);
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
    try {
      return await showDialog<String>(
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
    } finally {
      controller.dispose();
    }
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
                        ? _UploadProgressView(
                            status: _processingStatus,
                            step: _processingStep,
                            pulseAnimation: _pulseController,
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
                                  child: Text(AppErrorHandler.friendlyMessage(e)),
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
                                    Text(AppErrorHandler.friendlyMessage(e)),
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

// ═══════════════════════════════════════════
// Upload Progress View
// ═══════════════════════════════════════════

/// Beautiful animated upload progress view with step indicators.
class _UploadProgressView extends StatelessWidget {
  final String status;
  final int step; // 0=uploading, 1=analyzing
  final AnimationController pulseAnimation;

  const _UploadProgressView({
    required this.status,
    required this.step,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated orb
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, __) {
                final scale = 1.0 + (pulseAnimation.value * 0.12);
                final glowOpacity = 0.2 + (pulseAnimation.value * 0.15);
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: glowOpacity),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight,
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        ),
                      ),
                      child: Icon(
                        step == 0
                            ? Icons.cloud_upload_rounded
                            : Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Status text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Text(
                status,
                key: ValueKey(status),
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                step == 0
                    ? 'Sending your file to the cloud...'
                    : 'Our AI is working its magic...',
                key: ValueKey(step),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Step indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepDot(
                  label: 'Upload',
                  icon: Icons.cloud_upload_outlined,
                  isActive: step == 0,
                  isComplete: step > 0,
                ),
                _StepConnector(isComplete: step > 0),
                _StepDot(
                  label: 'Analyze',
                  icon: Icons.psychology_outlined,
                  isActive: step == 1,
                  isComplete: step > 1,
                ),
                _StepConnector(isComplete: step > 1),
                _StepDot(
                  label: 'Done',
                  icon: Icons.check_circle_outline,
                  isActive: false,
                  isComplete: step > 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isComplete;

  const _StepDot({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final color = isComplete
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : AppColors.textMuted.withValues(alpha: 0.4);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          width: isActive ? 44 : 36,
          height: isActive ? 44 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isActive ? 0.15 : 0.08),
            border: Border.all(
              color: color.withValues(alpha: isActive ? 0.5 : 0.2),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Icon(
            isComplete ? Icons.check_rounded : icon,
            size: isActive ? 22 : 18,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isActive ? AppColors.primary : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool isComplete;

  const _StepConnector({required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 40,
        height: 2,
        decoration: BoxDecoration(
          color: isComplete
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.textMuted.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Audio Recorder Dialog
// ═══════════════════════════════════════════

class _AudioRecorderDialog extends StatefulWidget {
  const _AudioRecorderDialog();

  @override
  State<_AudioRecorderDialog> createState() => _AudioRecorderDialogState();
}

class _AudioRecorderDialogState extends State<_AudioRecorderDialog> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  StreamSubscription? _playerCompleteSub;

  // States: idle → recording → preview
  bool _isRecording = false;
  bool _hasPermission = false;
  bool _isPreview = false; // after recording, show playback
  bool _isPlaying = false;
  int _seconds = 0;
  int _recordedDuration = 0; // total recorded seconds
  Timer? _timer;
  String? _filePath;

  static const _maxDurationSeconds = 1800; // 30 minutes max

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _checkPermission() async {
    final granted = await _recorder.hasPermission();
    if (mounted) {
      setState(() => _hasPermission = granted);
      if (!granted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required. Please enable it in Settings.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      _filePath =
          '${dir.path}/kapsa_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Compressed config optimized for voice:
      // 48 kbps AAC mono @ 16 kHz ≈ ~360 KB/min (vs ~960 KB/min before)
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 48000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _filePath!,
      );

      setState(() {
        _isRecording = true;
        _isPreview = false;
        _seconds = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _seconds++);
        if (_seconds >= _maxDurationSeconds) {
          _stopRecording();
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioRecorder] Start failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorHandler.friendlyMessage(e))),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      final path = await _recorder.stop();
      if (mounted && path != null) {
        _filePath = path;
        // Get file size for display
        final file = File(path);
        final sizeBytes = await file.length();
        final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
        setState(() {
          _isRecording = false;
          _isPreview = true;
          _recordedDuration = _seconds;
        });
        if (kDebugMode) {
          debugPrint('[AudioRecorder] File: $sizeMB MB, $_seconds seconds');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioRecorder] Stop failed: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_filePath == null) return;
    try {
      if (_isPlaying) {
        await _player.pause();
        setState(() => _isPlaying = false);
      } else {
        await _player.play(DeviceFileSource(_filePath!));
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioPlayer] Playback error: $e');
    }
  }

  Future<void> _reRecord() async {
    // Stop playback if playing
    await _player.stop();
    setState(() {
      _isPlaying = false;
      _isPreview = false;
      _seconds = 0;
    });
    // Delete old temp file
    if (_filePath != null) {
      try {
        await File(_filePath!).delete();
      } catch (_) {}
    }
    // Don't auto-start; let user tap Record
  }

  void _submitRecording() {
    _player.stop();
    if (_filePath != null && mounted) {
      Navigator.of(context).pop(_filePath);
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await _player.stop();
    if (_isRecording) {
      try {
        await _recorder.stop();
      } catch (_) {}
    }
    // Delete temp file
    if (_filePath != null) {
      try {
        await File(_filePath!).delete();
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerCompleteSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return const SizedBox.shrink();
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),

          // ── Icon indicator ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording
                  ? AppColors.error.withValues(alpha: 0.1)
                  : _isPreview
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              _isRecording
                  ? Icons.mic
                  : _isPreview
                      ? Icons.headphones_rounded
                      : Icons.mic_none,
              size: 40,
              color: _isRecording
                  ? AppColors.error
                  : _isPreview
                      ? AppColors.success
                      : AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // ── Timer / Duration ──
          Text(
            _isPreview
                ? _formatDuration(_recordedDuration)
                : _formatDuration(_seconds),
            style: AppTypography.h1.copyWith(
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),

          // ── Status text ──
          Text(
            _isRecording
                ? 'Recording... Tap stop when done'
                : _isPreview
                    ? 'Listen to your recording before sending'
                    : 'Tap the mic to start recording',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (_isRecording) ...[
            const SizedBox(height: 4),
            Text(
              'Max ${_maxDurationSeconds ~/ 60} min',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Action buttons ──
          if (_isPreview) ...[
            // Preview mode: Play + Re-record / Send
            FilledButton.icon(
              onPressed: _togglePlayback,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(_isPlaying ? 'Pause' : 'Play'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(200, 48),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Re-record
                OutlinedButton.icon(
                  onPressed: _reRecord,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Re-record'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Send
                FilledButton.icon(
                  onPressed: _submitRecording,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Idle / Recording mode
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel
                TextButton(
                  onPressed: _cancelRecording,
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                // Record / Stop
                FilledButton.icon(
                  onPressed:
                      _isRecording ? _stopRecording : _startRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(_isRecording ? 'Stop' : 'Record'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _isRecording ? AppColors.error : AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
