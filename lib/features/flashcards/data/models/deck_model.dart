import '../../../../core/utils/title_utils.dart';

/// Model representing a flashcard deck from the `flashcard_decks` table.
///
/// Supports parent/child hierarchy:
/// - Parent deck: [parentDeckId] is null, contains aggregate card count
/// - Child deck: [parentDeckId] points to parent, contains actual cards
/// - Legacy flat deck: [parentDeckId] is null with no children
class DeckModel {
  final String id;
  final String courseId;
  final String userId;
  final String title;
  final int cardCount;
  final DateTime? createdAt;

  /// Null for parent/root/legacy decks. Set to parent's ID for child decks.
  final String? parentDeckId;

  /// AI-generated description of the deck's content.
  final String? description;

  /// Index (0-11) into a curated gradient palette for visual covers.
  final int coverGradientIndex;

  /// Pexels stock photo URL for the deck banner. Null = use gradient fallback.
  final String? bannerUrl;

  const DeckModel({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.title,
    this.cardCount = 0,
    this.createdAt,
    this.parentDeckId,
    this.description,
    this.coverGradientIndex = 0,
    this.bannerUrl,
  });

  /// Whether this deck has a Pexels banner image.
  bool get hasBanner => bannerUrl != null && bannerUrl!.isNotEmpty;

  /// Whether this is a parent or root-level deck.
  bool get isParent => parentDeckId == null;

  /// Whether this is a child subdeck.
  bool get isChild => parentDeckId != null;

  /// Clean title for display (strips numeric prefixes, replaces underscores).
  String get displayTitle => cleanDisplayTitle(title);

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
      parentDeckId: json['parent_deck_id'] as String?,
      description: json['description'] as String?,
      coverGradientIndex:
          (json['cover_gradient_index'] as num?)?.toInt() ?? 0,
      bannerUrl: json['banner_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'user_id': userId,
      'title': title,
      'card_count': cardCount,
      if (parentDeckId != null) 'parent_deck_id': parentDeckId,
      if (description != null) 'description': description,
      'cover_gradient_index': coverGradientIndex,
      if (bannerUrl != null) 'banner_url': bannerUrl,
    };
  }

  DeckModel copyWith({
    String? title,
    int? cardCount,
    String? parentDeckId,
    String? description,
    int? coverGradientIndex,
    String? bannerUrl,
  }) {
    return DeckModel(
      id: id,
      courseId: courseId,
      userId: userId,
      title: title ?? this.title,
      cardCount: cardCount ?? this.cardCount,
      createdAt: createdAt,
      parentDeckId: parentDeckId ?? this.parentDeckId,
      description: description ?? this.description,
      coverGradientIndex: coverGradientIndex ?? this.coverGradientIndex,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }
}
