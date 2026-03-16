import 'dart:io';
import 'dart:math' as math;

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_limits.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/generation_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

/// Full-screen immersive wizard for creating a deck from a document.
/// Always dark, single vertical scroll, premium editorial experience.
class FirstDeckWizard extends ConsumerStatefulWidget {
  const FirstDeckWizard({super.key});

  @override
  ConsumerState<FirstDeckWizard> createState() => _FirstDeckWizardState();
}

class _FirstDeckWizardState extends ConsumerState<FirstDeckWizard> {
  // Step 1 — Upload
  String? _fileName;
  String? _uploadType; // 'pdf' | 'ocr'
  Uint8List? _fileBytes;
  bool _isPicking = false;

  // Step 2 — Flashcard count
  int _flashcardCount = 30;

  // Step 3 — Details
  final _courseNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Step 4 — Exam date
  DateTime? _examDate;

  // Processing
  bool _isCreating = false;
  String _creationPhase = '';

  @override
  void dispose() {
    _courseNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // File picking — preserved intact
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _pickPdf() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read the PDF. Please try again.')),
          );
        }
        return;
      }

      if (bytes.length > AppLimits.maxFileSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF too large. Maximum size is ${AppLimits.maxFileSizeMB} MB.')),
          );
        }
        return;
      }

      setState(() {
        _fileBytes = bytes;
        _fileName = file.name;
        _uploadType = 'pdf';
      });
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _scanPages() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 75,
      );
      if (image == null) return;

      final fileLength = await image.length();
      if (fileLength > AppLimits.maxFileSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image too large. Maximum size is ${AppLimits.maxFileSizeMB} MB.')),
          );
        }
        return;
      }

      final bytes = await image.readAsBytes();
      setState(() {
        _fileBytes = bytes;
        _fileName = 'Scanned Page';
        _uploadType = 'ocr';
      });
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Create & Generate pipeline — preserved intact
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _createAndGenerate() async {
    setState(() {
      _isCreating = true;
      _creationPhase = 'Checking access...';
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      // 1. Check feature access (OCR credits)
      final canUse = await checkFeatureAccess(
        ref: ref,
        feature: 'ocr',
        context: context,
      );
      if (!canUse) {
        setState(() => _isCreating = false);
        return;
      }

      // 2. Check plan limits for flashcard count
      final isPro = await ref.read(isProProvider.future);
      final effectiveCount = isPro ? _flashcardCount : _flashcardCount.clamp(1, 30);

      if (!isPro && _flashcardCount > 30) {
        if (mounted) context.push(Routes.paywall);
        setState(() => _isCreating = false);
        return;
      }

      // 3. Create course
      if (mounted) setState(() => _creationPhase = 'Creating your deck...');
      final courseName = _courseNameController.text.trim().isNotEmpty
          ? _courseNameController.text.trim()
          : _fileName?.replaceAll('.pdf', '').replaceAll('.PDF', '') ?? 'My First Deck';

      final course = await ref.read(courseRepositoryProvider).createCourse(
            userId: user.id,
            title: courseName,
            examDate: _examDate,
          );
      ref.invalidate(coursesProvider);

      // 4. Upload to Supabase Storage
      if (mounted) setState(() => _creationPhase = 'Uploading document...');
      final client = ref.read(supabaseClientProvider);
      final ext = _uploadType == 'pdf' ? 'pdf' : 'jpg';
      final storagePath = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await client.storage.from('course-materials').uploadBinary(storagePath, _fileBytes!);
      final fileUrl = client.storage.from('course-materials').getPublicUrl(storagePath);

      // 5. Process capture (OCR / PDF extraction)
      if (mounted) setState(() => _creationPhase = 'Processing document...');
      final material = await ref.read(materialRepositoryProvider).processCapture(
            courseId: course.id,
            type: _uploadType!,
            fileUrl: fileUrl,
            title: _fileName ?? 'Uploaded Document',
          );

      await recordFeatureUsage(ref: ref, feature: 'ocr');
      ref.invalidate(courseMaterialsProvider(course.id));
      ref.invalidate(recentMaterialsProvider);

      // 6. Start flashcard generation in background
      if (mounted) setState(() => _creationPhase = 'Starting generation...');
      ref.read(generationProvider.notifier).generateFlashcards(
            course.id,
            course.displayTitle,
            materialId: material.id,
            count: effectiveCount,
          );

      SoundService.playProcessingComplete();

      // 7. Navigate to course detail
      if (mounted) {
        context.go(Routes.courseDetailPath(course.id));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        AppErrorHandler.showError(e, context: context);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Build — Immersive dark vertical scroll
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Background gradient ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.immersiveDark,
              ),
            ),
          ),

          // ── Scrollable content ──
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                24,
                safeTop + 64,
                24,
                math.max(safeBottom, bottomInset) + 88,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Branding ──
                  const _WizardBranding(),
                  const SizedBox(height: 48),

                  // ── Step 1: Documents ──
                  const _ImmersiveStepHeader(number: 1, title: 'Documents'),
                  const SizedBox(height: 16),
                  _ImmersiveUploadZone(
                    fileName: _fileName,
                    uploadType: _uploadType,
                    isPicking: _isPicking,
                    onPickPdf: _pickPdf,
                    onClear: () => setState(() {
                      _fileBytes = null;
                      _fileName = null;
                      _uploadType = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  if (_fileName == null)
                    _UploadActionRow(
                      onPickPdf: _pickPdf,
                      onScanPages: _scanPages,
                      isPicking: _isPicking,
                    ),

                  const SizedBox(height: 48),

                  // ── Step 2: Number of Flashcards ──
                  const _ImmersiveStepHeader(
                    number: 2,
                    title: 'Number of Flashcards',
                  ),
                  const SizedBox(height: 24),
                  _FlashcardCountSection(
                    count: _flashcardCount,
                    onCountChanged: (c) =>
                        setState(() => _flashcardCount = c),
                  ),

                  const SizedBox(height: 48),

                  // ── Step 3: Details ──
                  const _ImmersiveStepHeader(
                    number: 3,
                    title: 'Details',
                    optional: true,
                  ),
                  const SizedBox(height: 16),
                  _ImmersiveTextField(
                    controller: _courseNameController,
                    hint: 'e.g. Biology Chapter 5',
                    icon: Icons.edit_note_rounded,
                    label: 'TITLE',
                  ),
                  const SizedBox(height: 12),
                  _ImmersiveTextField(
                    controller: _descriptionController,
                    hint: 'What is this deck about?',
                    icon: Icons.notes_rounded,
                    label: 'DESCRIPTION',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 48),

                  // ── Step 4: Exam Date ──
                  const _ImmersiveStepHeader(
                    number: 4,
                    title: 'Exam Date',
                    optional: true,
                  ),
                  const SizedBox(height: 16),
                  _HorizontalDatePills(
                    selectedDate: _examDate,
                    onDateSelected: (d) => setState(() => _examDate = d),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ── Floating back button ──
          Positioned(
            top: safeTop + 12,
            left: 16,
            child: _FloatingBackButton(
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // ── Sticky CTA at bottom ──
          Positioned(
            left: 24,
            right: 24,
            bottom: math.max(safeBottom, bottomInset) + 16,
            child: _ImmersiveCTA(
              label: 'Create Deck',
              isEnabled: _fileBytes != null,
              isLoading: _isCreating,
              loadingPhase: _creationPhase,
              onPressed: _createAndGenerate,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Branding — icon + title + subtitle
// ═══════════════════════════════════════════════════════════════════════════════

class _WizardBranding extends StatelessWidget {
  const _WizardBranding();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // Sparkle icon in rounded square with glow
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Create Your Deck',
            style: AppTypography.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a document and let Kapsa turn it\ninto smart flashcards',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Step header — numbered circle + title + optional badge
// ═══════════════════════════════════════════════════════════════════════════════

class _ImmersiveStepHeader extends StatelessWidget {
  final int number;
  final String title;
  final bool optional;

  const _ImmersiveStepHeader({
    required this.number,
    required this.title,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTypography.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.immersiveBorder,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'Optional',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Upload zone — two states: empty / file attached
// ═══════════════════════════════════════════════════════════════════════════════

class _ImmersiveUploadZone extends StatelessWidget {
  final String? fileName;
  final String? uploadType;
  final bool isPicking;
  final VoidCallback onPickPdf;
  final VoidCallback onClear;

  const _ImmersiveUploadZone({
    required this.fileName,
    required this.uploadType,
    required this.isPicking,
    required this.onPickPdf,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (fileName != null) {
      // ── File attached state ──
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (uploadType == 'pdf' ? AppColors.pdfRed : AppColors.info)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                uploadType == 'pdf' ? 'PDF' : 'SCAN',
                style: AppTypography.labelSmall.copyWith(
                  color: uploadType == 'pdf' ? AppColors.pdfRed : AppColors.info,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // File name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName!,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ready to process',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Check icon
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 22,
            ),
            const SizedBox(width: 8),
            // Change link
            TapScale(
              onTap: onClear,
              child: Text(
                'Change',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Empty upload zone ──
    return TapScale(
      onTap: isPicking ? null : onPickPdf,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        color: Colors.white.withValues(alpha: 0.15),
        dashPattern: const [8, 5],
        strokeWidth: 1.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.immersiveCard.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 44,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 16),
              Text(
                'Drop your files here or browse',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PDF \u00b7 Max ${AppLimits.maxFileSizeMB} MB',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
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
// Upload action row — PDF + Scan side by side
// ═══════════════════════════════════════════════════════════════════════════════

class _UploadActionRow extends StatelessWidget {
  final VoidCallback onPickPdf;
  final VoidCallback onScanPages;
  final bool isPicking;

  const _UploadActionRow({
    required this.onPickPdf,
    required this.onScanPages,
    required this.isPicking,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ImmersiveActionButton(
            icon: Icons.picture_as_pdf_rounded,
            label: 'Upload PDF',
            color: AppColors.pdfRed,
            onTap: isPicking ? null : onPickPdf,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ImmersiveActionButton(
            icon: Icons.camera_alt_rounded,
            label: 'Scan Pages',
            color: AppColors.info,
            onTap: isPicking ? null : onScanPages,
          ),
        ),
      ],
    );
  }
}

class _ImmersiveActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ImmersiveActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Flashcard count section — hero number + presets + slider
// ═══════════════════════════════════════════════════════════════════════════════

class _FlashcardCountSection extends ConsumerWidget {
  final int count;
  final ValueChanged<int> onCountChanged;

  const _FlashcardCountSection({
    required this.count,
    required this.onCountChanged,
  });

  static const _presets = [20, 30, 50, 80];
  static const _freeMax = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProAsync = ref.watch(isProProvider);
    final isPro = isProAsync.whenOrNull(data: (v) => v) ?? false;

    return Column(
      children: [
        // Hero number
        Center(
          child: Column(
            children: [
              Text(
                '$count',
                style: AppTypography.h1.copyWith(
                  fontFamily: 'Outfit',
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Flashcards',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Preset chips
        Row(
          children: _presets.map((preset) {
            final isSelected = count == preset;
            final isLocked = !isPro && preset > _freeMax;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: preset == _presets.first ? 0 : 4,
                  right: preset == _presets.last ? 0 : 4,
                ),
                child: TapScale(
                  onTap: () {
                    if (isLocked) {
                      HapticFeedback.mediumImpact();
                      context.push(Routes.paywall);
                    } else {
                      HapticFeedback.lightImpact();
                      onCountChanged(preset);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.immersiveCard,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.immersiveBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (isLocked) ...[
                          Icon(
                            Icons.lock_rounded,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          '$preset',
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : isLocked
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Subtle slider (always visible, secondary)
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary.withValues(alpha: 0.6),
            inactiveTrackColor: AppColors.immersiveBorder,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.08),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: count.toDouble().clamp(10, isPro ? 250 : _freeMax.toDouble()),
            min: 10,
            max: isPro ? 250 : _freeMax.toDouble(),
            divisions: isPro ? 48 : 4,
            onChanged: (v) {
              if (!isPro && v > _freeMax) {
                context.push(Routes.paywall);
                onCountChanged(_freeMax);
                return;
              }
              onCountChanged(v.round());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 11,
                ),
              ),
              Text(
                isPro ? '250' : '$_freeMax',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Immersive text field — dark, premium
// ═══════════════════════════════════════════════════════════════════════════════

class _ImmersiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String label;
  final int maxLines;

  const _ImmersiveTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.35),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.2),
            ),
            filled: true,
            fillColor: AppColors.immersiveCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: Colors.white.withValues(alpha: 0.25), size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.immersiveBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.immersiveBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Horizontal date pills — scrollable, 3 visual states
// ═══════════════════════════════════════════════════════════════════════════════

class _HorizontalDatePills extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  const _HorizontalDatePills({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<_HorizontalDatePills> createState() => _HorizontalDatePillsState();
}

class _HorizontalDatePillsState extends State<_HorizontalDatePills> {
  late final ScrollController _scrollController;
  static const _dayCount = 60;
  static const _weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 88,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _dayCount,
        itemBuilder: (context, index) {
          final date = today.add(Duration(days: index));
          final isToday = index == 0;
          final isSelected = widget.selectedDate != null &&
              _isSameDay(date, widget.selectedDate!);

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 6,
              right: index == _dayCount - 1 ? 0 : 6,
            ),
            child: TapScale(
              onTap: () {
                if (isSelected) {
                  widget.onDateSelected(null); // deselect
                } else {
                  widget.onDateSelected(
                    DateTime(date.year, date.month, date.day, 9, 0),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.immersiveCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.immersiveBorder,
                    width: isToday && !isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // TODAY label or weekday
                    if (isToday)
                      Text(
                        'TODAY',
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      )
                    else
                      Text(
                        _weekdays[date.weekday % 7],
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Day number
                    Text(
                      '${date.day}',
                      style: AppTypography.h4.copyWith(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Month abbreviation
                    Text(
                      _months[date.month - 1],
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.2),
                        fontWeight: FontWeight.w500,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Floating back button
// ═══════════════════════════════════════════════════════════════════════════════

class _FloatingBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.immersiveCard,
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Immersive CTA — lime, sticky bottom, SafeArea-aware
// ═══════════════════════════════════════════════════════════════════════════════

class _ImmersiveCTA extends StatelessWidget {
  final String label;
  final bool isEnabled;
  final bool isLoading;
  final String loadingPhase;
  final VoidCallback onPressed;

  const _ImmersiveCTA({
    required this.label,
    required this.isEnabled,
    required this.isLoading,
    required this.loadingPhase,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.immersiveBorder,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 3,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loadingPhase,
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return TapScale(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.35,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.ctaLime,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.ctaLime.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.ctaLimeText,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.ctaLimeText,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
