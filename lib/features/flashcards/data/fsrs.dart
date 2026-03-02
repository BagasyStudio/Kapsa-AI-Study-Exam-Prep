import 'dart:math';

/// FSRS v5 — Free Spaced Repetition Scheduler
///
/// A modern, open-source spaced repetition algorithm that outperforms SM-2.
/// Runs entirely client-side (no backend dependency).
///
/// Reference: https://github.com/open-spaced-repetition/fsrs4anki
/// Paper: https://arxiv.org/abs/2402.02657

// ── Rating ──

enum Rating {
  again(1),
  hard(2),
  good(3),
  easy(4);

  final int value;
  const Rating(this.value);

  static Rating fromValue(int v) => switch (v) {
        1 => Rating.again,
        2 => Rating.hard,
        3 => Rating.good,
        _ => Rating.easy,
      };
}

// ── Card State ──

enum SrsState {
  newCard(0),
  learning(1),
  review(2),
  relearning(3);

  final int value;
  const SrsState(this.value);

  static SrsState fromValue(int v) => switch (v) {
        1 => SrsState.learning,
        2 => SrsState.review,
        3 => SrsState.relearning,
        _ => SrsState.newCard,
      };
}

// ── Card ──

class FsrsCard {
  final double stability;
  final double difficulty;
  final int elapsedDays;
  final int scheduledDays;
  final int reps;
  final int lapses;
  final SrsState state;
  final DateTime due;
  final DateTime? lastReview;

  const FsrsCard({
    this.stability = 0,
    this.difficulty = 0,
    this.elapsedDays = 0,
    this.scheduledDays = 0,
    this.reps = 0,
    this.lapses = 0,
    this.state = SrsState.newCard,
    required this.due,
    this.lastReview,
  });

  FsrsCard copyWith({
    double? stability,
    double? difficulty,
    int? elapsedDays,
    int? scheduledDays,
    int? reps,
    int? lapses,
    SrsState? state,
    DateTime? due,
    DateTime? lastReview,
  }) {
    return FsrsCard(
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      elapsedDays: elapsedDays ?? this.elapsedDays,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      state: state ?? this.state,
      due: due ?? this.due,
      lastReview: lastReview ?? this.lastReview,
    );
  }
}

// ── Review Log ──

class ReviewLog {
  final Rating rating;
  final SrsState state; // state BEFORE review
  final int scheduledDays;
  final int elapsedDays;
  final DateTime reviewedAt;

  const ReviewLog({
    required this.rating,
    required this.state,
    required this.scheduledDays,
    required this.elapsedDays,
    required this.reviewedAt,
  });
}

// ── Scheduling Result ──

class SchedulingResult {
  final FsrsCard card;
  final ReviewLog log;

  const SchedulingResult({required this.card, required this.log});
}

// ── FSRS Algorithm ──

class FSRS {
  // FSRS v5 default parameters (w0..w18)
  static const List<double> _defaultW = [
    0.4072, // w0: initial stability for Again
    1.1829, // w1: initial stability for Hard
    3.1262, // w2: initial stability for Good
    15.4722, // w3: initial stability for Easy
    7.2102, // w4: difficulty weight
    0.5316, // w5: difficulty decay
    1.0651, // w6: stability decay
    0.0046, // w7: stability factor
    1.5418, // w8: retrievability weight
    0.1718, // w9: mean reversion
    1.0252, // w10: review stability factor
    2.0106, // w11: fail stability factor (hard)
    0.0059, // w12: fail stability factor (lapse)
    0.579, // w13: fail stability factor (easy)
    0.7185, // w14: short-term stability decay
    0.3589, // w15: short-term stability mean reversion
    0.1497, // w16
    3.3498, // w17
    0.3539, // w18
  ];

  final List<double> w;

  /// Desired retention rate (0..1). Default 0.9 = 90%.
  final double requestRetention;

  /// Maximum interval in days.
  final int maximumInterval;

  FSRS({
    List<double>? parameters,
    this.requestRetention = 0.9,
    this.maximumInterval = 36500,
  }) : w = parameters ?? _defaultW;

  /// Schedule a review of [card] with the given [rating].
  ///
  /// Returns a [SchedulingResult] with the updated card and review log.
  SchedulingResult repeat(FsrsCard card, Rating rating, {DateTime? now}) {
    now ??= DateTime.now();

    final elapsedDays = card.state == SrsState.newCard
        ? 0
        : (card.lastReview != null
            ? now.difference(card.lastReview!).inDays
            : 0);

    final log = ReviewLog(
      rating: rating,
      state: card.state,
      scheduledDays: card.scheduledDays,
      elapsedDays: elapsedDays,
      reviewedAt: now,
    );

    FsrsCard next;

    switch (card.state) {
      case SrsState.newCard:
        next = _scheduleNew(card, rating, now);
      case SrsState.learning:
      case SrsState.relearning:
        next = _scheduleLearning(card, rating, now, elapsedDays);
      case SrsState.review:
        next = _scheduleReview(card, rating, now, elapsedDays);
    }

    return SchedulingResult(card: next, log: log);
  }

  /// Preview all 4 ratings for a card. Returns a map of Rating → interval string.
  Map<Rating, String> previewIntervals(FsrsCard card, {DateTime? now}) {
    now ??= DateTime.now();
    final result = <Rating, String>{};
    for (final r in Rating.values) {
      final sr = repeat(card, r, now: now);
      final days = sr.card.scheduledDays;
      result[r] = _formatInterval(days);
    }
    return result;
  }

  static String _formatInterval(int days) {
    if (days < 1) return '<1m';
    if (days == 1) return '1d';
    if (days < 30) return '${days}d';
    if (days < 365) return '${(days / 30).round()}mo';
    return '${(days / 365).toStringAsFixed(1)}y';
  }

  // ── New card scheduling ──

  FsrsCard _scheduleNew(FsrsCard card, Rating rating, DateTime now) {
    final s0 = _initStability(rating);
    final d0 = _initDifficulty(rating);

    switch (rating) {
      case Rating.again:
        return card.copyWith(
          stability: s0,
          difficulty: d0,
          state: SrsState.learning,
          scheduledDays: 0,
          due: now.add(const Duration(minutes: 1)),
          reps: card.reps + 1,
          lapses: card.lapses + 1,
          lastReview: now,
          elapsedDays: 0,
        );
      case Rating.hard:
        return card.copyWith(
          stability: s0,
          difficulty: d0,
          state: SrsState.learning,
          scheduledDays: 0,
          due: now.add(const Duration(minutes: 5)),
          reps: card.reps + 1,
          lastReview: now,
          elapsedDays: 0,
        );
      case Rating.good:
        return card.copyWith(
          stability: s0,
          difficulty: d0,
          state: SrsState.learning,
          scheduledDays: 0,
          due: now.add(const Duration(minutes: 10)),
          reps: card.reps + 1,
          lastReview: now,
          elapsedDays: 0,
        );
      case Rating.easy:
        final interval = _nextInterval(s0);
        return card.copyWith(
          stability: s0,
          difficulty: d0,
          state: SrsState.review,
          scheduledDays: interval,
          due: now.add(Duration(days: interval)),
          reps: card.reps + 1,
          lastReview: now,
          elapsedDays: 0,
        );
    }
  }

  // ── Learning / Relearning scheduling ──

  FsrsCard _scheduleLearning(
      FsrsCard card, Rating rating, DateTime now, int elapsedDays) {
    switch (rating) {
      case Rating.again:
        return card.copyWith(
          stability: _shortTermStability(card.stability, rating),
          difficulty: _nextDifficulty(card.difficulty, rating),
          state: card.state == SrsState.learning
              ? SrsState.learning
              : SrsState.relearning,
          scheduledDays: 0,
          due: now.add(const Duration(minutes: 5)),
          reps: card.reps + 1,
          lapses: card.lapses + 1,
          lastReview: now,
          elapsedDays: elapsedDays,
        );
      case Rating.hard:
        return card.copyWith(
          stability: _shortTermStability(card.stability, rating),
          difficulty: _nextDifficulty(card.difficulty, rating),
          state: card.state,
          scheduledDays: 0,
          due: now.add(const Duration(minutes: 10)),
          reps: card.reps + 1,
          lastReview: now,
          elapsedDays: elapsedDays,
        );
      case Rating.good:
        final s = _shortTermStability(card.stability, rating);
        final interval = _nextInterval(s);
        return card.copyWith(
          stability: s,
          difficulty: _nextDifficulty(card.difficulty, rating),
          state: SrsState.review,
          scheduledDays: interval,
          due: now.add(Duration(days: interval)),
          reps: card.reps + 1,
          lastReview: now,
          elapsedDays: elapsedDays,
        );
      case Rating.easy:
        final s = _shortTermStability(card.stability, rating);
        final interval = max(
          _nextInterval(s),
          _nextInterval(_shortTermStability(card.stability, Rating.good)) + 1,
        );
        return card.copyWith(
          stability: s,
          difficulty: _nextDifficulty(card.difficulty, rating),
          state: SrsState.review,
          scheduledDays: interval,
          due: now.add(Duration(days: interval)),
          reps: card.reps + 1,
          lastReview: now,
          elapsedDays: elapsedDays,
        );
    }
  }

  // ── Review scheduling ──

  FsrsCard _scheduleReview(
      FsrsCard card, Rating rating, DateTime now, int elapsedDays) {
    final retrievability = _retrievability(card, elapsedDays);

    switch (rating) {
      case Rating.again:
        final s = _nextForgetStability(
            card.difficulty, card.stability, retrievability);
        return card.copyWith(
          stability: s,
          difficulty: _nextDifficulty(card.difficulty, rating),
          state: SrsState.relearning,
          scheduledDays: 0,
          due: now.add(const Duration(minutes: 5)),
          reps: card.reps + 1,
          lapses: card.lapses + 1,
          lastReview: now,
          elapsedDays: elapsedDays,
        );
      case Rating.hard:
        final s = _nextRecallStability(
            card.difficulty, card.stability, retrievability, rating);
        final interval = _nextInterval(s);
        return card.copyWith(
          stability: s,
          difficulty: _nextDifficulty(card.difficulty, rating),
          state: SrsState.review,
          scheduledDays: interval,
          due: now.add(Duration(days: interval)),
          reps: card.reps + 1,
          lastReview: now,
          elapsedDays: elapsedDays,
        );
      case Rating.good:
        final s = _nextRecallStability(
            card.difficulty, card.stability, retrievability, rating);
        final interval = _nextInterval(s);
        return card.copyWith(
          stability: s,
          difficulty: _nextDifficulty(card.difficulty, rating),
          state: SrsState.review,
          scheduledDays: interval,
          due: now.add(Duration(days: interval)),
          reps: card.reps + 1,
          lastReview: now,
          elapsedDays: elapsedDays,
        );
      case Rating.easy:
        final s = _nextRecallStability(
            card.difficulty, card.stability, retrievability, rating);
        final goodS = _nextRecallStability(
            card.difficulty, card.stability, retrievability, Rating.good);
        final interval = max(_nextInterval(s), _nextInterval(goodS) + 1);
        return card.copyWith(
          stability: s,
          difficulty: _nextDifficulty(card.difficulty, rating),
          state: SrsState.review,
          scheduledDays: interval,
          due: now.add(Duration(days: interval)),
          reps: card.reps + 1,
          lastReview: now,
          elapsedDays: elapsedDays,
        );
    }
  }

  // ── Core formulas ──

  double _initStability(Rating r) => w[r.value - 1].clamp(0.1, 36500);

  double _initDifficulty(Rating r) {
    return (w[4] - exp(w[5] * (r.value - 1)) + 1).clamp(1.0, 10.0);
  }

  double _nextDifficulty(double d, Rating r) {
    final delta = d - w[6] * (r.value - 3);
    // Mean reversion toward initial difficulty
    final next = w[9] * _initDifficulty(Rating.easy) + (1 - w[9]) * delta;
    return next.clamp(1.0, 10.0);
  }

  double _retrievability(FsrsCard card, int elapsedDays) {
    if (card.stability <= 0) return 0;
    return pow(1 + elapsedDays / (9 * card.stability), -1).toDouble();
  }

  double _shortTermStability(double s, Rating r) {
    return s * exp(w[14] * (r.value - 3 + w[15]));
  }

  double _nextRecallStability(
      double d, double s, double r, Rating rating) {
    final hardPenalty = rating == Rating.hard ? w[16] : 1.0;
    final easyBonus = rating == Rating.easy ? w[17] : 1.0;
    return (s *
            (1 +
                exp(w[8]) *
                    (11 - d) *
                    pow(s, -w[9]) *
                    (exp((1 - r) * w[10]) - 1) *
                    hardPenalty *
                    easyBonus))
        .clamp(0.1, 36500);
  }

  double _nextForgetStability(double d, double s, double r) {
    return (w[11] *
            pow(d, -w[12]) *
            (pow(s + 1.0, w[13]) - 1) *
            exp((1 - r) * w[14]))
        .clamp(0.1, 36500);
  }

  int _nextInterval(double s) {
    final interval = (s / 9 * (pow(1 / requestRetention, 1) - 1)).round();
    return interval.clamp(1, maximumInterval);
  }

  static double exp(double x) => pow(e, x).toDouble();
}
