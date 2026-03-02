import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../data/models/group_member_model.dart';

/// Row widget for leaderboard showing rank, name, and XP.
class LeaderboardRow extends StatelessWidget {
  final GroupMemberModel member;
  final int rank;
  final bool isCurrentUser;

  const LeaderboardRow({
    super.key,
    required this.member,
    required this.rank,
    this.isCurrentUser = false,
  });

  Color? get _medalColor => switch (rank) {
        1 => const Color(0xFFFFD700),
        2 => const Color(0xFFC0C0C0),
        3 => const Color(0xFFCD7F32),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.08)
            : isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: _medalColor != null
                ? Icon(Icons.emoji_events, size: 22, color: _medalColor)
                : Text(
                    '$rank',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textMutedFor(brightness),
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              (member.fullName ?? '?')[0].toUpperCase(),
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Name
          Expanded(
            child: Text(
              member.fullName ?? 'Member',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textPrimaryFor(brightness),
                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '${member.xpTotal ?? 0} XP',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
