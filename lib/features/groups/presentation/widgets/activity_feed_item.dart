import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/group_activity_model.dart';

/// Feed item widget displaying a single group activity.
class ActivityFeedItem extends StatelessWidget {
  final GroupActivityModel activity;

  const ActivityFeedItem({super.key, required this.activity});

  IconData get _icon => switch (activity.activityType) {
        'member_joined' => Icons.person_add,
        'quiz_completed' => Icons.quiz,
        'flashcards_reviewed' => Icons.style,
        'material_uploaded' => Icons.upload_file,
        'streak' => Icons.local_fire_department,
        _ => Icons.notifications_none,
      };

  Color get _iconColor => switch (activity.activityType) {
        'member_joined' => const Color(0xFF22C55E),
        'quiz_completed' => const Color(0xFF3B82F6),
        'flashcards_reviewed' => AppColors.primary,
        'material_uploaded' => const Color(0xFFF59E0B),
        'streak' => const Color(0xFFEF4444),
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _iconColor.withValues(alpha: 0.1),
            ),
            child: Icon(_icon, size: 18, color: _iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: activity.userName ?? 'Someone',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimaryFor(brightness),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: ' ${activity.title}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryFor(brightness),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.timeAgo,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedFor(brightness),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
