import 'package:flutter/material.dart';
import 'shareable_card_base.dart';

class SrsReviewShareCard extends StatelessWidget {
  final int totalReviewed;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;
  final int xpEarned;
  final String courseName;
  final String userName;
  final int xpLevel;
  final int dueRemaining;

  const SrsReviewShareCard({
    super.key,
    required this.totalReviewed,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    required this.xpEarned,
    required this.courseName,
    required this.userName,
    required this.xpLevel,
    this.dueRemaining = 0,
  });

  int get retention =>
      totalReviewed > 0 ? ((goodCount + easyCount) / totalReviewed * 100).round() : 0;

  String? get _badge {
    if (dueRemaining == 0) return '📭 Zero Inbox!';
    if (retention >= 90) return '🧠 Memory Machine!';
    return null;
  }

  Color get _retentionColor {
    if (retention >= 80) return const Color(0xFF10B981);
    if (retention >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFF97316);
  }

  @override
  Widget build(BuildContext context) {
    return ShareableCardBase(
      userName: userName,
      xpLevel: xpLevel,
      badgeText: _badge,
      badgeColor: dueRemaining == 0 ? const Color(0xFF10B981) : null,
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
          const SizedBox(height: 20),

          // Retention ring
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
                    value: retention / 100,
                    strokeWidth: 8,
                    backgroundColor: _retentionColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(_retentionColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$retention%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Retention',
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

          const SizedBox(height: 24),

          // Rating breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RatingChip(label: 'Again', count: againCount, color: const Color(0xFFEF4444)),
              _RatingChip(label: 'Hard', count: hardCount, color: const Color(0xFFF97316)),
              _RatingChip(label: 'Good', count: goodCount, color: const Color(0xFF22C55E)),
              _RatingChip(label: 'Easy', count: easyCount, color: const Color(0xFF3B82F6)),
            ],
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBubble(
                icon: Icons.style,
                value: '$totalReviewed',
                label: 'Cards',
              ),
              _StatBubble(
                icon: Icons.bolt,
                value: '+$xpEarned',
                label: 'XP Earned',
                iconColor: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _RatingChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _StatBubble extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const _StatBubble({
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor ?? Colors.white.withValues(alpha: 0.7), size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
