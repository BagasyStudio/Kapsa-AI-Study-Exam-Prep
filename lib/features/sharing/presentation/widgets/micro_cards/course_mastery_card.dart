import 'package:flutter/material.dart';
import '../shareable_card_base.dart';

class CourseMasteryCard extends StatelessWidget {
  final String courseName;
  final int totalCards;
  final int quizzesTaken;
  final int daysToMaster;
  final String userName;
  final int xpLevel;

  const CourseMasteryCard({
    super.key,
    required this.courseName,
    required this.totalCards,
    required this.quizzesTaken,
    required this.daysToMaster,
    required this.userName,
    required this.xpLevel,
  });

  @override
  Widget build(BuildContext context) {
    return ShareableCardBase(
      userName: userName,
      xpLevel: xpLevel,
      badgeText: '\u{1F393} Course Mastered!',
      badgeColor: const Color(0xFF10B981),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Trophy
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.3),
                  const Color(0xFF059669).withValues(alpha: 0.15),
                ],
              ),
            ),
            child: const Icon(Icons.emoji_events, color: Color(0xFFFBBF24), size: 36),
          ),

          const SizedBox(height: 20),

          Text(
            'Mastered',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            courseName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 28),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(icon: Icons.style, value: '$totalCards', label: 'Cards', color: const Color(0xFF3B82F6)),
              _Stat(icon: Icons.quiz, value: '$quizzesTaken', label: 'Quizzes', color: const Color(0xFF8B5CF6)),
              _Stat(icon: Icons.calendar_today, value: '$daysToMaster', label: 'Days', color: const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _Stat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
      ],
    );
  }
}
