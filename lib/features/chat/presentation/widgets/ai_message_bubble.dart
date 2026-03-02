import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/markdown_math_builder.dart';

/// Glass-styled AI message bubble (light mode).
///
/// Displays a frosted glass bubble aligned to the left side with
/// an optional timestamp. Uses BackdropFilter for glass effect.
/// Renders AI responses as markdown for rich formatting.
class AiMessageBubble extends StatelessWidget {
  final String text;
  final String? timestamp;
  final Widget? trailing; // for citation chips below message

  const AiMessageBubble({
    super.key,
    required this.text,
    this.timestamp,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = Theme.of(context).brightness;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Glass bubble
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xxl),
                topRight: Radius.circular(AppRadius.xxl),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(AppRadius.xxl),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.75),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.xxl),
                      topRight: Radius.circular(AppRadius.xxl),
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(AppRadius.xxl),
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1F2687).withValues(alpha: 0.07),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: text,
                    selectable: true,
                    shrinkWrap: true,
                    inlineSyntaxes: mathInlineSyntaxes(),
                    builders: mathBuilders(
                      textStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                        height: 1.6,
                      ),
                    ),
                    styleSheet: MarkdownStyleSheet(
                      p: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                        height: 1.6,
                      ),
                      strong: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                      ),
                      em: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                      h1: AppTypography.h3.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                      ),
                      h2: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                        fontWeight: FontWeight.w700,
                      ),
                      h3: AppTypography.labelLarge.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                        fontWeight: FontWeight.w600,
                      ),
                      listBullet: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                      code: AppTypography.bodySmall.copyWith(
                        color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      codeblockPadding: const EdgeInsets.all(12),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 3,
                          ),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.only(left: 12),
                      a: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Timestamp
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.sm,
                  top: AppSpacing.xxs,
                ),
                child: Text(
                  timestamp!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedFor(brightness),
                    fontSize: 10,
                  ),
                ),
              ),

            // Trailing widget (citations, etc.)
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}
