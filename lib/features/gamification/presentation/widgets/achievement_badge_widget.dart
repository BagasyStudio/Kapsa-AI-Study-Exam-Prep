import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/achievement_model.dart';

/// A single achievement badge icon with title.
///
/// Appears locked (greyed out) when [isUnlocked] is false.
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

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
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.12)),
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
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.grey.withValues(alpha: 0.35)),
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
                    ? (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.grey.withValues(alpha: 0.5)),
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
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
                    : Colors.grey.withValues(alpha: isDark ? 0.15 : 0.12),
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
                    : Colors.grey.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.title,
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black54,
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
                  color: Colors.grey.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Locked',
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.grey,
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
            child: const Text('Close'),
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
