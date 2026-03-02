import 'package:flutter/material.dart';
import 'shareable_card_base.dart';

class FlashcardShareCard extends StatelessWidget {
  final int cardsReviewed;
  final int masteredCount;
  final int studyAgainCount;
  final String courseName;
  final String userName;
  final int xpLevel;
  final int streakDays;

  const FlashcardShareCard({
    super.key,
    required this.cardsReviewed,
    required this.masteredCount,
    required this.studyAgainCount,
    required this.courseName,
    required this.userName,
    required this.xpLevel,
    this.streakDays = 0,
  });

  double get masteryRate =>
      cardsReviewed > 0 ? (masteredCount / cardsReviewed * 100) : 0;

  String? get _badge {
    if (masteryRate >= 90) return '🧠 Memory Machine!';
    if (cardsReviewed >= 50) return '💪 Power Session!';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ShareableCardBase(
      userName: userName,
      xpLevel: xpLevel,
      badgeText: _badge,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            courseName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 28),

          // Big stat
          Text(
            '$cardsReviewed',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cards Reviewed',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 32),

          // Mastery bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mastery Rate',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${masteryRate.round()}%',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: masteryRate / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(icon: Icons.check_circle, value: '$masteredCount', label: 'Mastered', color: const Color(0xFF10B981)),
              _Stat(icon: Icons.refresh, value: '$studyAgainCount', label: 'Study Again', color: const Color(0xFFF97316)),
              _Stat(icon: Icons.local_fire_department, value: '$streakDays', label: 'Streak', color: const Color(0xFFF97316)),
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
