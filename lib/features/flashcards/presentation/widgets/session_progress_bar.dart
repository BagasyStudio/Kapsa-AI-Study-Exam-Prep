import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';

/// Top header bar for the flashcard session.
///
/// Close button | progress bar with count | more options button.
class SessionProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final String courseLabel;
  final VoidCallback? onClose;
  final VoidCallback? onMore;

  const SessionProgressBar({
    super.key,
    required this.current,
    required this.total,
    required this.courseLabel,
    this.onClose,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Row(
      children: [
        // Close button
        _GlassCircleButton(
          icon: Icons.close,
          onTap: onClose,
        ),

        const SizedBox(width: 16),

        // Progress section
        Expanded(
          child: Column(
            children: [
              // Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    courseLabel.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMutedFor(
                          Theme.of(context).brightness),
                      letterSpacing: 1.5,
                      fontSize: 9,
                    ),
                  ),
                  Text(
                    '$current / $total',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMutedFor(
                          Theme.of(context).brightness),
                      letterSpacing: 1.5,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar (animated fill)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                      borderRadius: AppRadius.borderRadiusPill,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.borderRadiusPill,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.8),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // More options button
        _GlassCircleButton(
          icon: Icons.more_horiz,
          onTap: onMore,
        ),
      ],
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassCircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.45),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.textSecondaryFor(brightness),
            ),
          ),
        ),
      ),
    );
  }
}
