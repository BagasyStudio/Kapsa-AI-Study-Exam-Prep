import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/providers/generation_provider.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../providers/summary_provider.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  final String summaryId;

  const SummaryScreen({super.key, required this.summaryId});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  bool _isPlaying = false;
  Set<int> _starredBullets = {};

  // -- Edit mode --
  bool _isEditing = false;
  bool _isSaving = false;
  final List<TextEditingController> _bulletControllers = [];
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStarredBullets();
  }

  // -- Starred bullets persistence --
  Future<void> _loadStarredBullets() async {
    final prefs = await SharedPreferences.getInstance();
    final stored =
        prefs.getStringList('starred_bullets_${widget.summaryId}') ?? [];
    setState(() {
      _starredBullets = stored.map((e) => int.parse(e)).toSet();
    });
  }

  Future<void> _toggleStarred(int index) async {
    HapticFeedback.lightImpact();
    setState(() {
      if (_starredBullets.contains(index)) {
        _starredBullets.remove(index);
      } else {
        _starredBullets.add(index);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'starred_bullets_${widget.summaryId}',
      _starredBullets.map((e) => e.toString()).toList(),
    );
  }

  // -- Rename --
  Future<void> _showRenameDialog(String currentTitle) async {
    final controller = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.immersiveCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Rename Summary',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'Enter new title',
            hintStyle:
                AppTypography.bodyMedium.copyWith(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(
              'Rename',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newTitle != null && newTitle.isNotEmpty && newTitle != currentTitle) {
      await ref
          .read(summaryRepositoryProvider)
          .renameSummary(widget.summaryId, newTitle);
      ref.invalidate(summaryProvider(widget.summaryId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Summary renamed \u2713'),
            backgroundColor: AppColors.immersiveCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int _estimateReadMinutes(int wordCount) =>
      (wordCount / 200).ceil().clamp(1, 99);

  void _shareSummary({
    required String title,
    required List<String> bulletPoints,
    required String content,
  }) {
    HapticFeedback.mediumImpact();
    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln();

    if (bulletPoints.isNotEmpty) {
      buffer.writeln('Key Takeaways:');
      for (final point in bulletPoints) {
        buffer.writeln('  \u2022 $point');
      }
      buffer.writeln();
    }

    buffer.writeln(content);

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  // -- Edit mode helpers --
  void _enterEditMode(List<String> bulletPoints, String content) {
    HapticFeedback.lightImpact();

    // Dispose any existing controllers before creating new ones
    for (final c in _bulletControllers) {
      c.dispose();
    }
    _bulletControllers.clear();

    for (final bp in bulletPoints) {
      _bulletControllers.add(TextEditingController(text: bp));
    }
    _contentController.text = content;

    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    HapticFeedback.lightImpact();
    setState(() => _isEditing = false);
  }

  Future<void> _saveEdit() async {
    setState(() => _isSaving = true);

    final updatedBullets = _bulletControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final updatedContent = _contentController.text.trim();

    try {
      await ref.read(summaryRepositoryProvider).updateSummaryContent(
            widget.summaryId,
            bulletPoints: updatedBullets,
            content: updatedContent,
          );
      ref.invalidate(summaryProvider(widget.summaryId));
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Summary updated \u2713'),
            backgroundColor: AppColors.immersiveCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${AppErrorHandler.friendlyMessage(e)}'),
            backgroundColor: AppColors.immersiveCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleTts(String summaryText) async {
    if (_isPlaying) {
      await TtsService.instance.stop();
    } else {
      await TtsService.instance.speak(summaryText);
    }
    if (mounted) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _generateQuiz(String courseId) {
    HapticFeedback.mediumImpact();

    final notifier = ref.read(generationProvider.notifier);
    if (notifier.isRunning(GenerationType.quiz, courseId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Already generating quiz...'),
          backgroundColor: AppColors.immersiveCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final course = ref.read(courseProvider(courseId)).valueOrNull;
    final courseName = course?.displayTitle ?? 'Course';

    notifier.generateQuiz(courseId, courseName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Generating quiz...'),
          ],
        ),
        backgroundColor: AppColors.immersiveCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _isExportingPdf = false;

  Future<void> _exportToPdf({
    required String title,
    required List<String> bulletPoints,
    required String content,
  }) async {
    if (_isExportingPdf) return;
    HapticFeedback.mediumImpact();
    setState(() => _isExportingPdf = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (pw.Context context) {
            if (context.pageNumber == 1) return pw.SizedBox.shrink();
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey500,
                ),
              ),
            );
          },
          build: (pw.Context context) => [
            // Title
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Generated by Kapsa',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey500,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.SizedBox(height: 16),

            // Key Takeaways
            if (bulletPoints.isNotEmpty) ...[
              pw.Text(
                'Key Takeaways',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 10),
              ...bulletPoints.map(
                (point) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6, left: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 5,
                        height: 5,
                        margin: const pw.EdgeInsets.only(top: 5, right: 8),
                        decoration: const pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColors.indigo400,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          point,
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey800,
                            lineSpacing: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            // Full Summary
            pw.Text(
              'Full Summary',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              content,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
                lineSpacing: 4,
              ),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      // Sanitize title for filename
      final safeName = title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .toLowerCase();
      final filename = '${safeName.isEmpty ? 'summary' : safeName}.pdf';

      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: ${AppErrorHandler.friendlyMessage(e)}'),
            backgroundColor: AppColors.immersiveCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    for (final c in _bulletControllers) {
      c.dispose();
    }
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(summaryProvider(widget.summaryId));

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      floatingActionButton: summaryAsync.whenOrNull(
        data: (summary) {
          if (summary == null || !TtsService.instance.isEnabled) return null;

          return FloatingActionButton(
            backgroundColor: AppColors.primary,
            onPressed: () => _toggleTts(summary.content),
            child: Icon(
              _isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
            ),
          );
        },
      ),
      body: summaryAsync.when(
        loading: () => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: ShimmerList(count: 5, itemHeight: 60),
          ),
        ),
        error: (e, _) => SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48,
                      color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppErrorHandler.friendlyMessage(e),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (summary) {
          if (summary == null) {
            return SafeArea(
              child: Center(
                child: Text(
                  'Summary not found',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ),
            );
          }

          final readMin = _estimateReadMinutes(summary.wordCount);

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom header with glass back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0,
                  ),
                  child: Row(
                    children: [
                      TapScale(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Edit button
                      if (!_isEditing)
                        TapScale(
                          onTap: () => _enterEditMode(
                            summary.bulletPoints,
                            summary.content,
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      if (!_isEditing)
                        const SizedBox(width: AppSpacing.sm),
                      // Share button
                      TapScale(
                        onTap: () => _shareSummary(
                          title: summary.title,
                          bulletPoints: summary.bulletPoints,
                          content: summary.content,
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Download PDF button
                      if (!_isEditing)
                        TapScale(
                          onTap: _isExportingPdf
                              ? null
                              : () => _exportToPdf(
                                    title: summary.title,
                                    bulletPoints: summary.bulletPoints,
                                    content: summary.content,
                                  ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isExportingPdf
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: _isExportingPdf
                                    ? AppColors.primary.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: _isExportingPdf
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 18,
                                    color: Colors.white70,
                                  ),
                          ),
                        ),
                      if (!_isEditing)
                        const SizedBox(width: AppSpacing.sm),
                      // Generate Quiz button
                      if (!_isEditing)
                        TapScale(
                          onTap: () => _generateQuiz(summary.courseId),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.quiz_rounded,
                              size: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      if (!_isEditing)
                        const SizedBox(width: AppSpacing.sm),
                      // Reading time pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_stories_rounded, size: 14,
                                color: Colors.white.withValues(alpha: 0.5)),
                            const SizedBox(width: 5),
                            Text(
                              '~$readMin min read',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.lg,
                      AppSpacing.xl, 120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title area (long-press to rename)
                        GestureDetector(
                          onLongPress: () {
                            HapticFeedback.mediumImpact();
                            _showRenameDialog(summary.title);
                          },
                          child: Text(
                            summary.title,
                            style: AppTypography.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Word count + reading time
                        Text(
                          '${summary.wordCount} words',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),

                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Container(
                            height: 1,
                            color: AppColors.immersiveBorder,
                          ),
                        ),

                        // Starred Key Points section
                        if (_starredBullets.isNotEmpty &&
                            summary.bulletPoints.isNotEmpty) ...[
                          Row(
                            children: [
                              const Text(
                                '\u2B50 Key Points',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '${_starredBullets.length} key point${_starredBullets.length == 1 ? '' : 's'} starred',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              children: _starredBullets
                                  .where((i) =>
                                      i < summary.bulletPoints.length)
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final bulletIndex = entry.value;
                                final isLast = entry.key ==
                                    _starredBullets
                                            .where((i) =>
                                                i <
                                                summary
                                                    .bulletPoints.length)
                                            .length -
                                        1;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: isLast ? 0 : AppSpacing.sm,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding:
                                            EdgeInsets.only(top: 3),
                                        child: Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: Color(0xFFFFD700),
                                        ),
                                      ),
                                      const SizedBox(
                                          width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          summary.bulletPoints[
                                              bulletIndex],
                                          style: AppTypography
                                              .bodySmall
                                              .copyWith(
                                            color: Colors.white
                                                .withValues(
                                                    alpha: 0.9),
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],

                        // Key Takeaways
                        if (_isEditing
                            ? _bulletControllers.isNotEmpty
                            : summary.bulletPoints.isNotEmpty) ...[
                          Text(
                            'Key Takeaways',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.immersiveCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isEditing
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : AppColors.immersiveBorder,
                              ),
                            ),
                            child: _isEditing
                                ? Column(
                                    children: _bulletControllers
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: entry.key <
                                                  _bulletControllers.length - 1
                                              ? AppSpacing.sm
                                              : 0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  top: 14),
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.7),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.sm),
                                            Expanded(
                                              child: TextField(
                                                controller: entry.value,
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.85),
                                                  height: 1.6,
                                                ),
                                                maxLines: null,
                                                cursorColor: AppColors.primary,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    vertical: 6,
                                                    horizontal: 8,
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white
                                                      .withValues(alpha: 0.04),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide: BorderSide(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.1),
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide: BorderSide(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.1),
                                                    ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide: BorderSide(
                                                      color: AppColors.primary
                                                          .withValues(
                                                              alpha: 0.6),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : Column(
                                    children: summary.bulletPoints
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final isStarred = _starredBullets
                                          .contains(entry.key);
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: entry.key <
                                                  summary.bulletPoints.length -
                                                      1
                                              ? AppSpacing.sm
                                              : 0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  top: 7),
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.7),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.sm),
                                            Expanded(
                                              child: Text(
                                                entry.value,
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.85),
                                                  height: 1.6,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.xs),
                                            GestureDetector(
                                              onTap: () => _toggleStarred(
                                                  entry.key),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        top: 2),
                                                child: Icon(
                                                  isStarred
                                                      ? Icons.star_rounded
                                                      : Icons
                                                          .star_outline_rounded,
                                                  size: 18,
                                                  color: isStarred
                                                      ? const Color(
                                                          0xFFFFD700)
                                                      : Colors.white
                                                          .withValues(
                                                              alpha: 0.25),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],

                        // Full Summary
                        Text(
                          'Full Summary',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.immersiveCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isEditing
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.immersiveBorder,
                            ),
                          ),
                          child: _isEditing
                              ? TextField(
                                  controller: _contentController,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.85),
                                    height: 1.8,
                                  ),
                                  maxLines: null,
                                  minLines: 6,
                                  cursorColor: AppColors.primary,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                    hintText: 'Enter summary content...',
                                    hintStyle:
                                        AppTypography.bodyMedium.copyWith(
                                      color: Colors.white38,
                                    ),
                                  ),
                                )
                              : SelectableText(
                                  summary.content,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.85),
                                    height: 1.8,
                                  ),
                                ),
                        ),

                        // Quiz from this summary chip
                        if (!_isEditing) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Center(
                            child: _QuizFromSummaryChip(
                              courseId: summary.courseId,
                              onTap: () => _generateQuiz(summary.courseId),
                            ),
                          ),
                        ],

                        // Save / Cancel buttons (edit mode)
                        if (_isEditing) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Row(
                            children: [
                              Expanded(
                                child: TapScale(
                                  onTap: _isSaving ? null : _cancelEdit,
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.06),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.12),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Cancel',
                                      style:
                                          AppTypography.bodySmall.copyWith(
                                        color: Colors.white60,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TapScale(
                                  onTap: _isSaving ? null : _saveEdit,
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'Save',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Floating chip that shows "Quiz from this summary" with a loading state
/// when quiz generation is in progress.
class _QuizFromSummaryChip extends ConsumerWidget {
  final String courseId;
  final VoidCallback onTap;

  const _QuizFromSummaryChip({
    required this.courseId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGenerating = ref.watch(generationProvider).any(
          (t) =>
              t.type == GenerationType.quiz &&
              t.courseId == courseId &&
              t.isRunning,
        );

    return TapScale(
      onTap: isGenerating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isGenerating
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isGenerating
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGenerating)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              const Icon(
                Icons.quiz_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            const SizedBox(width: 8),
            Text(
              isGenerating ? 'Generating quiz...' : 'Quiz from this summary',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
