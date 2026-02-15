/// Model representing a flashcard deck from the `flashcard_decks` table.
class DeckModel {
  final String id;
  final String courseId;
  final String userId;
  final String title;
  final int cardCount;
  final DateTime? createdAt;

  const DeckModel({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.title,
    this.cardCount = 0,
    this.createdAt,
  });

  factory DeckModel.fromJson(Map<String, dynamic> json) {
    return DeckModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      cardCount: (json['card_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'user_id': userId,
      'title': title,
      'card_count': cardCount,
    };
  }

  DeckModel copyWith({
    String? title,
    int? cardCount,
  }) {
    return DeckModel(
      id: id,
      courseId: courseId,
      userId: userId,
      title: title ?? this.title,
      cardCount: cardCount ?? this.cardCount,
      createdAt: createdAt,
    );
  }
}
