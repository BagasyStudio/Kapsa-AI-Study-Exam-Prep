import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../data/models/occlusion_rect_model.dart';
import '../widgets/occlusion_painter.dart';

/// Editor screen for creating image occlusion flashcards.
///
/// User picks an image, draws rectangles over key areas, labels each
/// rectangle, then saves. Each rectangle becomes one flashcard.
class OcclusionEditorScreen extends ConsumerStatefulWidget {
  final String courseId;

  const OcclusionEditorScreen({super.key, required this.courseId});

  @override
  ConsumerState<OcclusionEditorScreen> createState() =>
      _OcclusionEditorScreenState();
}

class _OcclusionEditorScreenState
    extends ConsumerState<OcclusionEditorScreen> {
  File? _imageFile;
  final List<OcclusionRect> _rects = [];
  int? _selectedIndex;
  bool _isSaving = false;

  // Drawing state
  Offset? _drawStart;
  Offset? _drawCurrent;
  Size _imageSize = Size.zero;

  final _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _rects.clear();
        _selectedIndex = null;
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_imageFile == null || _imageSize == Size.zero) return;
    setState(() {
      _drawStart = details.localPosition;
      _drawCurrent = details.localPosition;
      _selectedIndex = null;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_drawStart == null) return;
    setState(() => _drawCurrent = details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_drawStart == null || _drawCurrent == null || _imageSize == Size.zero) {
      return;
    }

    final startX = _drawStart!.dx / _imageSize.width;
    final startY = _drawStart!.dy / _imageSize.height;
    final endX = _drawCurrent!.dx / _imageSize.width;
    final endY = _drawCurrent!.dy / _imageSize.height;

    final x = startX < endX ? startX : endX;
    final y = startY < endY ? startY : endY;
    final w = (endX - startX).abs();
    final h = (endY - startY).abs();

    // Ignore tiny accidental drags
    if (w < 0.02 || h < 0.02) {
      setState(() {
        _drawStart = null;
        _drawCurrent = null;
      });
      return;
    }

    final rect = OcclusionRect(
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      width: w.clamp(0.0, 1.0 - x),
      height: h.clamp(0.0, 1.0 - y),
      label: '',
    );

    setState(() {
      _rects.add(rect);
      _selectedIndex = _rects.length - 1;
      _drawStart = null;
      _drawCurrent = null;
    });

    HapticFeedback.lightImpact();
    _showLabelDialog(_rects.length - 1);
  }

  void _showLabelDialog(int index) {
    _labelController.text = _rects[index].label;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Label for Region ${index + 1}',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
          ),
        ),
        content: TextField(
          controller: _labelController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Mitochondria',
            filled: true,
            fillColor: AppColors.cardDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _rects[index] =
                    _rects[index].copyWith(label: _labelController.text.trim());
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _deleteSelected() {
    if (_selectedIndex == null || _selectedIndex! >= _rects.length) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _rects.removeAt(_selectedIndex!);
      _selectedIndex = null;
    });
  }

  Future<void> _save() async {
    if (_imageFile == null || _rects.isEmpty) return;

    // Validate all rects have labels
    final unlabeled = _rects.where((r) => r.label.isEmpty).toList();
    if (unlabeled.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please label all occlusion regions before saving')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Upload image to Supabase Storage
      final bytes = await _imageFile!.readAsBytes();
      final ext = _imageFile!.path.split('.').last;
      final fileName =
          'occlusion-images/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await client.storage.from('user-uploads').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      final imageUrl =
          client.storage.from('user-uploads').getPublicUrl(fileName);

      // Create deck
      final repo = ref.read(flashcardRepositoryProvider);
      final deck = await repo.createDeck(
        courseId: widget.courseId,
        title: 'Image Occlusion — ${_rects.length} cards',
      );

      // Create flashcard for each rect
      final now = DateTime.now().toUtc().toIso8601String();
      final occlusionJson =
          _rects.map((rect) => rect.toJson()).toList();

      final cards = _rects.map((r) {
        return {
          'deck_id': deck.id,
          'topic': 'Image Occlusion',
          'question_before': 'Identify the highlighted region',
          'keyword': r.label,
          'question_after': '',
          'answer': r.label,
          'mastery': 'new',
          'card_type': 'image_occlusion',
          'image_url': imageUrl,
          'occlusion_data': occlusionJson,
          'stability': 0,
          'difficulty': 0,
          'elapsed_days': 0,
          'scheduled_days': 0,
          'reps': 0,
          'lapses': 0,
          'srs_state': 0,
          'due': now,
        };
      }).toList();

      await repo.insertCards(cards);

      ref.invalidate(flashcardDecksProvider(widget.courseId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created ${_rects.length} image occlusion cards!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Image Occlusion',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
          ),
        ),
        actions: [
          if (_rects.isNotEmpty)
            TapScale(
              onTap: _isSaving ? null : _save,
              child: Container(
                margin: const EdgeInsets.only(right: AppSpacing.md),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save ${_rects.length} Cards',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: _imageFile == null
          ? _buildPickPrompt()
          : _buildEditor(),
    );
  }

  Widget _buildPickPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(Icons.add_photo_alternate,
                size: 40, color: AppColors.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Choose an Image',
            style: AppTypography.h3.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Select a diagram, chart, or image to create\nocclusion flashcards',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white38,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          TapScale(
            onTap: _pickImage,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pick from Gallery',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

  Widget _buildEditor() {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.touch_app,
                  size: 16, color: Colors.white38),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Draw rectangles over areas to occlude',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ),
              if (_selectedIndex != null) ...[
                TapScale(
                  onTap: () => _showLabelDialog(_selectedIndex!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit,
                        size: 16, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                TapScale(
                  onTap: _deleteSelected,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 16, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Image canvas
        Expanded(
          child: Center(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onTapUp: (details) {
                for (int i = 0; i < _rects.length; i++) {
                  final r = _rects[i];
                  final rectPixels = Rect.fromLTWH(
                    r.x * _imageSize.width,
                    r.y * _imageSize.height,
                    r.width * _imageSize.width,
                    r.height * _imageSize.height,
                  );
                  if (rectPixels.contains(details.localPosition)) {
                    setState(() => _selectedIndex = i);
                    return;
                  }
                }
                setState(() => _selectedIndex = null);
              },
              child: Stack(
                children: [
                  Image.file(
                    _imageFile!,
                    fit: BoxFit.contain,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      if (frame == null) {
                        return const SizedBox(
                          width: 200,
                          height: 200,
                          child:
                              Center(child: CircularProgressIndicator()),
                        );
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final renderBox =
                            context.findRenderObject() as RenderBox?;
                        if (renderBox != null &&
                            renderBox.hasSize &&
                            renderBox.size != _imageSize) {
                          setState(() => _imageSize = renderBox.size);
                        }
                      });
                      return child;
                    },
                  ),
                  if (_imageSize != Size.zero)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: OcclusionPainter(
                          rects: _rects,
                          selectedIndex: _selectedIndex,
                          imageSize: _imageSize,
                        ),
                      ),
                    ),
                  if (_drawStart != null && _drawCurrent != null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DrawPreviewPainter(
                          start: _drawStart!,
                          current: _drawCurrent!,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Rect list
        if (_rects.isNotEmpty)
          Container(
            height: 60,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _rects.length,
              itemBuilder: (context, index) {
                final r = _rects[index];
                final isSelected = index == _selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TapScale(
                    onTap: () =>
                        setState(() => _selectedIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                                .withValues(alpha: 0.15)
                            : Colors.white
                                    .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${index + 1}',
                            style: AppTypography.labelLarge.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if (r.label.isNotEmpty)
                            Text(
                              r.label,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// Preview painter for drawing in-progress rectangle.
class _DrawPreviewPainter extends CustomPainter {
  final Offset start;
  final Offset current;

  _DrawPreviewPainter({required this.start, required this.current});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(start, current);
    final paint = Paint()
      ..color = const Color(0xFF6467F2).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );
    final borderPaint = Paint()
      ..color = const Color(0xFF6467F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DrawPreviewPainter oldDelegate) =>
      start != oldDelegate.start || current != oldDelegate.current;
}
