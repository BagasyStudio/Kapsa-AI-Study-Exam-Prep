import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_gradients.dart';

/// Gradient-styled user message bubble.
///
/// Displays a primary-to-indigo gradient bubble aligned to the right.
class UserMessageBubble extends StatelessWidget {
  final String text;
  final String? timestamp;

  const UserMessageBubble({
    super.key,
    required this.text,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                gradient: AppGradients.primaryToIndigo,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xxl),
                  topRight: Radius.circular(AppRadius.xxl),
                  bottomLeft: Radius.circular(AppRadius.xxl),
                  bottomRight: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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

            // Timestamp
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.sm,
                  top: AppSpacing.xxs,
                ),
                child: Text(
                  timestamp!,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF9CA3AF), // gray-400
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
