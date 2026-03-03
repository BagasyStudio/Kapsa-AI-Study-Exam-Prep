import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_limits.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Chat input bar with multiline text field and send/stop action button.
///
/// Fixed at the bottom of the chat screen. Solid background (no glass blur).
/// Shows a send button by default, switches to a stop button when [isLoading].
class ChatInputBar extends StatelessWidget {
  final TextEditingController? controller;
  final VoidCallback? onSend;
  final VoidCallback? onStop;
  final ValueChanged<String>? onChanged;
  final bool isLoading;

  const ChatInputBar({
    super.key,
    this.controller,
    this.onSend,
    this.onStop,
    this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final backgroundColor = brightness == Brightness.light
        ? Colors.white
        : AppColors.cardDark;

    final topBorderColor = brightness == Brightness.light
        ? const Color(0xFFE5E7EB)
        : Colors.white.withValues(alpha: 0.08);

    final fieldBackground = brightness == Brightness.light
        ? const Color(0xFFF3F4F6)
        : Colors.white.withValues(alpha: 0.06);

    final hintColor = AppColors.textMutedFor(brightness);
    final textColor = AppColors.textPrimaryFor(brightness);

    // Determine action button properties based on loading state.
    final actionColor = isLoading ? AppColors.error : AppColors.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        bottomPadding + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(color: topBorderColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(
                color: fieldBackground,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                maxLength: AppLimits.maxChatMessageLength,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    AppLimits.maxChatMessageLength,
                  ),
                ],
                style: AppTypography.bodyMedium.copyWith(color: textColor),
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: hintColor,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Action button (send / stop)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: TapScale(
              onTap: isLoading ? onStop : onSend,
              scaleDown: 0.90,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: actionColor,
                  boxShadow: [
                    BoxShadow(
                      color: actionColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? const Icon(
                          Icons.stop_rounded,
                          key: ValueKey('stop'),
                          color: Colors.white,
                          size: 22,
                        )
                      : const Icon(
                          Icons.arrow_upward,
                          key: ValueKey('send'),
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
