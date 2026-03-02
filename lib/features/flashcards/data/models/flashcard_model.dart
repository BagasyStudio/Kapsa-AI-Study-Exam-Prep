import '../fsrs.dart';

/// Model representing a flashcard from the `flashcards` table.
///
/// Includes FSRS spaced repetition fields for scheduling reviews.
class FlashcardModel {
  final String id;
  final String deckId;
  final String topic;
  final String questionBefore;
  final String keyword;
  final String questionAfter;
  final String answer;
  final String mastery; // legacy: 'new', 'learning', 'mastered'
  final DateTime? createdAt;

  // ── SRS (FSRS) fields ──
  final double stability;
  final double difficulty;
  final int elapsedDays;
  final int scheduledDays;
  final int reps;
  final int lapses;
  final int srsState; // 0=New, 1=Learning, 2=Review, 3=Relearning
  final DateTime? due;
  final DateTime? lastReview;

  // ── Image Occlusion fields ──
  final String cardType; // 'text' or 'image_occlusion'
  final String? imageUrl;
  final List<Map<String, dynamic>>? occlusionData;

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
    this.stability = 0,
    this.difficulty = 0,
    this.elapsedDays = 0,
    this.scheduledDays = 0,
    this.reps = 0,
    this.lapses = 0,
    this.srsState = 0,
    this.due,
    this.lastReview,
    this.cardType = 'text',
    this.imageUrl,
    this.occlusionData,
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
      stability: (json['stability'] as num?)?.toDouble() ?? 0,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0,
      elapsedDays: json['elapsed_days'] as int? ?? 0,
      scheduledDays: json['scheduled_days'] as int? ?? 0,
      reps: json['reps'] as int? ?? 0,
      lapses: json['lapses'] as int? ?? 0,
      srsState: json['srs_state'] as int? ?? 0,
      due: json['due'] != null
          ? DateTime.parse(json['due'] as String)
          : null,
      lastReview: json['last_review'] != null
          ? DateTime.parse(json['last_review'] as String)
          : null,
      cardType: json['card_type'] as String? ?? 'text',
      imageUrl: json['image_url'] as String?,
      occlusionData: json['occlusion_data'] != null
          ? (json['occlusion_data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
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
      'card_type': cardType,
      if (imageUrl != null) 'image_url': imageUrl,
      if (occlusionData != null) 'occlusion_data': occlusionData,
    };
  }

  /// Returns the SRS fields as a map for updating after a review.
  Map<String, dynamic> toSrsJson() {
    return {
      'stability': stability,
      'difficulty': difficulty,
      'elapsed_days': elapsedDays,
      'scheduled_days': scheduledDays,
      'reps': reps,
      'lapses': lapses,
      'srs_state': srsState,
      'due': due?.toUtc().toIso8601String(),
      'last_review': lastReview?.toUtc().toIso8601String(),
      // Also sync legacy mastery field
      'mastery': _srsStateToMastery(srsState),
    };
  }

  /// Whether this is an image occlusion card.
  bool get isImageOcclusion => cardType == 'image_occlusion';

  FlashcardModel copyWith({
    String? topic,
    String? questionBefore,
    String? keyword,
    String? questionAfter,
    String? answer,
    String? mastery,
    double? stability,
    double? difficulty,
    int? elapsedDays,
    int? scheduledDays,
    int? reps,
    int? lapses,
    int? srsState,
    DateTime? due,
    DateTime? lastReview,
    String? cardType,
    String? imageUrl,
    List<Map<String, dynamic>>? occlusionData,
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
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      elapsedDays: elapsedDays ?? this.elapsedDays,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      srsState: srsState ?? this.srsState,
      due: due ?? this.due,
      lastReview: lastReview ?? this.lastReview,
      cardType: cardType ?? this.cardType,
      imageUrl: imageUrl ?? this.imageUrl,
      occlusionData: occlusionData ?? this.occlusionData,
    );
  }

  /// Whether this card has been mastered (legacy).
  bool get isMastered => mastery == 'mastered';

  /// Whether this card still needs study (legacy).
  bool get needsStudy => mastery != 'mastered';

  /// Whether this card is due for review now.
  bool get isDue => due == null || DateTime.now().isAfter(due!);

  /// Convert to an [FsrsCard] for the FSRS algorithm.
  FsrsCard toFsrsCard() {
    return FsrsCard(
      stability: stability,
      difficulty: difficulty,
      elapsedDays: elapsedDays,
      scheduledDays: scheduledDays,
      reps: reps,
      lapses: lapses,
      state: SrsState.fromValue(srsState),
      due: due ?? DateTime.now(),
      lastReview: lastReview,
    );
  }

  /// Create an updated model from FSRS result.
  FlashcardModel applyFsrsResult(FsrsCard result) {
    return copyWith(
      stability: result.stability,
      difficulty: result.difficulty,
      elapsedDays: result.elapsedDays,
      scheduledDays: result.scheduledDays,
      reps: result.reps,
      lapses: result.lapses,
      srsState: result.state.value,
      due: result.due,
      lastReview: result.lastReview,
      mastery: _srsStateToMastery(result.state.value),
    );
  }

  /// Map SRS state to legacy mastery string for backward compatibility.
  static String _srsStateToMastery(int state) => switch (state) {
        0 => 'new',
        1 => 'learning',
        2 => 'mastered', // "review" state means it was learned
        3 => 'learning', // relearning
        _ => 'new',
      };
}
