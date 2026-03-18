import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../providers/course_provider.dart';

/// Aggregated stats for a course (materials, decks, due cards).
class CourseStats {
  final int materialCount;
  final int reviewedCount;
  final int deckCount;
  final int totalCards;
  final int dueCards;

  const CourseStats({
    this.materialCount = 0,
    this.reviewedCount = 0,
    this.deckCount = 0,
    this.totalCards = 0,
    this.dueCards = 0,
  });

  /// Completion rate: reviewed materials / total materials (0.0 to 1.0).
  double get completionRate =>
      materialCount > 0 ? reviewedCount / materialCount : 0.0;
}

/// Provider that aggregates course statistics.
final courseStatsProvider = FutureProvider.autoDispose
    .family<CourseStats, String>((ref, courseId) async {
  // Watch dependent providers
  final materials =
      await ref.watch(courseMaterialsProvider(courseId).future);
  final decks =
      await ref.watch(flashcardDecksProvider(courseId).future);
  final dueCount =
      await ref.watch(dueCardsCountProvider(courseId).future);

  int totalCards = 0;
  for (final deck in decks) {
    totalCards += deck.cardCount;
  }

  final reviewedCount = materials.where((m) => m.isReviewed).length;

  return CourseStats(
    materialCount: materials.length,
    reviewedCount: reviewedCount,
    deckCount: decks.length,
    totalCards: totalCards,
    dueCards: dueCount,
  );
});
