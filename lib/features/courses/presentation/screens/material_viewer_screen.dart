import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../../core/widgets/math_text.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/material_model.dart';
import '../providers/course_provider.dart';
import '../widgets/material_list_item.dart';
import '../../../../core/utils/error_handler.dart';

/// A parsed table-of-contents entry from the material content.
class _TocEntry {
  final String title;
  final int level; // 1 for #, 2 for ##, 3 for ###, etc.
  final int charOffset; // character offset in the content string

  const _TocEntry({
    required this.title,
    required this.level,
    required this.charOffset,
  });
}

/// A highlighted text range stored by character offset.
class _HighlightRange {
  final int start;
  final int end;

  const _HighlightRange({required this.start, required this.end});

  Map<String, dynamic> toJson() => {'start': start, 'end': end};

  factory _HighlightRange.fromJson(Map<String, dynamic> json) =>
      _HighlightRange(
        start: json['start'] as int,
        end: json['end'] as int,
      );
}

/// A beautiful full-screen viewer for course materials.
///
/// Shows the material content (extracted text, notes, paste) with a
/// premium glassmorphic design. Supports copy-to-clipboard, marking
/// as reviewed, and scrollable reading experience.
class MaterialViewerScreen extends ConsumerStatefulWidget {
  final String materialId;
  final String courseId;

  const MaterialViewerScreen({
    super.key,
    required this.materialId,
    required this.courseId,
  });

  @override
  ConsumerState<MaterialViewerScreen> createState() =>
      _MaterialViewerScreenState();
}

class _MaterialViewerScreenState extends ConsumerState<MaterialViewerScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _copyScaleController;
  late Animation<double> _copyScaleAnimation;
  bool _showCopied = false;

  // -- Offline caching state --
  bool _isCachedOffline = false;
  bool _isCaching = false;

  // -- Offline fallback --
  MaterialModel? _offlineFallbackMaterial;
  bool _isLoadingOfflineFallback = false;
  bool _usedOfflineFallback = false;

  // -- Highlighting state --
  bool _highlightMode = false;
  List<_HighlightRange> _highlights = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _copyScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _copyScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _copyScaleController,
      curve: Curves.easeInOut,
    ));

    _checkOfflineCache();
    _loadHighlights();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _copyScaleController.dispose();
    super.dispose();
  }

  // ── Offline caching helpers ──

  Future<Directory> _materialsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/materials');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _cacheFile() async {
    final dir = await _materialsDir();
    return File('${dir.path}/${widget.materialId}.txt');
  }

  Future<void> _checkOfflineCache() async {
    if (kIsWeb) return;
    try {
      final file = await _cacheFile();
      final exists = await file.exists();
      if (mounted) setState(() => _isCachedOffline = exists);
    } catch (e) {
      // Ignore file-system errors silently
      debugPrint('MaterialViewerScreen: checkOfflineCache failed: $e');
    }
  }

  // ── Highlighting helpers ──

  String get _highlightsKey => 'highlights_${widget.materialId}';

  Future<void> _loadHighlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_highlightsKey) ?? [];
      final loaded = stored.map((s) {
        final json = jsonDecode(s) as Map<String, dynamic>;
        return _HighlightRange.fromJson(json);
      }).toList();
      if (mounted) {
        setState(() {
          _highlights = loaded;
        });
      }
    } catch (e) {
      // Ignore silently
      debugPrint('MaterialViewerScreen: loadHighlights failed: $e');
    }
  }

  Future<void> _saveHighlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          _highlights.map((h) => jsonEncode(h.toJson())).toList();
      await prefs.setStringList(_highlightsKey, encoded);
    } catch (e) {
      // Ignore silently
      debugPrint('MaterialViewerScreen: saveHighlights failed: $e');
    }
  }

  void _addHighlight(int start, int end) {
    if (start >= end) return;
    HapticFeedback.lightImpact();
    setState(() {
      _highlights.add(_HighlightRange(start: start, end: end));
      // Merge overlapping ranges
      _highlights = _mergeHighlights(_highlights);
    });
    _saveHighlights();
  }

  List<_HighlightRange> _mergeHighlights(List<_HighlightRange> ranges) {
    if (ranges.isEmpty) return ranges;
    final sorted = List<_HighlightRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));
    final merged = <_HighlightRange>[sorted.first];
    for (int i = 1; i < sorted.length; i++) {
      final last = merged.last;
      final current = sorted[i];
      if (current.start <= last.end) {
        merged[merged.length - 1] = _HighlightRange(
          start: last.start,
          end: current.end > last.end ? current.end : last.end,
        );
      } else {
        merged.add(current);
      }
    }
    return merged;
  }

  void _clearHighlights() {
    HapticFeedback.mediumImpact();
    setState(() => _highlights = []);
    _saveHighlights();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Highlights cleared'),
          backgroundColor: AppColors.immersiveCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showHighlightOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.highlight_rounded, size: 20, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '${_highlights.length} highlight${_highlights.length == 1 ? '' : 's'}',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TapScale(
                onTap: () {
                  Navigator.pop(ctx);
                  _clearHighlights();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Clear All Highlights',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleHighlightMode() {
    HapticFeedback.lightImpact();
    setState(() => _highlightMode = !_highlightMode);
    if (_highlightMode && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.highlight_rounded, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Highlight mode: select text to highlight'),
              ),
            ],
          ),
          backgroundColor: AppColors.immersiveCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Attempt to load material from offline cache when network fails.
  /// Returns a [MaterialModel] built from the cached file, or null.
  Future<MaterialModel?> _loadFromOfflineCache() async {
    if (kIsWeb) return null;
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return null;

      final raw = await file.readAsString();
      final lines = raw.split('\n');
      if (lines.isEmpty) return null;

      final title = lines[0];
      String type = 'notes';
      String? fileUrl;
      int contentStart = 1;

      // Parse metadata lines
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.startsWith('---type:') && line.endsWith('---')) {
          type = line.substring(8, line.length - 3);
          contentStart = i + 1;
        } else if (line.startsWith('---fileUrl:') && line.endsWith('---')) {
          fileUrl = line.substring(11, line.length - 3);
          contentStart = i + 1;
        } else {
          break;
        }
      }

      final content = lines.sublist(contentStart).join('\n');

      return MaterialModel(
        id: widget.materialId,
        courseId: widget.courseId,
        userId: '',
        title: title,
        type: type,
        content: content.isNotEmpty ? content : null,
        fileUrl: fileUrl,
      );
    } catch (e) {
      debugPrint('MaterialViewerScreen: parseOfflineCache failed: $e');
      return null;
    }
  }

  Future<void> _cacheMaterialContent(MaterialModel material) async {
    if (kIsWeb) return;
    if (_isCachedOffline || _isCaching) return;

    setState(() => _isCaching = true);

    try {
      final file = await _cacheFile();
      // Store title + type + content as a simple text cache
      final buffer = StringBuffer();
      buffer.writeln(material.displayTitle);
      buffer.writeln('---type:${material.type}---');
      if (material.fileUrl != null) {
        buffer.writeln('---fileUrl:${material.fileUrl}---');
      }
      buffer.writeln(material.content ?? '');
      await file.writeAsString(buffer.toString());

      if (mounted) {
        setState(() {
          _isCachedOffline = true;
          _isCaching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.download_done_rounded, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Text('Saved for offline \u2713'),
              ],
            ),
            backgroundColor: AppColors.immersiveCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('MaterialViewerScreen: cacheMaterialContent failed: $e');
      if (mounted) setState(() => _isCaching = false);
    }
  }

  void _copyContent(String content) {
    Clipboard.setData(ClipboardData(text: content));
    HapticFeedback.mediumImpact();
    _copyScaleController.forward(from: 0);
    setState(() => _showCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCopied = false);
    });
  }

  Future<void> _markReviewed(String materialId) async {
    HapticFeedback.lightImpact();
    await ref.read(materialRepositoryProvider).markReviewed(materialId);
    ref.invalidate(courseMaterialsProvider(widget.courseId));
  }

  void _shareMaterial(MaterialModel material) {
    HapticFeedback.mediumImpact();

    final title = material.displayTitle;
    final content = material.content ?? '';

    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln();

    // Truncate if content is very long (> 2000 chars)
    if (content.length > 2000) {
      buffer.writeln(content.substring(0, 2000));
      buffer.writeln('... [Read more in Kapsa app]');
    } else {
      buffer.writeln(content);
    }

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  /// Parse the material content to extract table of contents entries.
  List<_TocEntry> _parseToc(String content) {
    final entries = <_TocEntry>[];
    final lines = content.split('\n');
    int charOffset = 0;

    for (final line in lines) {
      final trimmed = line.trimLeft();

      // Match markdown headers: #, ##, ###, etc.
      final headerMatch = RegExp(r'^(#{1,4})\s+(.+)$').firstMatch(trimmed);
      if (headerMatch != null) {
        final level = headerMatch.group(1)!.length;
        final title = headerMatch.group(2)!.trim();
        entries.add(_TocEntry(
          title: title,
          level: level,
          charOffset: charOffset,
        ));
      }

      // Match numbered sections like "1. Title" or "1.2 Title" at start of line
      final numberedMatch =
          RegExp(r'^(\d+(?:\.\d+)?)[.\)]\s+(.+)$').firstMatch(trimmed);
      if (numberedMatch != null && headerMatch == null) {
        final title = numberedMatch.group(2)!.trim();
        final number = numberedMatch.group(1)!;
        final level = number.contains('.') ? 2 : 1;
        entries.add(_TocEntry(
          title: title,
          level: level,
          charOffset: charOffset,
        ));
      }

      charOffset += line.length + 1; // +1 for the newline character
    }

    return entries;
  }

  void _showTableOfContents(BuildContext context, String content) {
    HapticFeedback.mediumImpact();
    final entries = _parseToc(content);

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No sections found in this material',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.immersiveCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TocBottomSheet(
        entries: entries,
        totalContentLength: content.length,
        onEntryTap: (entry) {
          Navigator.pop(ctx);
          final readerState = _contentReaderKey.currentState;
          if (readerState != null) {
            readerState.scrollToFraction(
                entry.charOffset / content.length.clamp(1, content.length));
          }
        },
      ),
    );
  }

  // Global key for accessing _ContentReader state (for TOC scroll)
  final GlobalKey<_ContentReaderState> _contentReaderKey =
      GlobalKey<_ContentReaderState>();

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(courseMaterialsProvider(widget.courseId));

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: Stack(
        children: [
          // Ethereal background gradients
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: -40,
            left: -60,
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
            bottom: 100,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.03),
              ),
            ),
          ),

          // Main content
          SafeArea(
            bottom: false,
            child: widget.courseId.isEmpty || widget.materialId.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.white38),
                        const SizedBox(height: AppSpacing.md),
                        Text('Invalid material link',
                            style: AppTypography.bodyMedium),
                      ],
                    ),
                  )
                : materialsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) {
                // Attempt to load from offline cache
                if (!_isLoadingOfflineFallback && _offlineFallbackMaterial == null && !_usedOfflineFallback) {
                  _isLoadingOfflineFallback = true;
                  _loadFromOfflineCache().then((cached) {
                    if (mounted) {
                      setState(() {
                        _offlineFallbackMaterial = cached;
                        _isLoadingOfflineFallback = false;
                        _usedOfflineFallback = true;
                      });
                    }
                  });
                }

                if (_offlineFallbackMaterial != null) {
                  return FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      children: [
                        // Offline mode banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                          color: Colors.orange.withValues(alpha: 0.1),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 16,
                                color: Colors.orange.shade300,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Viewing offline version',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.orange.shade300,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _buildContent(context, _offlineFallbackMaterial!),
                        ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 48, color: Colors.white38),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        AppErrorHandler.friendlyMessage(e),
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),
                      if (_isLoadingOfflineFallback) ...[
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Checking offline cache...',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              data: (materials) {
                final matches = materials
                    .where((m) => m.id == widget.materialId);
                final MaterialModel? material =
                    matches.isNotEmpty ? matches.first : null;

                if (material == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.white38),
                        const SizedBox(height: AppSpacing.md),
                        Text('Material not found',
                            style: AppTypography.bodyMedium),
                      ],
                    ),
                  );
                }

                return FadeTransition(
                  opacity: _fadeController,
                  child: _buildContent(context, material),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MaterialModel material) {
    final hasContent =
        material.content != null && material.content!.trim().isNotEmpty;
    final isPdf = material.type == 'pdf' && material.fileUrl != null && material.fileUrl!.isNotEmpty;
    final kind = _kindFromType(material.type);
    final typeColor = _colorForKind(kind);
    final typeIcon = _iconForKind(kind);

    // Check if TOC is available for text content
    final hasToc = hasContent && _parseToc(material.content!).isNotEmpty;

    // Auto-cache content when material loads (non-web only)
    if (!kIsWeb && !_isCachedOffline && !_isCaching && (hasContent || isPdf)) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cacheMaterialContent(material);
      });
    }

    return Column(
      children: [
        // Header bar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              TapScale(
                onTap: () => context.pop(),
                scaleDown: 0.90,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.white60),
                ),
              ),
              const Spacer(),
              // Offline badge
              if (_isCachedOffline)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppRadius.borderRadiusPill,
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_done_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (hasContent) ...[
                // TOC button (only if sections are found)
                if (hasToc)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: TapScale(
                      onTap: () => _showTableOfContents(
                          context, material.content!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: AppRadius.borderRadiusPill,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.toc_rounded,
                              size: 16,
                              color: Colors.white60,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'TOC',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Highlight toggle button with badge
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: TapScale(
                    onTap: _toggleHighlightMode,
                    onLongPress: _highlights.isNotEmpty
                        ? () => _showHighlightOptions(context)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _highlightMode
                            ? Colors.amber.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.10),
                        borderRadius: AppRadius.borderRadiusPill,
                        border: Border.all(
                          color: _highlightMode
                              ? Colors.amber.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.highlight_rounded,
                            size: 16,
                            color: _highlightMode
                                ? Colors.amber
                                : Colors.white60,
                          ),
                          if (_highlights.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _highlightMode
                                    ? Colors.amber.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${_highlights.length}',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _highlightMode
                                      ? Colors.amber
                                      : Colors.white60,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Copy button
                TapScale(
                  onTap: () => _copyContent(material.content!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _showCopied
                          ? AppColors.success.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.10),
                      borderRadius: AppRadius.borderRadiusPill,
                      border: Border.all(
                        color: _showCopied
                            ? AppColors.success.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _copyScaleAnimation,
                          child: Icon(
                            _showCopied
                                ? Icons.check_rounded
                                : Icons.copy_rounded,
                            size: 16,
                            color: _showCopied
                                ? AppColors.success
                                : Colors.white60,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showCopied ? 'Copied!' : 'Copy',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _showCopied
                                ? AppColors.success
                                : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Share button
                TapScale(
                  onTap: () => _shareMaterial(material),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: AppRadius.borderRadiusPill,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 16,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Share',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              // Mark reviewed button
              if (!material.isReviewed)
                TapScale(
                  onTap: () => _markReviewed(material.id),
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
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mark Reviewed',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Breadcrumb: Course Name > Material Name
        _Breadcrumb(
          courseId: widget.courseId,
          materialTitle: material.displayTitle,
          onCourseTap: () => context.pop(),
        ),

        // Material header card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  // Type icon badge
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 26),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GradientText(
                          material.displayTitle,
                          style: AppTypography.h2.copyWith(fontSize: 22),
                          gradient: AppGradients.textLight,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: AppRadius.borderRadiusPill,
                              ),
                              child: Text(
                                material.typeLabel,
                                style: AppTypography.caption.copyWith(
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (material.sizeLabel.isNotEmpty) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                material.sizeLabel,
                                style: AppTypography.caption,
                              ),
                            ],
                            if (material.isReviewed) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Icon(Icons.check_circle,
                                  size: 14, color: AppColors.success),
                              const SizedBox(width: 3),
                              Text(
                                'Reviewed',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (material.createdAt != null) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                _formatDate(material.createdAt!),
                                style: AppTypography.caption,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.textMuted.withValues(alpha: 0.15),
                  AppColors.textMuted.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Content area
        Expanded(
          child: isPdf && !kIsWeb
              ? _PdfViewerContent(fileUrl: material.fileUrl!)
              : hasContent
                  ? _ContentReader(
                      key: _contentReaderKey,
                      content: material.content!,
                      highlights: _highlights,
                      highlightMode: _highlightMode,
                      onHighlightAdded: _addHighlight,
                    )
                  : _EmptyContent(type: material.type, fileUrl: material.fileUrl),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
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

  Color _colorForKind(CourseMaterialKind kind) => switch (kind) {
        CourseMaterialKind.pdf => AppColors.pdfRed,
        CourseMaterialKind.audio => const Color(0xFF3B82F6),
        CourseMaterialKind.notes => const Color(0xFF10B981),
        CourseMaterialKind.paste => const Color(0xFFA855F7),
      };

  IconData _iconForKind(CourseMaterialKind kind) => switch (kind) {
        CourseMaterialKind.pdf => Icons.picture_as_pdf_rounded,
        CourseMaterialKind.audio => Icons.graphic_eq_rounded,
        CourseMaterialKind.notes => Icons.note_alt_rounded,
        CourseMaterialKind.paste => Icons.content_paste_rounded,
      };
}

/// Scrollable content reader with glassmorphic card styling, scroll
/// progress indicator, and text highlighting support.
class _ContentReader extends StatefulWidget {
  final String content;
  final List<_HighlightRange> highlights;
  final bool highlightMode;
  final void Function(int start, int end)? onHighlightAdded;

  const _ContentReader({
    super.key,
    required this.content,
    this.highlights = const [],
    this.highlightMode = false,
    this.onHighlightAdded,
  });

  @override
  State<_ContentReader> createState() => _ContentReaderState();
}

class _ContentReaderState extends State<_ContentReader> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    final progress =
        (_scrollController.offset / maxExtent).clamp(0.0, 1.0);
    if ((progress - _scrollProgress).abs() > 0.001) {
      setState(() => _scrollProgress = progress);
    }
  }

  /// Scroll to a fraction (0.0 - 1.0) of the total scroll extent.
  /// Used by the TOC to jump to approximate positions in the content.
  void scrollToFraction(double fraction) {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final targetOffset = (fraction * maxExtent).clamp(0.0, maxExtent);
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Build a [TextSpan] tree with yellow background for highlighted ranges.
  TextSpan _buildHighlightedTextSpan(String text, TextStyle baseStyle) {
    if (widget.highlights.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    // Sort highlights by start position
    final sorted = List<_HighlightRange>.from(widget.highlights)
      ..sort((a, b) => a.start.compareTo(b.start));

    final spans = <TextSpan>[];
    int cursor = 0;

    for (final hl in sorted) {
      final start = hl.start.clamp(0, text.length);
      final end = hl.end.clamp(0, text.length);
      if (start >= end || start < cursor) continue;

      // Non-highlighted text before this highlight
      if (cursor < start) {
        spans.add(TextSpan(
          text: text.substring(cursor, start),
          style: baseStyle,
        ));
      }

      // Highlighted text
      spans.add(TextSpan(
        text: text.substring(start, end),
        style: baseStyle.copyWith(
          backgroundColor: Colors.amber.withValues(alpha: 0.35),
        ),
      ));

      cursor = end;
    }

    // Remaining text after last highlight
    if (cursor < text.length) {
      spans.add(TextSpan(
        text: text.substring(cursor),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTypography.bodyMedium.copyWith(
      height: 1.75,
      color: Colors.white,
    );

    final hasHighlights = widget.highlights.isNotEmpty;
    final useHighlightableText = widget.highlightMode || hasHighlights;

    return Column(
      children: [
        // Scroll progress indicator
        LinearProgressIndicator(
          value: _scrollProgress,
          minHeight: 2,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.highlightMode ? Colors.amber : AppColors.primary,
          ),
        ),
        // Highlight mode indicator bar
        if (widget.highlightMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 6,
            ),
            color: Colors.amber.withValues(alpha: 0.08),
            child: Row(
              children: [
                Icon(Icons.highlight_rounded, size: 14, color: Colors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Select text to highlight it',
                    style: AppTypography.caption.copyWith(
                      color: Colors.amber.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.borderRadiusXxl,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: AppRadius.borderRadiusXxl,
                    border: Border.all(
                      color: widget.highlightMode
                          ? Colors.amber.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: useHighlightableText
                      ? SelectableText.rich(
                          _buildHighlightedTextSpan(
                              widget.content, baseStyle),
                          onSelectionChanged: (selection, cause) {
                            // When highlight mode is active and the user
                            // lifts their finger after selecting text, we
                            // store the highlight.
                            if (!widget.highlightMode) return;
                            if (selection.isCollapsed) return;
                            // We use a post-frame callback so that the
                            // selection is finalised before we read it.
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) {
                              if (!widget.highlightMode) return;
                              final start = selection.start;
                              final end = selection.end;
                              if (end > start &&
                                  start >= 0 &&
                                  end <= widget.content.length) {
                                widget.onHighlightAdded?.call(start, end);
                              }
                            });
                          },
                        )
                      : MathText(
                          text: widget.content,
                          style: baseStyle,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen PDF viewer using pdfrx with page indicator.
class _PdfViewerContent extends StatefulWidget {
  final String fileUrl;

  const _PdfViewerContent({required this.fileUrl});

  @override
  State<_PdfViewerContent> createState() => _PdfViewerContentState();
}

class _PdfViewerContentState extends State<_PdfViewerContent> {
  final PdfViewerController _pdfController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PdfViewer.uri(
            Uri.parse(widget.fileUrl),
            controller: _pdfController,
            params: PdfViewerParams(
              backgroundColor: AppColors.immersiveBg,
              onViewerReady: (document, controller) {
                if (mounted) {
                  setState(() => _totalPages = document.pages.length);
                }
              },
              viewerOverlayBuilder: (context, size, handleLinkTap) => [],
              onPageChanged: (pageNumber) {
                if (mounted) {
                  setState(() => _currentPage = pageNumber ?? 1);
                }
              },
              loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
                final progress = totalBytes != null && totalBytes > 0
                    ? bytesDownloaded / totalBytes
                    : null;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: progress,
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        progress != null
                            ? 'Loading PDF... ${(progress * 100).toInt()}%'
                            : 'Loading PDF...',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                );
              },
              errorBannerBuilder: (context, error, stackTrace, documentRef) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.error.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Failed to load PDF',
                          style: AppTypography.h4.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Please check your connection and try again.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white38,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Page indicator
        if (_totalPages > 0)
          Container(
            padding: EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: AppColors.immersiveSurface,
              border: Border(
                top: BorderSide(
                  color: AppColors.immersiveBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: Colors.white38,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Table of Contents bottom sheet.
class _TocBottomSheet extends StatelessWidget {
  final List<_TocEntry> entries;
  final int totalContentLength;
  final ValueChanged<_TocEntry> onEntryTap;

  const _TocBottomSheet({
    required this.entries,
    required this.totalContentLength,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.55;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.toc_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Table of Contents',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${entries.length} sections',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(
              color: Colors.white.withValues(alpha: 0.08),
              height: 1,
            ),
            // Entries list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final indent = (entry.level - 1) * 16.0;

                  return TapScale(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onEntryTap(entry);
                    },
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 20 + indent,
                        right: 20,
                        top: 10,
                        bottom: 10,
                      ),
                      child: Row(
                        children: [
                          // Level indicator dot
                          Container(
                            width: entry.level == 1 ? 8 : 6,
                            height: entry.level == 1 ? 8 : 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: entry.level == 1
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.title,
                              style: entry.level == 1
                                  ? AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    )
                                  : AppTypography.bodySmall.copyWith(
                                      color: Colors.white70,
                                    ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.white24,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Breadcrumb showing "Course Name > Material Name" navigation context.
class _Breadcrumb extends ConsumerWidget {
  final String courseId;
  final String materialTitle;
  final VoidCallback onCourseTap;

  const _Breadcrumb({
    required this.courseId,
    required this.materialTitle,
    required this.onCourseTap,
  });

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}\u2026';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseProvider(courseId));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xs,
      ),
      child: courseAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (course) {
          if (course == null) return const SizedBox.shrink();
          final courseName = _truncate(course.displayTitle, 20);
          return Row(
            children: [
              GestureDetector(
                onTap: onCourseTap,
                child: Text(
                  courseName,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '\u203A',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  materialTitle,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white38,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Empty content state when material has no extracted text.
class _EmptyContent extends StatelessWidget {
  final String type;
  final String? fileUrl;

  const _EmptyContent({required this.type, this.fileUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white38.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.text_snippet_outlined,
                size: 36,
                color: Colors.white38.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No text content available',
              style: AppTypography.h4.copyWith(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              type == 'pdf'
                  ? 'The PDF text extraction may still be processing.'
                  : type == 'audio'
                      ? 'The audio transcription may still be processing.'
                      : 'This material has no text content yet.',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
