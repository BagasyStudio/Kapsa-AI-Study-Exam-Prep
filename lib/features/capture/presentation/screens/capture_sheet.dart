import 'dart:async';
import 'dart:io';
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
import '../../../../core/widgets/animated_counter.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Bottom sheet modal for capturing new study materials.
///
/// Covers 92% of screen, shows 2x2 action grid + recent captures.
class CaptureSheet extends ConsumerStatefulWidget {
  /// If provided, skips the course picker and uses this course directly.
  final String? courseId;

  const CaptureSheet({super.key, this.courseId});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  String _realPhase = 'uploading'; // 'uploading' | 'analyzing' | 'done'
  String _processingType = 'ocr'; // 'ocr' | 'pdf' | 'whisper'
  String _materialName = '';
  String? _pendingPopMessage; // message to pop with after animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  /// Ensure the Supabase JWT is fresh before storage operations.
  /// Storage SDK doesn't auto-refresh like the Functions wrapper does.
  Future<void> _ensureFreshToken() async {
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (session == null) return;
    // Refresh if token expires within 2 minutes
    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final expiresIn = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)
          .difference(DateTime.now())
          .inSeconds;
      if (expiresIn < 120) {
        debugPrint('CaptureSheet: refreshing JWT (expires in ${expiresIn}s)');
        await ref.read(supabaseClientProvider).auth.refreshSession();
      }
    }
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
      _realPhase = 'uploading';
      _processingType = 'ocr';
      _materialName = 'Scanned Page';
    });

    try {
      final imageBytes = await image.readAsBytes();

      // Ensure fresh JWT before storage upload
      await _ensureFreshToken();

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
        setState(() => _realPhase = 'analyzing');
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
        // Let the animation finish gracefully before popping
        setState(() {
          _realPhase = 'done';
          _pendingPopMessage = 'Scanned and processed: ${material.displayTitle}';
        });
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
      _realPhase = 'uploading';
      _processingType = 'whisper';
      _materialName = 'Recording - ${DateTime.now().day}/${DateTime.now().month}';
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

      await _ensureFreshToken();

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
        setState(() => _realPhase = 'analyzing');
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
      } catch (e) {
        debugPrint('CaptureSheet: temp file cleanup failed: $e');
      }

      // Refresh materials lists so new material appears immediately
      ref.invalidate(courseMaterialsProvider(courseId));
      ref.invalidate(recentMaterialsProvider);

      if (mounted) {
        SoundService.playProcessingComplete();
        setState(() {
          _realPhase = 'done';
          _pendingPopMessage = 'Transcribed: ${material.displayTitle}';
        });
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

    // Get bytes: prefer file.bytes (web), fall back to file.path (mobile)
    Uint8List? fileBytes = file.bytes;
    if (fileBytes == null && file.path != null) {
      try {
        fileBytes = await File(file.path!).readAsBytes();
      } catch (e) {
        debugPrint('CaptureSheet: reading PDF bytes failed: $e');
      }
    }
    if (fileBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not read the PDF. Please try again.')),
        );
      }
      return;
    }

    // Validate file size (25 MB max)
    if (fileBytes.length > AppLimits.maxFileSizeBytes) {
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
      _realPhase = 'uploading';
      _processingType = 'pdf';
      _materialName = file.name;
    });

    try {
      await _ensureFreshToken();

      final client = ref.read(supabaseClientProvider);
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.pdf';
      await client.storage
          .from('course-materials')
          .uploadBinary(fileName, fileBytes);
      final fileUrl =
          client.storage.from('course-materials').getPublicUrl(fileName);

      if (mounted) {
        setState(() => _realPhase = 'analyzing');
      }

      // Extract text from PDF (direct extraction, no AI needed)
      final material = await ref
          .read(materialRepositoryProvider)
          .processCapture(
            courseId: courseId,
            type: 'pdf',
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
        setState(() {
          _realPhase = 'done';
          _pendingPopMessage = 'Uploaded and processed: ${material.displayTitle}';
        });
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
      _realPhase = 'analyzing';
      _processingType = 'paste';
      _materialName = 'Quick Note';
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
        setState(() => _isProcessing = false);
        Navigator.of(context)
            .pop('Saved: ${material.displayTitle}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppErrorHandler.showError(e, context: context);
      }
    }
  }

  Future<String?> _pickCourse(List<CourseModel> courses) async {
    // If a course was pre-selected (opened from course detail), use it directly
    if (widget.courseId != null) return widget.courseId;

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
                title: Text(course.displayTitle),
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

  void _cancelProcessing() {
    setState(() {
      _isProcessing = false;
      _pendingPopMessage = null;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final recentAsync = ref.watch(recentMaterialsProvider);

    return PopScope(
      canPop: !_isProcessing,
      onPopInvokedWithResult: (didPop, result) {
        // When processing, system back press is blocked by canPop.
      },
      child: Container(
              decoration: BoxDecoration(
                color: AppColors.immersiveSurface,
                borderRadius: AppRadius.borderRadiusSheet,
                border: Border.all(
                  color: AppColors.immersiveBorder,
                ),
              ),
              child: Column(
                children: [
                  // Close button + drag handle row
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Drag handle centered
                        Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: AppRadius.borderRadiusPill,
                          ),
                        ),
                        // Close button right-aligned
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Content
                  Expanded(
                    child: _isProcessing
                        ? _processingType == 'paste'
                            ? _SimplePasteProgress(
                                pulseAnimation: _pulseController,
                              )
                            : _EnhancedProcessingView(
                                type: _processingType,
                                realPhase: _realPhase,
                                materialName: _materialName,
                                pulseAnimation: _pulseController,
                                onCancel: _cancelProcessing,
                                onAnimationComplete: () {
                                  if (mounted && _pendingPopMessage != null) {
                                    final msg = _pendingPopMessage;
                                    _pendingPopMessage = null;
                                    Navigator.of(context).pop(msg);
                                  }
                                },
                              )
                        : ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            children: [
                              const SizedBox(height: AppSpacing.md),

                              // Header
                              Center(
                                child: Text(
                                  'New Capture',
                                  style: AppTypography.h2.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Text(
                                  'Choose how you want to add materials',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white60,
                                  ),
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
                                  childAspectRatio: 0.85,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  children: [
                                    _CaptureAction(
                                      icon: Icons.photo_camera_rounded,
                                      label: 'Scan Pages',
                                      subtitle: 'Photos to text in seconds',
                                      onTap: () => _scanPages(courses),
                                    ),
                                    _CaptureAction(
                                      icon: Icons.graphic_eq_rounded,
                                      label: 'Record &\nTranscribe',
                                      subtitle: 'Voice to study notes',
                                      onTap: () =>
                                          _recordAndTranscribe(courses),
                                    ),
                                    _CaptureAction(
                                      icon: Icons.picture_as_pdf_rounded,
                                      label: 'Upload PDF',
                                      subtitle: 'Extract summaries & cards',
                                      onTap: () => _uploadPdf(courses),
                                    ),
                                    _CaptureAction(
                                      icon: Icons.content_paste_rounded,
                                      label: 'Quick Paste',
                                      subtitle: 'Paste text from anywhere',
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
                                    style: AppTypography.sectionHeader.copyWith(
                                      color: Colors.white60,
                                    ),
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
                                                  bottom: AppSpacing.md),
                                              child: _RecentItem(
                                                icon: _iconForType(m.type),
                                                title: m.displayTitle,
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
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: AppRadius.borderRadiusPill,
                                    border: Border.all(
                                      color: AppColors.immersiveBorder,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Cancel',
                                      style:
                                          AppTypography.labelLarge.copyWith(
                                        color: Colors.white60,
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
  final String? subtitle;
  final VoidCallback onTap;

  const _CaptureAction({
    required this.icon,
    required this.label,
    this.subtitle,
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
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTypography.caption.copyWith(
                color: Colors.white38,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
        color: AppColors.immersiveCard,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.immersiveBorder,
        ),
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
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
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
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: Colors.white38,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Simple Paste Progress (quick — no mega animation)
// ═══════════════════════════════════════════

class _SimplePasteProgress extends StatelessWidget {
  final AnimationController pulseAnimation;

  const _SimplePasteProgress({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (_, __) {
              final scale = 1.0 + (pulseAnimation.value * 0.12);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 80,
                  height: 80,
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
                  child: const Icon(
                    Icons.save_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l.captureSavingNote,
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Floating Particles (ambient processing effect)
// ═══════════════════════════════════════════

class _Particle {
  double x, y, speed, size, alpha, drift;
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.alpha,
    required this.drift,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  _ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = color.withValues(alpha: p.alpha);
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

class _FloatingParticles extends StatefulWidget {
  final double width;
  final double height;
  const _FloatingParticles({this.width = 160, this.height = 160});

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  static const _count = 14;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(_count, (_) => _randomParticle());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_tick)..repeat();
  }

  _Particle _randomParticle() {
    final r = DateTime.now().microsecondsSinceEpoch;
    return _Particle(
      x: 0.3 + ((r % 100) / 250),
      y: 0.7 + ((r % 73) / 250),
      speed: 0.003 + ((r % 50) / 10000),
      size: 1.5 + ((r % 40) / 20),
      alpha: 0.15 + ((r % 60) / 150),
      drift: ((r % 100) - 50) / 8000,
    );
  }

  void _tick() {
    if (!mounted) return;
    for (var i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.y -= p.speed;
      p.x += p.drift + 0.001 * (0.5 - p.x).sign * ((i % 3) == 0 ? 1 : -1);
      p.alpha = (p.alpha - 0.001).clamp(0.05, 0.6);
      if (p.y < 0.05 || p.alpha <= 0.05) {
        _particles[i] = _Particle(
          x: 0.3 + ((DateTime.now().microsecondsSinceEpoch + i * 17) % 100) / 250,
          y: 0.85 + ((DateTime.now().microsecondsSinceEpoch + i * 31) % 30) / 200,
          speed: 0.003 + ((DateTime.now().microsecondsSinceEpoch + i * 7) % 50) / 10000,
          size: 1.5 + ((DateTime.now().microsecondsSinceEpoch + i * 13) % 40) / 20,
          alpha: 0.2 + ((DateTime.now().microsecondsSinceEpoch + i * 23) % 60) / 150,
          drift: ((DateTime.now().microsecondsSinceEpoch + i * 11) % 100 - 50) / 8000,
        );
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: _ParticlePainter(
        particles: _particles,
        color: AppColors.primaryLight,
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Rotating Ring (dashed circle around orb)
// ═══════════════════════════════════════════

class _RingPainter extends CustomPainter {
  final double rotation;
  final Color color;
  _RingPainter({required this.rotation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * 3.14159);
    canvas.translate(-center.dx, -center.dy);

    // Draw 8 arcs with gaps
    const arcCount = 8;
    const sweepAngle = 0.55; // radians per arc
    const gapAngle = (2 * 3.14159 - arcCount * sweepAngle) / arcCount;
    for (var i = 0; i < arcCount; i++) {
      final startAngle = i * (sweepAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.rotation != rotation;
}

// ═══════════════════════════════════════════
// Enhanced Processing View (mega animation)
// ═══════════════════════════════════════════

class _EnhancedProcessingView extends StatefulWidget {
  final String type; // 'ocr' | 'pdf' | 'whisper'
  final String realPhase; // 'uploading' | 'analyzing' | 'done'
  final String materialName;
  final AnimationController pulseAnimation;
  final VoidCallback onAnimationComplete;
  final VoidCallback? onCancel;

  const _EnhancedProcessingView({
    required this.type,
    required this.realPhase,
    required this.materialName,
    required this.pulseAnimation,
    required this.onAnimationComplete,
    this.onCancel,
  });

  @override
  State<_EnhancedProcessingView> createState() =>
      _EnhancedProcessingViewState();
}

class _EnhancedProcessingViewState extends State<_EnhancedProcessingView>
    with SingleTickerProviderStateMixin {
  static const _stepCount = 7;
  int _currentStep = 0;
  bool _realDone = false;
  Timer? _stepTimer;
  late AnimationController _ringController;

  // Icons per step
  static const _stepIcons = <IconData>[
    Icons.cloud_upload_rounded,
    Icons.document_scanner_rounded,
    Icons.psychology_rounded,
    Icons.edit_note_rounded,
    Icons.auto_awesome_rounded,
    Icons.bar_chart_rounded,
    Icons.celebration_rounded,
  ];

  List<({String loading, String done})> _getSteps(AppLocalizations l) {
    switch (widget.type) {
      case 'pdf':
        return [
          (loading: l.capturePdfUploading, done: '\u2713 ${l.capturePdfUploaded}'),
          (loading: l.capturePdfParsing, done: '\u2713 ${l.capturePdfParsed}'),
          (loading: l.capturePdfAnalyzing, done: '\u2713 ${l.capturePdfAnalyzed}'),
          (loading: l.capturePdfExtracting, done: '\u2713 ${l.capturePdfExtracted}'),
          (loading: l.capturePdfConcepts, done: '\u2713 ${l.capturePdfConceptsDone}'),
          (loading: l.capturePdfFormatting, done: '\u2713 ${l.capturePdfFormattingDone}'),
          (loading: l.capturePdfFinishing, done: '\u2713 ${l.capturePdfReady}'),
        ];
      case 'whisper':
        return [
          (loading: l.captureWhisperUploading, done: '\u2713 ${l.captureWhisperUploaded}'),
          (loading: l.captureWhisperSignal, done: '\u2713 ${l.captureWhisperSignalDone}'),
          (loading: l.captureWhisperSpeech, done: '\u2713 ${l.captureWhisperSpeechDone}'),
          (loading: l.captureWhisperTranscribing, done: '\u2713 ${l.captureWhisperTranscribed}'),
          (loading: l.captureWhisperFormatting, done: '\u2713 ${l.captureWhisperFormattingDone}'),
          (loading: l.captureWhisperCleaning, done: '\u2713 ${l.captureWhisperCleaningDone}'),
          (loading: l.captureWhisperFinishing, done: '\u2713 ${l.captureWhisperReady}'),
        ];
      default: // ocr
        return [
          (loading: l.captureOcrUploading, done: '\u2713 ${l.captureOcrUploaded}'),
          (loading: l.captureOcrScanning, done: '\u2713 ${l.captureOcrScanned}'),
          (loading: l.captureOcrRecognizing, done: '\u2713 ${l.captureOcrRecognized}'),
          (loading: l.captureOcrExtracting, done: '\u2713 ${l.captureOcrExtracted}'),
          (loading: l.captureOcrFormatting, done: '\u2713 ${l.captureOcrFormattingDone}'),
          (loading: l.captureOcrOrganizing, done: '\u2713 ${l.captureOcrOrganized}'),
          (loading: l.captureOcrFinishing, done: '\u2713 ${l.captureOcrReady}'),
        ];
    }
  }

  String _getTitle(AppLocalizations l) {
    switch (widget.type) {
      case 'pdf':
        return l.captureProcessingPdf;
      case 'whisper':
        return l.captureProcessingWhisper;
      default:
        return l.captureProcessingOcr;
    }
  }

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _startStepTimer();
  }

  @override
  void didUpdateWidget(_EnhancedProcessingView old) {
    super.didUpdateWidget(old);
    // Detect phase changes
    if (widget.realPhase != old.realPhase) {
      if (widget.realPhase == 'analyzing' && _currentStep < 2) {
        // Real upload finished — jump to analysis steps
        setState(() => _currentStep = 2);
      }
      if (widget.realPhase == 'done') {
        _realDone = true;
        // Accelerate: finish remaining steps quickly
        _stepTimer?.cancel();
        _accelerateToEnd();
      }
    }
  }

  void _startStepTimer() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) {
        _stepTimer?.cancel();
        return;
      }

      // Don't advance past step 5 until real processing is done
      if (_currentStep >= 5 && !_realDone) return;

      if (_currentStep < _stepCount - 1) {
        setState(() => _currentStep++);
      } else {
        // Animation complete
        _stepTimer?.cancel();
        if (_realDone) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) widget.onAnimationComplete();
          });
        }
      }
    });
  }

  void _accelerateToEnd() {
    // Rapidly complete remaining steps
    Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentStep < _stepCount - 1) {
        setState(() => _currentStep++);
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) widget.onAnimationComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  double get _progress => (_currentStep + 1) / _stepCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final steps = _getSteps(l);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),

            // ── Multi-layered Neural Orb ──
            SizedBox(
              width: 160,
              height: 160,
              child: AnimatedBuilder(
                animation: Listenable.merge([widget.pulseAnimation, _ringController]),
                builder: (_, __) {
                  final pulse = widget.pulseAnimation.value;
                  final scale = 0.93 + (pulse * 0.07);
                  final glowAlpha = 0.10 + (pulse * 0.12) + (_progress * 0.08);

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Layer 1: Outer ambient glow
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: glowAlpha * 0.6),
                              blurRadius: 60 + pulse * 20,
                              spreadRadius: 10 + _progress * 15,
                            ),
                          ],
                        ),
                      ),

                      // Layer 2: Rotating dashed ring
                      SizedBox(
                        width: 134,
                        height: 134,
                        child: CustomPaint(
                          painter: _RingPainter(
                            rotation: _ringController.value,
                            color: AppColors.primary.withValues(alpha: 0.20 + pulse * 0.10),
                          ),
                        ),
                      ),

                      // Layer 3: Floating particles
                      const _FloatingParticles(width: 160, height: 160),

                      // Layer 4: Main orb body
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.2, -0.3),
                              colors: [
                                Colors.white.withValues(alpha: 0.22),
                                AppColors.primaryLight,
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                              stops: const [0.0, 0.25, 0.6, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35 + _progress * 0.15),
                                blurRadius: 25,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: AppColors.primaryDark.withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: Tween(begin: 0.6, end: 1.0).animate(
                                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                                ),
                                child: FadeTransition(opacity: animation, child: child),
                              );
                            },
                            child: Icon(
                              _stepIcons[_currentStep.clamp(0, _stepIcons.length - 1)],
                              key: ValueKey(_currentStep),
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Title with slide-fade transition ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween(begin: const Offset(0, 0.3), end: Offset.zero)
                      .animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                _currentStep == steps.length - 1 && _realDone
                    ? l.captureProcessingDone
                    : _getTitle(l),
                key: ValueKey(_currentStep == steps.length - 1 && _realDone),
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 4),

            // ── Subtitle with slide-fade ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween(begin: const Offset(0, 0.2), end: Offset.zero)
                      .animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                steps[_currentStep].loading,
                key: ValueKey('sub_$_currentStep'),
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white38,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Shimmer gradient progress bar ──
            SizedBox(
              height: 8,
              child: Stack(
                children: [
                  // Background track
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: AppColors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  // Animated fill
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        widthFactor: value.clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                                AppColors.primary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  begin: Alignment(-1.0 + (DateTime.now().millisecondsSinceEpoch % 2000) / 1000, 0),
                                  end: Alignment(-0.5 + (DateTime.now().millisecondsSinceEpoch % 2000) / 1000, 0),
                                  colors: [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcATop,
                              child: Container(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── Animated percentage counter ──
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedCounter(
                value: (_progress * 100).round(),
                suffix: '%',
                duration: const Duration(milliseconds: 600),
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Enhanced step cards ──
            ...List.generate(steps.length, (i) {
              final isComplete = i < _currentStep;
              final isCurrent = i == _currentStep;
              final step = steps[i];
              final pulseVal = widget.pulseAnimation.value;

              return AnimatedBuilder(
                animation: widget.pulseAnimation,
                builder: (_, __) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isComplete
                          ? LinearGradient(colors: [
                              AppColors.success.withValues(alpha: 0.08),
                              AppColors.success.withValues(alpha: 0.03),
                            ])
                          : null,
                      color: isComplete
                          ? null
                          : isCurrent
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.025),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isComplete
                            ? AppColors.success.withValues(alpha: 0.20)
                            : isCurrent
                                ? AppColors.primary.withValues(
                                    alpha: 0.12 + pulseVal * 0.12,
                                  )
                                : Colors.transparent,
                        width: isCurrent ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Status icon with bounce animation
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, anim) {
                              return ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutBack,
                                ),
                                child: child,
                              );
                            },
                            child: isComplete
                                ? Container(
                                    key: ValueKey('done_$i'),
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.success,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  )
                                : isCurrent
                                    ? SizedBox(
                                        key: ValueKey('spin_$i'),
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : Icon(
                                        Icons.circle_outlined,
                                        key: ValueKey('wait_$i'),
                                        size: 20,
                                        color: Colors.white.withValues(alpha: 0.15),
                                      ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Text
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: AppTypography.bodyMedium.copyWith(
                              color: isComplete
                                  ? AppColors.success
                                  : isCurrent
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.25),
                              fontWeight: isCurrent || isComplete
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            child: Text(
                              isComplete ? step.done : step.loading,
                              key: ValueKey('text_${i}_$isComplete'),
                            ),
                          ),
                        ),
                        // Trailing step icon
                        if (isComplete || isCurrent)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              _stepIcons[i],
                              size: 14,
                              color: isComplete
                                  ? AppColors.success.withValues(alpha: 0.45)
                                  : AppColors.primary.withValues(alpha: 0.35),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            }),

            const SizedBox(height: AppSpacing.lg),

            // ── Close / Cancel button ──
            if (widget.onCancel != null)
              GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppColors.immersiveBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      l.commonCancel,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.xl),
          ],
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
      } catch (e) {
        debugPrint('CaptureSheet: delete old temp file failed: $e');
      }
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
      } catch (e) {
        debugPrint('CaptureSheet: stopping recorder failed: $e');
      }
    }
    // Delete temp file
    if (_filePath != null) {
      try {
        await File(_filePath!).delete();
      } catch (e) {
        debugPrint('CaptureSheet: delete temp file on cancel failed: $e');
      }
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
                color: Colors.white38,
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
                    foregroundColor: Colors.white60,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white60),
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
