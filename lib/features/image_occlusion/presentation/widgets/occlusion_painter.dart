import 'package:flutter/material.dart';
import '../../data/models/occlusion_rect_model.dart';

/// Paints occlusion rectangles on top of an image.
///
/// [rects] — all defined occlusion regions.
/// [revealedIndex] — if non-null, that rect is shown as revealed (green border, no fill).
/// [selectedIndex] — if non-null, that rect has a blue highlight for editing.
/// [imageSize] — the rendered size of the image (rects are ratio-based).
class OcclusionPainter extends CustomPainter {
  final List<OcclusionRect> rects;
  final int? revealedIndex;
  final int? selectedIndex;
  final Size imageSize;

  OcclusionPainter({
    required this.rects,
    this.revealedIndex,
    this.selectedIndex,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < rects.length; i++) {
      final r = rects[i];
      final rect = Rect.fromLTWH(
        r.x * imageSize.width,
        r.y * imageSize.height,
        r.width * imageSize.width,
        r.height * imageSize.height,
      );

      if (i == revealedIndex) {
        // Revealed: green border, no fill
        final revealPaint = Paint()
          ..color = const Color(0xFF22C55E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          revealPaint,
        );
        // Show label text
        _drawLabel(canvas, rect, r.label, const Color(0xFF22C55E));
      } else {
        // Occluded: solid fill
        final fillPaint = Paint()
          ..color = const Color(0xFF6467F2).withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          fillPaint,
        );

        // Number label
        _drawNumber(canvas, rect, i + 1);

        // Selected highlight
        if (i == selectedIndex) {
          final selectPaint = Paint()
            ..color = const Color(0xFF3B82F6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(6)),
            selectPaint,
          );
        }
      }
    }
  }

  void _drawNumber(Canvas canvas, Rect rect, int number) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawLabel(Canvas canvas, Rect rect, String label, Color color) {
    if (label.isEmpty) return;
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: rect.width - 8);
    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant OcclusionPainter oldDelegate) {
    return rects != oldDelegate.rects ||
        revealedIndex != oldDelegate.revealedIndex ||
        selectedIndex != oldDelegate.selectedIndex ||
        imageSize != oldDelegate.imageSize;
  }
}
