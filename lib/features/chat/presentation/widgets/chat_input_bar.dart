import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Glass-styled chat input bar (light mode).
///
/// Fixed at the bottom of the chat screen. Includes an add button,
/// text field with mic icon, and gradient send button.
/// Matches mockup: glass-input { white/50, blur 20, border-top white/40 }.
class ChatInputBar extends StatelessWidget {
  final TextEditingController? controller;
  final VoidCallback? onSend;
  final VoidCallback? onMic;
  final ValueChanged<String>? onChanged;

  const ChatInputBar({
    super.key,
    this.controller,
    this.onSend,
    this.onMic,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            bottomPadding + AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Add button
              TapScale(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attach file coming soon')),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF3F4F6), // gray-100
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color(0xFF6B7280), // gray-500
                    size: 22,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // Text field with mic inside
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onChanged: onChanged,
                          style: AppTypography.bodyMedium.copyWith(
                            color: const Color(0xFF1F2937), // gray-800
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ask a follow up question...',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: const Color(0xFF6B7280), // gray-500
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            isDense: true,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      // Mic button inside field
                      TapScale(
                        onTap: onMic,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.mic,
                            color: const Color(0xFF9CA3AF), // gray-400
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // Send button
              TapScale(
                onTap: onSend,
                scaleDown: 0.90,
                child: Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
