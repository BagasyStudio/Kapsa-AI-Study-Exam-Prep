/// Model for an AI-generated insight shown on the home screen.
class AssistantInsightModel {
  final String title;
  final String body;
  final String type; // 'exam_prep', 'weak_area', 'streak', 'review', 'progress'

  const AssistantInsightModel({
    required this.title,
    required this.body,
    this.type = 'progress',
  });

  factory AssistantInsightModel.fromJson(Map<String, dynamic> json) {
    return AssistantInsightModel(
      title: json['title'] as String? ?? 'Study Tip',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'progress',
    );
  }

  /// Returns an appropriate icon name based on insight type.
  String get iconName {
    switch (type) {
      case 'exam_prep':
        return 'school';
      case 'weak_area':
        return 'trending_up';
      case 'streak':
        return 'local_fire_department';
      case 'review':
        return 'refresh';
      case 'progress':
      default:
        return 'auto_awesome';
    }
  }
}
