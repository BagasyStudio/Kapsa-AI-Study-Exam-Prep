import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/achievement_model.dart';

/// A single achievement badge icon with title.
///
/// Appears locked (greyed out) when [isUnlocked] is false.
/// Forced immersive dark styling.
class AchievementBadgeWidget extends StatelessWidget {
  final BadgeDefinition badge;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final VoidCallback? onTap;

  const AchievementBadgeWidget({
    super.key,
    required this.badge,
    this.isUnlocked = false,
    this.unlockedAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showDetail(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isUnlocked
                  ? LinearGradient(
                      colors: badge.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isUnlocked
                  ? null
                  : Colors.white.withValues(alpha: 0.06),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: badge.gradient.first.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              badge.icon,
              size: 26,
              color: isUnlocked
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(height: 6),
          // Title
          SizedBox(
            width: 72,
            child: Text(
              badge.title,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.w400,
                color: isUnlocked
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.25),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.immersiveCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: badge.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUnlocked
                    ? null
                    : Colors.white.withValues(alpha: 0.08),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color:
                              badge.gradient.first.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                badge.icon,
                size: 38,
                color: isUnlocked
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.title,
              style: AppTypography.h3.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            if (isUnlocked && unlockedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Unlocked ${_formatDate(unlockedAt!)}',
                style: AppTypography.caption.copyWith(
                  color: badge.gradient.first,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (!isUnlocked) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Locked',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
