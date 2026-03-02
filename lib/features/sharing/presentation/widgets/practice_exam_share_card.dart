import 'package:flutter/material.dart';
import 'shareable_card_base.dart';

class PracticeExamShareCard extends StatelessWidget {
  final double scorePercent;
  final String grade;
  final int correctCount;
  final int totalCount;
  final String courseName;
  final String userName;
  final int xpLevel;

  const PracticeExamShareCard({
    super.key,
    required this.scorePercent,
    required this.grade,
    required this.correctCount,
    required this.totalCount,
    required this.courseName,
    required this.userName,
    required this.xpLevel,
  });

  String? get _badge {
    if (scorePercent >= 100) return '🏆 Perfect Score!';
    if (scorePercent >= 85) return '✅ Exam Ready!';
    return null;
  }

  Color get _scoreColor {
    if (scorePercent >= 90) return const Color(0xFF10B981);
    if (scorePercent >= 70) return const Color(0xFFF59E0B);
    if (scorePercent >= 50) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return ShareableCardBase(
      userName: userName,
      xpLevel: xpLevel,
      badgeText: _badge,
      badgeColor: scorePercent >= 85 ? const Color(0xFF10B981) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Exam icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _scoreColor.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.school, color: _scoreColor, size: 24),
          ),
          const SizedBox(height: 8),
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

          const SizedBox(height: 20),

          // Big score
          Text(
            '${scorePercent.round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Practice Exam',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          // Grade + correct
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Grade: $grade',
                  style: TextStyle(color: _scoreColor, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  '$correctCount/$totalCount correct',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
