import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../gamification/presentation/widgets/xp_level_badge.dart';
import 'streak_pill.dart';

/// Header row with greeting text, streak counter pill, and XP badge.
class GreetingHeader extends StatelessWidget {
  final String userName;
  final int streakDays;

  const GreetingHeader({
    super.key,
    required this.userName,
    required this.streakDays,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '$_greeting,\n$userName',
            style: AppTypography.h1.copyWith(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 26,
              height: 1.2,
              color: AppColors.textPrimaryFor(brightness),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StreakPill(days: streakDays),
            const SizedBox(height: 6),
            const XpLevelBadge(),
          ],
        ),
      ],
    );
  }
}
