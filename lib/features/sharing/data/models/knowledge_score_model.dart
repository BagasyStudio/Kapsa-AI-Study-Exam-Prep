/// Represents a user's Knowledge Score with 8 metrics.
class KnowledgeScoreModel {
  final double overallScore; // 0-100
  final String rank;
  final double retention;
  final double accuracy;
  final double consistency;
  final double speed;
  final double depth;
  final double mastery;
  final double examReadiness;
  final double dedication;
  final String? oracleAnalysis;

  const KnowledgeScoreModel({
    required this.overallScore,
    required this.rank,
    required this.retention,
    required this.accuracy,
    required this.consistency,
    required this.speed,
    required this.depth,
    required this.mastery,
    required this.examReadiness,
    required this.dedication,
    this.oracleAnalysis,
  });

  /// Determine rank from overall score.
  static String rankFromScore(double score) {
    if (score >= 95) return 'Genius';
    if (score >= 80) return 'Master';
    if (score >= 60) return 'Expert';
    if (score >= 40) return 'Scholar';
    if (score >= 20) return 'Apprentice';
    return 'Beginner';
  }

  /// Color for a given rank.
  static int rankColorValue(String rank) {
    return switch (rank) {
      'Genius' => 0xFFE879F9,    // Rainbow/pink
      'Master' => 0xFF8B5CF6,    // Purple
      'Expert' => 0xFFF59E0B,    // Gold
      'Scholar' => 0xFFC0C0C0,   // Silver
      'Apprentice' => 0xFFCD7F32, // Bronze
      _ => 0xFF9CA3AF,           // Gray
    };
  }

  /// Icon for each metric.
  static Map<String, MetricInfo> get metricInfoMap => {
    'retention': MetricInfo('Retention', 0xFF10B981, 'memory'),
    'accuracy': MetricInfo('Accuracy', 0xFFF59E0B, 'target'),
    'consistency': MetricInfo('Consistency', 0xFF10B981, 'calendar'),
    'speed': MetricInfo('Speed', 0xFFF97316, 'speed'),
    'depth': MetricInfo('Depth', 0xFF3B82F6, 'layers'),
    'mastery': MetricInfo('Mastery', 0xFFF59E0B, 'star'),
    'exam_readiness': MetricInfo('Exam Ready', 0xFF10B981, 'school'),
    'dedication': MetricInfo('Dedication', 0xFF3B82F6, 'timer'),
  };

  Map<String, double> get metricsMap => {
    'retention': retention,
    'accuracy': accuracy,
    'consistency': consistency,
    'speed': speed,
    'depth': depth,
    'mastery': mastery,
    'exam_readiness': examReadiness,
    'dedication': dedication,
  };
}

class MetricInfo {
  final String label;
  final int colorValue;
  final String iconKey;

  const MetricInfo(this.label, this.colorValue, this.iconKey);
}
