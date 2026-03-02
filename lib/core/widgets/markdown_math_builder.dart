import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

// ══════════════════════════════════════════════════════════════════
// Inline Syntax — detects $...$ and $$...$$ inside markdown text
// ══════════════════════════════════════════════════════════════════

/// Matches `$$...$$` (block math) inside markdown.
class BlockMathSyntax extends md.InlineSyntax {
  BlockMathSyntax() : super(r'\$\$(.+?)\$\$', startCharacter: 0x24 /* $ */);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final latex = match[1]!.trim();
    if (!_looksLikeMath(latex)) return false;

    final el = md.Element.text('mathBlock', latex);
    parser.addNode(el);
    return true;
  }
}

/// Matches `$...$` (inline math) inside markdown.
class InlineMathSyntax extends md.InlineSyntax {
  InlineMathSyntax()
      : super(r'\$([^\$\n]+?)\$', startCharacter: 0x24 /* $ */);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final latex = match[1]!.trim();
    if (!_looksLikeMath(latex)) return false;

    final el = md.Element.text('math', latex);
    parser.addNode(el);
    return true;
  }
}

/// Returns true when [s] looks like LaTeX rather than a monetary amount.
bool _looksLikeMath(String s) {
  return RegExp(
    r'[\\^_{}]|frac|sqrt|sum|int|lim|alpha|beta|gamma|theta|pi|'
    r'infty|cdot|times|div|pm|leq|geq|neq|approx|rightarrow|'
    r'left|right|over|begin|end|mathrm|mathbf|text',
  ).hasMatch(s);
}

// ══════════════════════════════════════════════════════════════════
// Element Builder — renders math nodes as Flutter widgets
// ══════════════════════════════════════════════════════════════════

/// Renders inline `$...$` math using flutter_math_fork.
class MathBuilder extends MarkdownElementBuilder {
  final TextStyle? textStyle;
  MathBuilder({this.textStyle});

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final latex = element.textContent;
    final style = textStyle ?? preferredStyle ?? parentStyle;

    try {
      return Math.tex(
        latex,
        mathStyle: MathStyle.text,
        textStyle: style,
        onErrorFallback: (_) => _fallback(latex, style),
      );
    } catch (_) {
      return _fallback(latex, style);
    }
  }

  Widget _fallback(String latex, TextStyle? style) {
    return Text(
      latex,
      style: (style ?? const TextStyle()).copyWith(
        fontFamily: 'monospace',
        color: style?.color?.withValues(alpha: 0.85),
      ),
    );
  }
}

/// Renders block `$$...$$` math using flutter_math_fork (centered, larger).
class BlockMathBuilder extends MarkdownElementBuilder {
  final TextStyle? textStyle;
  BlockMathBuilder({this.textStyle});

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final latex = element.textContent;
    final style = textStyle ?? preferredStyle ?? parentStyle;
    final displayStyle = (style ?? const TextStyle()).copyWith(
      fontSize: ((style?.fontSize ?? 14) * 1.2),
    );

    try {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Math.tex(
            latex,
            mathStyle: MathStyle.display,
            textStyle: displayStyle,
            onErrorFallback: (_) => _fallback(latex, style),
          ),
        ),
      );
    } catch (_) {
      return _fallback(latex, style);
    }
  }

  Widget _fallback(String latex, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          latex,
          style: (style ?? const TextStyle()).copyWith(
            fontFamily: 'monospace',
            color: style?.color?.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Helper functions — easy integration
// ══════════════════════════════════════════════════════════════════

/// Returns inline syntaxes for math support.
/// Add to `MarkdownBody(inlineSyntaxes: mathInlineSyntaxes(), ...)`.
List<md.InlineSyntax> mathInlineSyntaxes() => [
      BlockMathSyntax(), // must be before InlineMathSyntax
      InlineMathSyntax(),
    ];

/// Returns element builders for math support.
/// Add to `MarkdownBody(builders: mathBuilders(), ...)`.
///
/// Pass [textStyle] to style the rendered math text.
Map<String, MarkdownElementBuilder> mathBuilders({TextStyle? textStyle}) => {
      'math': MathBuilder(textStyle: textStyle),
      'mathBlock': BlockMathBuilder(textStyle: textStyle),
    };
