import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A vertical timeline with connector dots and time labels.
///
/// Each timeline entry shows a time label on the left, a vertical
/// line with a connector dot in the middle, and a content widget on the right.
class TimelineView extends StatelessWidget {
  final List<TimelineEntry> entries;

  const TimelineView({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final isFirst = index == 0;
        final isLast = index == entries.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time label
              SizedBox(
                width: 52,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    entry.time,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),

              // Timeline line + dot
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    // Top line segment
                    if (!isFirst)
                      Container(
                        width: 2,
                        height: 8,
                        color: AppColors.textMuted.withValues(alpha: 0.2),
                      ),
                    // Dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entry.dotColor ?? AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: (entry.dotColor ?? AppColors.primary)
                                .withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    // Bottom line segment (flex to fill remaining height)
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.textMuted.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: entry.content,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// A single entry in the timeline.
class TimelineEntry {
  final String time;
  final Widget content;
  final Color? dotColor;

  const TimelineEntry({
    required this.time,
    required this.content,
    this.dotColor,
  });
}
