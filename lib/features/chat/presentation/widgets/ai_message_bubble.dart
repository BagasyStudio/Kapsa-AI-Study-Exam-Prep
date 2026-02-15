import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

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
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.xxl),
                      topRight: Radius.circular(AppRadius.xxl),
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(AppRadius.xxl),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
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
                    styleSheet: MarkdownStyleSheet(
                      p: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF374151),
                        height: 1.6,
                      ),
                      strong: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                      ),
                      em: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF374151),
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                      h1: AppTypography.h3.copyWith(
                        color: const Color(0xFF1F2937),
                      ),
                      h2: AppTypography.labelLarge.copyWith(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.w700,
                      ),
                      h3: AppTypography.labelLarge.copyWith(
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                      ),
                      listBullet: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                      code: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFFE11D48),
                        backgroundColor: const Color(0xFFF1F5F9),
                        fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
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
                    color: AppColors.textMuted,
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
