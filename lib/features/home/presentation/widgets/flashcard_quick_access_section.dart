import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_limits.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/shimmer_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/providers/generation_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../providers/flashcard_quick_access_provider.dart';
import 'flashcard_quick_access_card.dart';

/// Horizontal scrollable section showing flashcard decks on the home screen.
///
/// Gives users one-tap access to their flashcard decks without navigating
/// through courses. Shows a "Create New" card as the first item always.
class FlashcardQuickAccessSection extends ConsumerWidget {
  const FlashcardQuickAccessSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(flashcardQuickAccessProvider);
    final l = AppLocalizations.of(context)!;

    return decksAsync.when(
      loading: () => _buildShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (decks) {
        final totalDue = ref
            .watch(totalDueCardsProvider)
            .whenOrNull(data: (c) => c) ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.style_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l.homeFlashcards,
                    style: AppTypography.sectionHeader,
                  ),
                  const Spacer(),
                  if (totalDue > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF59E0B)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 12,
                            color: Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l.homeDue(totalDue),
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Horizontal deck list with Create New as first card
            SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                itemCount: decks.length + 1, // +1 for Create New
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: _CreateNewDeckCard(
                        onTap: () => _showCreateDeckSheet(context, ref),
                      ),
                    );
                  }
                  final item = decks[index - 1];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < decks.length ? AppSpacing.md : 0,
                    ),
                    child: FlashcardQuickAccessCard(
                      deck: item.deck,
                      courseName: item.courseName,
                      onQuickReview: () => context.push(
                        Routes.srsReviewPath(item.deck.courseId),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateDeckSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CreateDeckBottomSheet(parentRef: ref),
    );
  }

  /// Loading shimmer placeholder.
  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Create New Deck Card
// ═══════════════════════════════════════════════════════════════════════════════

class _CreateNewDeckCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateNewDeckCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return TapScale(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6467F2).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.flashcardCreateNew,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Create Deck Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _CreateDeckBottomSheet extends ConsumerStatefulWidget {
  final WidgetRef parentRef;
  const _CreateDeckBottomSheet({required this.parentRef});

  @override
  ConsumerState<_CreateDeckBottomSheet> createState() =>
      _CreateDeckBottomSheetState();
}

class _CreateDeckBottomSheetState
    extends ConsumerState<_CreateDeckBottomSheet> {
  String? _selectedCourseId;
  String? _selectedCourseName;
  double _cardCount = 30;

  // ── Document upload state ──
  String? _fileName;
  String? _uploadType; // 'pdf' | 'ocr'
  Uint8List? _fileBytes;
  bool _isPicking = false;
  bool _isProcessing = false;

  // ── File picking ──

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
      if (bytes == null) return;
      if (bytes.length > AppLimits.maxFileSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF too large. Max ${AppLimits.maxFileSizeMB} MB.')),
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

  Future<void> _scanPhoto() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 75,
      );
      if (image == null) return;
      if (await image.length() > AppLimits.maxFileSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image too large. Max ${AppLimits.maxFileSizeMB} MB.')),
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

  void _clearFile() {
    setState(() {
      _fileBytes = null;
      _fileName = null;
      _uploadType = null;
    });
  }

  // ── Generate (with optional document pipeline) ──

  Future<void> _generate() async {
    HapticFeedback.mediumImpact();

    // If no course selected, auto-create one from the uploaded file name
    if (_selectedCourseId == null) {
      if (_fileBytes == null) {
        // No course AND no file → show hint
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a course or upload a document first.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Auto-create course from file name
      setState(() => _isProcessing = true);
      try {
        final user = ref.read(currentUserProvider);
        if (user == null) throw Exception('Not authenticated');

        final courseName = _fileName != null
            ? _fileName!.replaceAll(RegExp(r'\.(pdf|jpg|png|jpeg)$', caseSensitive: false), '')
            : 'New Course';

        final course = await ref.read(courseRepositoryProvider).createCourse(
              userId: user.id,
              title: courseName,
            );
        _selectedCourseId = course.id;
        _selectedCourseName = course.title;
        ref.invalidate(coursesProvider);
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not create course: $e')),
          );
        }
        return;
      }
    }

    // No document → generate directly
    if (_fileBytes == null) {
      widget.parentRef.read(generationProvider.notifier).generateFlashcards(
            _selectedCourseId!,
            _selectedCourseName ?? '',
            count: _cardCount.round(),
          );
      Navigator.of(context).pop();
      return;
    }

    // With document → upload, process, then generate
    setState(() => _isProcessing = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      // Check OCR feature access
      final canUse = await checkFeatureAccess(
        ref: ref,
        feature: 'ocr',
        context: context,
      );
      if (!canUse) {
        setState(() => _isProcessing = false);
        return;
      }

      // Upload to Supabase Storage
      final client = ref.read(supabaseClientProvider);
      final ext = _uploadType == 'pdf' ? 'pdf' : 'jpg';
      final storagePath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await client.storage
          .from('course-materials')
          .uploadBinary(storagePath, _fileBytes!);
      final fileUrl =
          client.storage.from('course-materials').getPublicUrl(storagePath);

      // Process capture (OCR / PDF text extraction)
      final material =
          await ref.read(materialRepositoryProvider).processCapture(
                courseId: _selectedCourseId!,
                type: _uploadType!,
                fileUrl: fileUrl,
                title: _fileName ?? 'Uploaded Document',
              );

      await recordFeatureUsage(ref: ref, feature: 'ocr');
      ref.invalidate(courseMaterialsProvider(_selectedCourseId!));

      // Start flashcard generation with materialId
      widget.parentRef.read(generationProvider.notifier).generateFlashcards(
            _selectedCourseId!,
            _selectedCourseName ?? '',
            materialId: material.id,
            count: _cardCount.round(),
          );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppErrorHandler.showError(e, context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final coursesAsync = ref.watch(coursesProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.immersiveSurface.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.immersiveBorder),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        MediaQuery.of(context).padding.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            l.flashcardCreateDeck,
            style: AppTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Course selector
          Text(
            l.flashcardSelectCourse,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          coursesAsync.when(
            loading: () => const SizedBox(
              height: 56,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
            error: (e, _) => const SizedBox.shrink(),
            data: (courses) {
              if (courses.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final isSelected = course.id == _selectedCourseId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TapScale(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCourseId = course.id;
                            _selectedCourseName = course.displayTitle;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(course.icon, size: 18, color: course.color),
                              const SizedBox(width: 8),
                              Text(
                                course.displayTitle,
                                style: AppTypography.labelMedium.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_circle,
                                    color: AppColors.primary, size: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Document upload (optional) ──
          Text(
            l.flashcardUploadDoc,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (_fileBytes == null)
            // Upload buttons row
            Row(
              children: [
                Expanded(
                  child: TapScale(
                    onTap: _isPicking ? null : _pickPdf,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.flashcardUploadPdf,
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TapScale(
                    onTap: _isPicking ? null : _scanPhoto,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.flashcardUploadPhoto,
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // File preview chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _uploadType == 'pdf'
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _fileName ?? '',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TapScale(
                    onTap: _clearFile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l.flashcardUploadChange,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.xl),

          // Card count slider
          Text(
            l.flashcardCardCount,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '${_cardCount.round()}',
                style: AppTypography.h2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.flashcardCards,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF6467F2),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF6467F2).withValues(alpha: 0.2),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Builder(
              builder: (context) {
                final isPro = ref.watch(isProProvider).valueOrNull ?? false;
                final maxCards = isPro ? 250.0 : 30.0;
                final divisions = isPro ? 24 : 4;
                // Clamp current value to max if user was Pro and lost it
                if (_cardCount > maxCards) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _cardCount = maxCards);
                  });
                }
                return Slider(
                  value: _cardCount.clamp(10, maxCards),
                  min: 10,
                  max: maxCards,
                  divisions: divisions,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _cardCount = v);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('10', style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 11,
                )),
                Text('50', style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 11,
                )),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Generate button
          if (_isProcessing)
            SizedBox(
              height: 54,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l.flashcardUploadProcessing,
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ShimmerButton(
              label: l.flashcardGenerate,
              icon: Icons.auto_awesome,
              onPressed: _selectedCourseId == null ? null : _generate,
              height: 54,
            ),
        ],
      ),
    );
  }
}
