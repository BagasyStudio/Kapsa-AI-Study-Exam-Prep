import 'package:flutter/material.dart';
import 'shareable_card_base.dart';

class QuizShareCard extends StatelessWidget {
  final double scorePercent; // 0-100
  final String grade;
  final int correctCount;
  final int totalCount;
  final String courseName;
  final String userName;
  final int xpLevel;
  final int streakDays;

  const QuizShareCard({
    super.key,
    required this.scorePercent,
    required this.grade,
    required this.correctCount,
    required this.totalCount,
    required this.courseName,
    required this.userName,
    required this.xpLevel,
    this.streakDays = 0,
  });

  String? get _badge {
    if (scorePercent >= 100) return '🏆 Perfect Score!';
    if (scorePercent >= 90) return '⭐ Outstanding!';
    return null;
  }

  Color get _ringColor {
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
      badgeColor: scorePercent >= 100 ? const Color(0xFFF59E0B) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Course name
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

          // Score ring
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: scorePercent / 100,
                    strokeWidth: 8,
                    backgroundColor: _ringColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(_ringColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${scorePercent.round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quiz Score',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Grade badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _ringColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'Grade: $grade',
              style: TextStyle(
                color: _ringColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Secondary stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(
                icon: Icons.check_circle_outline,
                value: '$correctCount/$totalCount',
                label: 'Correct',
              ),
              _MiniStat(
                icon: Icons.local_fire_department,
                value: '$streakDays',
                label: 'Day Streak',
                iconColor: const Color(0xFFF97316),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor ?? Colors.white.withValues(alpha: 0.7),
            size: 16,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
