/// Model representing a flashcard from the `flashcards` table.
class FlashcardModel {
  final String id;
  final String deckId;
  final String topic;
  final String questionBefore;
  final String keyword;
  final String questionAfter;
  final String answer;
  final String mastery; // 'new', 'learning', 'mastered'
  final DateTime? createdAt;

  const FlashcardModel({
    required this.id,
    required this.deckId,
    required this.topic,
    required this.questionBefore,
    required this.keyword,
    this.questionAfter = '',
    required this.answer,
    this.mastery = 'new',
    this.createdAt,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as String,
      deckId: json['deck_id'] as String,
      topic: json['topic'] as String,
      questionBefore: json['question_before'] as String,
      keyword: json['keyword'] as String,
      questionAfter: json['question_after'] as String? ?? '',
      answer: json['answer'] as String,
      mastery: json['mastery'] as String? ?? 'new',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deck_id': deckId,
      'topic': topic,
      'question_before': questionBefore,
      'keyword': keyword,
      'question_after': questionAfter,
      'answer': answer,
      'mastery': mastery,
    };
  }

  FlashcardModel copyWith({
    String? topic,
    String? questionBefore,
    String? keyword,
    String? questionAfter,
    String? answer,
    String? mastery,
  }) {
    return FlashcardModel(
      id: id,
      deckId: deckId,
      topic: topic ?? this.topic,
      questionBefore: questionBefore ?? this.questionBefore,
      keyword: keyword ?? this.keyword,
      questionAfter: questionAfter ?? this.questionAfter,
      answer: answer ?? this.answer,
      mastery: mastery ?? this.mastery,
      createdAt: createdAt,
    );
  }

  /// Whether this card has been mastered.
  bool get isMastered => mastery == 'mastered';

  /// Whether this card still needs study.
  bool get needsStudy => mastery != 'mastered';
}
