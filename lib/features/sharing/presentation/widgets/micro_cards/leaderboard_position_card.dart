import 'package:flutter/material.dart';
import '../shareable_card_base.dart';

class LeaderboardPositionCard extends StatelessWidget {
  final int position;
  final String groupName;
  final int totalXp;
  final String userName;
  final int xpLevel;

  const LeaderboardPositionCard({
    super.key,
    required this.position,
    required this.groupName,
    required this.totalXp,
    required this.userName,
    required this.xpLevel,
  });

  String get _positionEmoji {
    return switch (position) {
      1 => '\u{1F451}',
      2 => '\u{1F948}',
      3 => '\u{1F949}',
      _ => '\u{1F3C5}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ShareableCardBase(
      userName: userName,
      xpLevel: xpLevel,
      badgeText: '$_positionEmoji #$position in Group',
      badgeColor: position == 1 ? const Color(0xFFF59E0B) : const Color(0xFF8B5CF6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_positionEmoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),

          Text(
            '#$position',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'in $groupName',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 6),
                Text(
                  '$totalXp XP this week',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
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
