import 'package:flutter/material.dart';
import '../shareable_card_base.dart';

class StreakMilestoneCard extends StatelessWidget {
  final int streakDays;
  final int totalXp;
  final String userName;
  final int xpLevel;

  const StreakMilestoneCard({
    super.key,
    required this.streakDays,
    required this.totalXp,
    required this.userName,
    required this.xpLevel,
  });

  String get _milestone {
    if (streakDays >= 365) return '\u{1F3C6} One Year!';
    if (streakDays >= 100) return '\u{1F4AF} Century!';
    if (streakDays >= 50) return '\u{1F525} On Fire!';
    if (streakDays >= 30) return '\u{26A1} Unstoppable!';
    return '\u{2728} Milestone!';
  }

  @override
  Widget build(BuildContext context) {
    return ShareableCardBase(
      userName: userName,
      xpLevel: xpLevel,
      badgeText: _milestone,
      badgeColor: const Color(0xFFF97316),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fire emoji big
          const Text('\u{1F525}', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),

          // Streak number
          Text(
            '$streakDays',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Day Streak',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 28),

          // Challenge text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              'Can you beat my streak? \u{1F914}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // XP stat
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 16),
              const SizedBox(width: 4),
              Text(
                '$totalXp XP earned',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
