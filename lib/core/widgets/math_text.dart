import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// A widget that renders text with inline and block LaTeX math.
///
/// Parses `$$...$$` for display (block) math and `$...$` for inline math.
/// Regular text is rendered with the provided [style].
/// Uses [flutter_math_fork] for LaTeX rendering.
///
/// Includes dollar-sign disambiguation: `$5.00` is not treated as math
/// unless the content contains LaTeX-like characters (`\`, `^`, `_`, `{`, `}`).
class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final MathStyle mathStyle;

  const MathText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.mathStyle = MathStyle.text,
  });

  // ── Regex ────────────────────────────────────────────────────────
  // Match $$...$$ (block) first, then $...$ (inline).
  // dotAll so $$ blocks can span lines.
  static final _mathPattern =
      RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$', dotAll: true);

  /// Returns true when [s] looks like LaTeX rather than a monetary amount.
  static bool _looksLikeMath(String s) {
    return RegExp(
      r'[\\^_{}]|frac|sqrt|sum|int|lim|alpha|beta|gamma|theta|pi|'
      r'infty|cdot|times|div|pm|leq|geq|neq|approx|rightarrow|'
      r'left|right|over|begin|end|mathrm|mathbf|text',
    ).hasMatch(s);
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ??
        DefaultTextStyle.of(context).style.copyWith(
              color: Colors.white,
            );

    // Fast path: no dollar signs at all → plain text.
    if (!text.contains('\$')) {
      return Text(text, style: effectiveStyle, textAlign: textAlign);
    }

    final segments = _parse(text);

    // If parsing produced only text segments (no math), render plain Text.
    if (segments.every((s) => s.type == _SegmentType.text)) {
      return Text(text, style: effectiveStyle, textAlign: textAlign);
    }

    // Check if we have any block math — if so, build as Column.
    final hasBlock = segments.any((s) => s.type == _SegmentType.blockMath);

    if (hasBlock) {
      return _buildWithBlocks(segments, effectiveStyle);
    }

    // All inline → use Wrap with WidgetSpans.
    return _buildInlineOnly(segments, effectiveStyle);
  }

  // ── Parsing ──────────────────────────────────────────────────────

  List<_Segment> _parse(String input) {
    final segments = <_Segment>[];
    var lastEnd = 0;

    for (final match in _mathPattern.allMatches(input)) {
      // Text before this match.
      if (match.start > lastEnd) {
        segments.add(
          _Segment(_SegmentType.text, input.substring(lastEnd, match.start)),
        );
      }

      final blockContent = match.group(1); // $$...$$
      final inlineContent = match.group(2); // $...$

      if (blockContent != null) {
        if (_looksLikeMath(blockContent)) {
          segments.add(_Segment(_SegmentType.blockMath, blockContent.trim()));
        } else {
          // Not math — keep original text with dollar signs.
          segments.add(_Segment(_SegmentType.text, match.group(0)!));
        }
      } else if (inlineContent != null) {
        if (_looksLikeMath(inlineContent)) {
          segments
              .add(_Segment(_SegmentType.inlineMath, inlineContent.trim()));
        } else {
          segments.add(_Segment(_SegmentType.text, match.group(0)!));
        }
      }

      lastEnd = match.end;
    }

    // Trailing text.
    if (lastEnd < input.length) {
      segments.add(_Segment(_SegmentType.text, input.substring(lastEnd)));
    }

    return segments;
  }

  // ── Renderers ────────────────────────────────────────────────────

  /// Builds a column layout when block math ($$...$$) is present.
  Widget _buildWithBlocks(List<_Segment> segments, TextStyle baseStyle) {
    final children = <Widget>[];
    var inlineBuffer = <_Segment>[];

    void flushInline() {
      if (inlineBuffer.isEmpty) return;
      children.add(_buildInlineOnly(inlineBuffer, baseStyle));
      inlineBuffer = [];
    }

    for (final seg in segments) {
      if (seg.type == _SegmentType.blockMath) {
        flushInline();
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(child: _buildMathWidget(seg.content, baseStyle, MathStyle.display)),
          ),
        );
      } else {
        inlineBuffer.add(seg);
      }
    }
    flushInline();

    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Builds a Wrap for inline-only content (text + inline math).
  Widget _buildInlineOnly(List<_Segment> segments, TextStyle baseStyle) {
    final spans = <InlineSpan>[];

    for (final seg in segments) {
      if (seg.type == _SegmentType.text) {
        spans.add(TextSpan(text: seg.content, style: baseStyle));
      } else {
        // inline math
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _buildMathWidget(seg.content, baseStyle, mathStyle),
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
    );
  }

  /// Renders a single LaTeX expression with fallback on error.
  Widget _buildMathWidget(String latex, TextStyle baseStyle, MathStyle mStyle) {
    try {
      return Math.tex(
        latex,
        mathStyle: mStyle,
        textStyle: baseStyle.copyWith(
          fontSize: mStyle == MathStyle.display
              ? (baseStyle.fontSize ?? 14) * 1.2
              : baseStyle.fontSize,
        ),
        onErrorFallback: (err) => _fallbackWidget(latex, baseStyle),
      );
    } catch (_) {
      return _fallbackWidget(latex, baseStyle);
    }
  }

  /// Monospace fallback when LaTeX parsing fails.
  Widget _fallbackWidget(String latex, TextStyle baseStyle) {
    return Text(
      latex,
      style: baseStyle.copyWith(
        fontFamily: 'monospace',
        color: baseStyle.color?.withValues(alpha: 0.85),
        backgroundColor: (baseStyle.color ?? Colors.black).withValues(alpha: 0.06),
      ),
    );
  }
}

// ── Internal types ───────────────────────────────────────────────

enum _SegmentType { text, inlineMath, blockMath }

class _Segment {
  final _SegmentType type;
  final String content;
  const _Segment(this.type, this.content);
}
