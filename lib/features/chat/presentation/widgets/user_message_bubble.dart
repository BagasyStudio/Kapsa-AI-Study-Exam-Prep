import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Gradient-styled user message bubble with grouping support.
///
/// Displays a refined three-stop gradient bubble aligned to the right.
/// When [isLastInGroup] is true (default), the optional [timestamp] is shown.
class UserMessageBubble extends StatelessWidget {
  final String text;
  final String? timestamp;
  final bool isLastInGroup;

  const UserMessageBubble({
    super.key,
    required this.text,
    this.timestamp,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Gradient bubble
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6467F2),
                    Color(0xFF5B5FE6),
                    Color(0xFF5558DB),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.card),
                  topRight: Radius.circular(AppRadius.card),
                  bottomLeft: Radius.circular(AppRadius.card),
                  bottomRight: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),

            // Timestamp (only shown for the last message in a group)
            if (isLastInGroup && timestamp != null)
              Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.sm,
                  top: AppSpacing.xxs,
                ),
                child: Text(
                  timestamp!,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
