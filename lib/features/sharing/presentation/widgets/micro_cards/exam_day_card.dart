import 'package:flutter/material.dart';
import '../shareable_card_base.dart';

class ExamDayCard extends StatelessWidget {
  final String courseName;
  final int cardsReviewed;
  final double practiceScore;
  final String userName;
  final int xpLevel;

  const ExamDayCard({
    super.key,
    required this.courseName,
    required this.cardsReviewed,
    required this.practiceScore,
    required this.userName,
    required this.xpLevel,
  });

  @override
  Widget build(BuildContext context) {
    return ShareableCardBase(
      userName: userName,
      xpLevel: xpLevel,
      badgeText: '\u{1F4DD} Exam Day!',
      badgeColor: const Color(0xFF3B82F6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('\u{1F3AF}', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),

          Text(
            courseName,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 24),

          Text(
            'Preparation Stats',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),

          const SizedBox(height: 16),

          // Prep stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      '$cardsReviewed',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    Text('Cards Reviewed', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                Column(
                  children: [
                    Text(
                      '${practiceScore.round()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    Text('Practice Score', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Wish me luck! \u{1F340}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
