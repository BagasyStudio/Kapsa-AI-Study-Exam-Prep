import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import 'streak_pill.dart';

/// Header row with greeting text and streak counter pill.
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '$_greeting,\n$userName',
            style: AppTypography.h1.copyWith(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
        StreakPill(days: streakDays),
      ],
    );
  }
}
