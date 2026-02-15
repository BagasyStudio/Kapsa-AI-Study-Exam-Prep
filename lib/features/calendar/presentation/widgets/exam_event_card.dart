import 'package:flutter/material.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A gradient pink card for exam events in the timeline.
///
/// Shows exam title, time, course label and a study CTA.
class ExamEventCard extends StatelessWidget {
  final String title;
  final String time;
  final String courseLabel;
  final VoidCallback? onStudy;

  const ExamEventCard({
    super.key,
    required this.title,
    required this.time,
    required this.courseLabel,
    this.onStudy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppGradients.examPink,
        borderRadius: AppRadius.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9A9E).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Exam icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      courseLabel,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Time + study button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onStudy,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: AppRadius.borderRadiusPill,
                  ),
                  child: Text(
                    'Study Now',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
