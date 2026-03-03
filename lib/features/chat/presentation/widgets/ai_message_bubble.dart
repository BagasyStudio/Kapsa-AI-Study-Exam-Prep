import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/markdown_math_builder.dart';

/// AI message bubble with solid background, left accent border, and avatar support.
///
/// Displays a clean bubble aligned to the left side with an optional avatar orb,
/// left accent border, and grouped timestamp support.
/// Renders AI responses as markdown for rich formatting.
/// Supports inline action cards for tappable actions detected in the message.
class AiMessageBubble extends StatelessWidget {
  final String text;
  final String? timestamp;
  final Widget? trailing; // for citation chips below message
  final Widget? actionCards; // for inline tappable action cards
  final bool showAvatar; // show avatar orb to the left
  final bool isLastInGroup; // show timestamp only when last in group

  const AiMessageBubble({
    super.key,
    required this.text,
    this.timestamp,
    this.trailing,
    this.actionCards,
    this.showAvatar = false,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = Theme.of(context).brightness;

    final bubbleBorderRadius = showAvatar
        ? const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(AppRadius.xl),
            bottomLeft: Radius.circular(AppRadius.xl),
            bottomRight: Radius.circular(AppRadius.xl),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(AppRadius.xl),
          );

    final bubbleWidget = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2040) : const Color(0xFFF8F9FA),
        borderRadius: bubbleBorderRadius,
        border: Border(
          left: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MarkdownBody(
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

          // Inline action cards (rendered inside the bubble)
          if (actionCards != null) actionCards!,
        ],
      ),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar row or indented bubble
            if (showAvatar)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar orb
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.3),
                        colors: [
                          AppColors.primaryLight,
                          AppColors.primary,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Bubble
                  Expanded(child: bubbleWidget),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 36), // 28 orb + 8 gap
                child: bubbleWidget,
              ),

            // Timestamp (only when last in group)
            if (isLastInGroup && timestamp != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: 36 + AppSpacing.sm, // align with bubble text
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
                padding: const EdgeInsets.only(
                  left: 36,
                  top: AppSpacing.xs,
                ),
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}
