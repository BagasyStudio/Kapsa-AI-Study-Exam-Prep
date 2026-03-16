import 'package:flutter/material.dart';

/// Curated gradient palette for deck covers.
///
/// 12 premium gradients, deterministically assigned by [coverGradientIndex].
/// No images needed — instant, consistent, and visually cohesive.
abstract final class DeckCoverGradient {
  static const List<List<Color>> _palettes = [
    [Color(0xFF6467F2), Color(0xFF8B5CF6)], // 0: Indigo → Violet
    [Color(0xFF3B82F6), Color(0xFF06B6D4)], // 1: Blue → Cyan
    [Color(0xFF10B981), Color(0xFF059669)], // 2: Emerald
    [Color(0xFFEC4899), Color(0xFFF43F5E)], // 3: Pink → Rose
    [Color(0xFFF97316), Color(0xFFF59E0B)], // 4: Orange → Amber
    [Color(0xFF8B5CF6), Color(0xFFA855F7)], // 5: Violet
    [Color(0xFF14B8A6), Color(0xFF06B6D4)], // 6: Teal → Cyan
    [Color(0xFF6366F1), Color(0xFF3B82F6)], // 7: Indigo → Blue
    [Color(0xFFEF4444), Color(0xFFEC4899)], // 8: Red → Pink
    [Color(0xFF84CC16), Color(0xFF10B981)], // 9: Lime → Emerald
    [Color(0xFF0EA5E9), Color(0xFF6366F1)], // 10: Sky → Indigo
    [Color(0xFFD946EF), Color(0xFF8B5CF6)], // 11: Fuchsia → Violet
  ];

  /// Get gradient for a parent deck.
  static LinearGradient forIndex(int index) {
    final colors = _palettes[index.clamp(0, _palettes.length - 1)];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  /// Get gradient variant for a child deck (offset from parent).
  static LinearGradient forChildIndex(int parentIndex, int childIndex) {
    final effectiveIndex =
        (parentIndex + childIndex + 1) % _palettes.length;
    return forIndex(effectiveIndex);
  }

  /// Get the primary color of a gradient (for tinting, badges, etc.).
  static Color primaryColor(int index) {
    return _palettes[index.clamp(0, _palettes.length - 1)][0];
  }

  /// Get gradient from a string hash (for auto-assignment).
  static int indexFromTitle(String title) {
    if (title.isEmpty) return 0;
    var hash = 0;
    for (var i = 0; i < title.length; i++) {
      hash = ((hash << 5) - hash + title.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash % _palettes.length;
  }
}
