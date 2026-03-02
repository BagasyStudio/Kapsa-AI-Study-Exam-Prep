import 'package:flutter/material.dart';
import '../../data/models/knowledge_score_model.dart';
import 'shareable_card_base.dart';

class KnowledgeScoreShareCard extends StatelessWidget {
  final KnowledgeScoreModel score;
  final String userName;
  final int xpLevel;

  const KnowledgeScoreShareCard({
    super.key,
    required this.score,
    required this.userName,
    required this.xpLevel,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = Color(KnowledgeScoreModel.rankColorValue(score.rank));

    return ShareableCardBase(
      userName: userName,
      xpLevel: xpLevel,
      badgeText: score.rank,
      badgeColor: rankColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Score ring
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: score.overallScore / 100,
                    strokeWidth: 8,
                    backgroundColor: rankColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${score.overallScore.round()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Knowledge Score',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Metrics grid 2x4
          _buildMiniGrid(),

          const SizedBox(height: 16),

          // CTA
          Text(
            "What's your Knowledge Score?",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGrid() {
    final metrics = score.metricsMap.entries.toList();
    final infoMap = KnowledgeScoreModel.metricInfoMap;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics.map((entry) {
        final info = infoMap[entry.key];
        final color = Color(info?.colorValue ?? 0xFF6467F2);

        return Container(
          width: 75,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Text(
                '${entry.value.round()}',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                info?.label ?? entry.key,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
