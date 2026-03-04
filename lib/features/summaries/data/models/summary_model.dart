class SummaryModel {
  final String id;
  final String courseId;
  final String? materialId;
  final String userId;
  final String title;
  final String content;
  final List<String> bulletPoints;
  final int wordCount;
  final DateTime? createdAt;

  const SummaryModel({
    required this.id,
    required this.courseId,
    this.materialId,
    required this.userId,
    required this.title,
    required this.content,
    this.bulletPoints = const [],
    this.wordCount = 0,
    this.createdAt,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    final rawBullets = json['bullet_points'];
    List<String> bullets = [];
    if (rawBullets is List) {
      bullets = rawBullets.map((e) => e.toString()).toList();
    }

    return SummaryModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      materialId: json['material_id'] as String?,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      bulletPoints: bullets,
      wordCount: (json['word_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
