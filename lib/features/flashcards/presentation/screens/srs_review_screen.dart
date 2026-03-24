import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/confetti_overlay.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/rating_buttons.dart';
import '../widgets/review_summary.dart';
import '../widgets/session_progress_bar.dart';
import '../providers/flashcard_provider.dart';
import '../../data/fsrs.dart';
import '../../data/models/flashcard_model.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../../gamification/presentation/widgets/xp_popup.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../sharing/presentation/widgets/share_preview_sheet.dart';
import '../../../sharing/presentation/widgets/srs_review_share_card.dart';
import '../../../../core/constants/xp_config.dart';
import '../../../home/data/models/journey_node_model.dart';

/// Stores data needed to undo the last rating.
class _UndoSnapshot {
  final int cardIndex;
  final FlashcardModel originalCard;
  final Rating rating;

  const _UndoSnapshot({
    required this.cardIndex,
    required this.originalCard,
    required this.rating,
  });
}

/// SRS Review screen — reviews all due cards for a course using FSRS ratings.
///
/// Shows cards one by one, tap to reveal answer, then rate with 4 buttons.
/// Supports swipe gestures (right = Good, left = Again) and undo.
///
/// When [courseId] is null, reviews due cards across ALL courses (Quick Review).
/// When [reverseMode] is true, question and answer sides are swapped.
class SrsReviewScreen extends ConsumerStatefulWidget {
  final String? courseId;
  final bool reverseMode;

  const SrsReviewScreen({super.key, this.courseId, this.reverseMode = false});

  @override
  ConsumerState<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends ConsumerState<SrsReviewScreen> {
  final FSRS _fsrs = FSRS();

  int _currentIndex = 0;
  bool _isRevealed = false;
  bool _isCompleted = false;

  // Stats
  int _againCount = 0;
  int _hardCount = 0;
  int _goodCount = 0;
  int _easyCount = 0;
  int _sessionXp = 0;

  // ── UX-25: Best streak tracking ──
  int _currentStreak = 0;
  int _bestStreak = 0;

  // Mutable working list (cards get updated after each review)
  List<FlashcardModel>? _cards;
  bool _isSpeaking = false;

  // ── UX-03: Bookmarks ──
  Set<String> _bookmarkedIds = {};

  // ── UX-01: Multi-level Undo (max 5) ──
  static const _maxUndoStack = 5;
  final List<_UndoSnapshot> _undoStack = [];
  Timer? _undoTimer;
  bool _showUndo = false;

  // ── UX-16: Session timer ──
  final Stopwatch _sessionStopwatch = Stopwatch();

  // ── UX-12: Swipe state ──
  double _swipeDx = 0;
  static const _swipeThreshold = 100.0;

  // ── UX-20: Progressive haptic during swipe ──
  int _lastHapticProgress = 0;

  // ── UX-110: Per-deck font size cache ──
  Map<String, double> _deckFontSizes = {};

  // ── UX-105/106: Swipe accessibility announcement flag ──
  bool _swipeAnnounced = false;

  // ── #25: Per-card timing for "Hardest Card" insight ──
  final Stopwatch _cardStopwatch = Stopwatch();
  String? _hardestCardKeyword;
  Duration _hardestCardDuration = Duration.zero;

  // ── UX-32: Keyboard shortcuts ──
  final FocusNode _keyboardFocusNode = FocusNode();

  void _onTapCard() {
    if (_isCompleted) return;
    setState(() => _isRevealed = !_isRevealed);
    if (_isRevealed) {
      SoundService.playFlashcardFlip();
      // Auto-read answer if enabled
      if (TtsService.instance.isAutoRead && TtsService.instance.isEnabled && _cards != null && _currentIndex < _cards!.length) {
        final card = _cards![_currentIndex];
        final textToRead = widget.reverseMode
            ? '${card.questionBefore}${card.keyword}${card.questionAfter}'
            : card.answer;
        _speakText(textToRead);
      }
    } else {
      TtsService.instance.stop();
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _speakText(String text) async {
    if (TtsService.instance.isSpeaking) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await TtsService.instance.speak(text);
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  void _speakCurrentCard() {
    if (_cards == null || _currentIndex >= _cards!.length) return;
    final card = _cards![_currentIndex];
    final questionText = '${card.questionBefore}${card.keyword}${card.questionAfter}';
    final answerText = card.answer;
    final text = _isRevealed
        ? (widget.reverseMode ? questionText : answerText)
        : (widget.reverseMode ? answerText : questionText);
    _speakText(text);
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _sessionStopwatch.stop();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  // ── UX-110: Load per-deck font sizes from SharedPreferences ──
  Future<void> _loadDeckFontSizes(List<FlashcardModel> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final deckIds = cards.map((c) => c.deckId).toSet();
    final sizes = <String, double>{};
    for (final deckId in deckIds) {
      final size = prefs.getDouble('deck_font_size_$deckId');
      if (size != null) sizes[deckId] = size;
    }
    if (mounted && sizes.isNotEmpty) {
      setState(() => _deckFontSizes = sizes);
    }
  }

  // ── UX-32: Keyboard shortcut handler ──────────────────────────────
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_isCompleted || _cards == null || _cards!.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // Space = flip card (reveal / hide)
    if (key == LogicalKeyboardKey.space) {
      _onTapCard();
      return KeyEventResult.handled;
    }

    // Rating keys (1-4) only work when card is revealed
    if (_isRevealed) {
      if (key == LogicalKeyboardKey.digit1 ||
          key == LogicalKeyboardKey.numpad1) {
        _onRating(Rating.again, _cards!);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit2 ||
          key == LogicalKeyboardKey.numpad2) {
        _onRating(Rating.hard, _cards!);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit3 ||
          key == LogicalKeyboardKey.numpad3) {
        _onRating(Rating.good, _cards!);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit4 ||
          key == LogicalKeyboardKey.numpad4) {
        _onRating(Rating.easy, _cards!);
        return KeyEventResult.handled;
      }
    }

    // Z = undo last rating (multi-level)
    if (key == LogicalKeyboardKey.keyZ && (_showUndo || _undoStack.isNotEmpty)) {
      _undoLastRating();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ── UX-01: Undo ─────────────────────────────────────────────────────

  void _startUndoTimer() {
    _undoTimer?.cancel();
    _undoTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _showUndo = false;
          _undoStack.clear();
        });
      }
    });
  }

  void _undoLastRating() {
    if (_undoStack.isEmpty || _cards == null) return;

    final snapshot = _undoStack.removeLast();

    // Revert stats
    switch (snapshot.rating) {
      case Rating.again:
        _againCount--;
      case Rating.hard:
        _hardCount--;
      case Rating.good:
        _goodCount--;
      case Rating.easy:
        _easyCount--;
    }
    _sessionXp -= XpConfig.flashcardReview;

    // ── UX-25: Reset streak on undo (conservative — recalc would be complex) ──
    _currentStreak = 0;

    // Restore original card in working list
    _cards![snapshot.cardIndex] = snapshot.originalCard;

    // Re-persist original state (fire-and-forget)
    ref
        .read(flashcardRepositoryProvider)
        .updateCardAfterReview(
          snapshot.originalCard,
          ReviewLog(
            rating: Rating.good,
            state: SrsState.fromValue(snapshot.originalCard.srsState),
            scheduledDays: snapshot.originalCard.scheduledDays,
            elapsedDays: snapshot.originalCard.elapsedDays,
            reviewedAt: DateTime.now(),
          ),
        )
        .catchError((_) {});

    HapticFeedback.mediumImpact();

    final hasMoreUndos = _undoStack.isNotEmpty;
    setState(() {
      _currentIndex = snapshot.cardIndex;
      _isRevealed = false;
      _isCompleted = false;
      _showUndo = hasMoreUndos;
    });

    // Reset the 6s timer if there are still undos available
    if (hasMoreUndos) {
      _startUndoTimer();
    } else {
      _undoTimer?.cancel();
    }
  }

  // ── Rating ──────────────────────────────────────────────────────────

  void _onRating(Rating rating, List<FlashcardModel> cards) {
    if (cards.isEmpty || _currentIndex >= cards.length) return;

    // Start session timer on first rating
    if (!_sessionStopwatch.isRunning) _sessionStopwatch.start();

    final card = cards[_currentIndex];

    // ── #25: Track per-card timing for "Hardest Card" insight ──
    final cardElapsed = _cardStopwatch.elapsed;
    _cardStopwatch.reset();
    _cardStopwatch.start();
    if (cardElapsed > _hardestCardDuration) {
      _hardestCardDuration = cardElapsed;
      _hardestCardKeyword = card.keyword;
    }

    // Save undo snapshot BEFORE applying the rating (multi-level, max 5)
    _undoStack.add(_UndoSnapshot(
      cardIndex: _currentIndex,
      originalCard: card,
      rating: rating,
    ));
    if (_undoStack.length > _maxUndoStack) {
      _undoStack.removeAt(0);
    }

    final fsrsCard = card.toFsrsCard();
    final result = _fsrs.repeat(fsrsCard, rating);

    // Update card in working list
    final updatedCard = card.applyFsrsResult(result.card);

    // Play sound + haptic feedback
    if (rating == Rating.again) {
      SoundService.playWrongAnswer();
      HapticFeedback.heavyImpact();
    } else if (rating == Rating.easy) {
      SoundService.playCorrectAnswer();
      HapticFeedback.mediumImpact();
    } else {
      SoundService.playCorrectAnswer();
      HapticFeedback.lightImpact();
    }

    // Persist update in background with retry on failure
    _persistReviewWithRetry(ref, updatedCard, result.log);

    // Award XP per card review (fire-and-forget)
    _sessionXp += XpConfig.flashcardReview;
    ref
        .read(xpRepositoryProvider)
        .awardXp(
          action: 'flashcard_review',
          amount: XpConfig.flashcardReview,
          metadata: {'card_id': updatedCard.id, 'rating': rating.value},
        )
        .then((_) => ref.invalidate(xpTotalProvider))
        .catchError((_) {/* silent */});

    // Update stats
    switch (rating) {
      case Rating.again:
        _againCount++;
      case Rating.hard:
        _hardCount++;
      case Rating.good:
        _goodCount++;
      case Rating.easy:
        _easyCount++;
    }

    // ── UX-25: Track best streak of Good/Easy ratings ──
    if (rating == Rating.good || rating == Rating.easy) {
      _currentStreak++;
      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
      }
    } else {
      _currentStreak = 0;
    }

    // ── UX-27: Mini sparkle on card mastery (Easy + high stability) ──
    if (rating == Rating.easy && result.card.stability > 21) {
      _showMasterySparkle();
    }

    // Stop TTS on card change
    TtsService.instance.stop();

    final nextIndex = _currentIndex + 1;

    if (nextIndex >= cards.length) {
      // Session complete
      _sessionStopwatch.stop();
      _cardStopwatch.stop(); // #25: Stop card timer
      _undoStack.clear();
      setState(() {
        _isCompleted = true;
        _isRevealed = false;
        _isSpeaking = false;
        _showUndo = false;
      });
      ConfettiOverlay.show(context);
      if (_sessionXp > 0) {
        XpPopup.show(context, xp: _sessionXp, label: 'Review Complete');
      }
      _recalculateCourseProgress();
    } else {
      setState(() {
        _currentIndex = nextIndex;
        _isRevealed = false;
        _isSpeaking = false;
        _showUndo = true;
      });
      _startUndoTimer();
    }
  }

  Future<void> _showSrsShareSheet() async {
    final profile = ref.read(profileProvider).valueOrNull;
    final xpTotal = ref.read(xpTotalProvider).valueOrNull ?? 0;
    final total = _againCount + _hardCount + _goodCount + _easyCount;

    // Get course name
    String courseName = 'Quick Review';
    if (widget.courseId != null) {
      try {
        final course = await Supabase.instance.client
            .from('courses')
            .select('title')
            .eq('id', widget.courseId!)
            .maybeSingle();
        courseName = course?['title'] as String? ?? 'My Course';
      } catch (e) {
        debugPrint('SRSReview: fetch course name for share failed: $e');
      }
    }

    if (!mounted) return;

    SharePreviewSheet.show(
      context,
      shareCard: SrsReviewShareCard(
        totalReviewed: total,
        againCount: _againCount,
        hardCount: _hardCount,
        goodCount: _goodCount,
        easyCount: _easyCount,
        xpEarned: _sessionXp,
        courseName: courseName,
        userName: profile?.fullName ?? 'Student',
        xpLevel: XpConfig.levelFromXp(xpTotal),
        dueRemaining: 0, // All due cards were reviewed
      ),
      shareType: 'srs_review',
    );
  }

  /// Persist a card review with up to 3 retries on network failure.
  void _persistReviewWithRetry(WidgetRef ref, FlashcardModel card, ReviewLog log, [int attempt = 1]) {
    ref
        .read(flashcardRepositoryProvider)
        .updateCardAfterReview(card, log)
        .catchError((Object e) {
      if (attempt < 3) {
        final delay = Duration(seconds: 2 * attempt);
        debugPrint('SRSReview: review save retry $attempt/3 after ${delay.inSeconds}s: $e');
        Future.delayed(delay, () {
          if (mounted) _persistReviewWithRetry(ref, card, log, attempt + 1);
        });
      } else {
        debugPrint('SRSReview: review save failed after 3 attempts: $e');
      }
    });
  }

  // ── UX-27: Mini sparkle overlay on card mastery ──
  void _showMasterySparkle() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _MasterySparkleOverlay(
        onComplete: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  Future<void> _recalculateCourseProgress() async {
    if (widget.courseId == null) return; // Quick review — skip per-course recalc
    try {
      await ref
          .read(courseRepositoryProvider)
          .recalculateProgress(widget.courseId!);
      ref.invalidate(coursesProvider);
    } catch (e) {
      // Best-effort
      debugPrint('SrsReviewScreen: recalculateCourseProgress failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueCardsAsync = widget.courseId != null
        ? ref.watch(dueCardsProvider(widget.courseId!))
        : ref.watch(allDueCardsProvider);

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.immersiveBg,
        body: dueCardsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.white38),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Could not load due cards',
                    style: AppTypography.h3.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppErrorHandler.friendlyMessage(e),
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(JourneyResult.cancelled),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
          data: (cards) {
            if (cards.isEmpty) {
              return _buildEmptyState();
            }
            // Initialize working list once
            if (_cards == null) {
              _cards = List.from(cards);
              _bookmarkedIds = cards
                  .where((c) => c.isBookmarked)
                  .map((c) => c.id)
                  .toSet();
              _loadDeckFontSizes(cards);
              // #25: Start card timer for first card
              _cardStopwatch.start();
            }
            return _isCompleted
                ? _buildSummary()
                : _buildReviewSession(_cards!);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 64, color: AppColors.success.withValues(alpha: 0.6)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'All caught up!',
                style: AppTypography.h2.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No cards due for review right now.\nCheck back later!',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white60,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextButton(
                onPressed: () => Navigator.of(context).pop(JourneyResult.cancelled),
                child: Text(
                  'Go Back',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final total = _againCount + _hardCount + _goodCount + _easyCount;

    // ── UX-25: Compute cards per minute ──
    double? cpm;
    final elapsed = _sessionStopwatch.elapsed;
    if (elapsed.inSeconds > 0 && total > 0) {
      cpm = total / (elapsed.inSeconds / 60.0);
    }

    return SafeArea(
      child: ReviewSummary(
        totalReviewed: total,
        againCount: _againCount,
        hardCount: _hardCount,
        goodCount: _goodCount,
        easyCount: _easyCount,
        xpEarned: _sessionXp,
        sessionDuration: elapsed,
        bestStreak: _bestStreak > 1 ? _bestStreak : null,
        cardsPerMinute: cpm,
        hardestCardKeyword: _hardestCardKeyword,
        onDone: () => Navigator.of(context).pop(JourneyResult.completed),
        onShare: _showSrsShareSheet,
      ),
    );
  }

  // ── UX-16: Format session time ───────────────────────────────────────

  String get _sessionTimeFormatted {
    final elapsed = _sessionStopwatch.elapsed;
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildReviewSession(List<FlashcardModel> cards) {
    final totalCards = cards.length;
    final displayIndex = _currentIndex + 1;
    final currentCard = cards[_currentIndex];

    // Build related cards list (same topic, excluding current)
    final relatedCards = cards
        .where((c) =>
            c.id != currentCard.id &&
            c.topic.toLowerCase() == currentCard.topic.toLowerCase())
        .map((c) => RelatedCardInfo(
              keyword: c.keyword,
              questionPreview:
                  '${c.questionBefore}${c.keyword}${c.questionAfter}',
            ))
        .toList();

    // Get interval previews for rating buttons
    final intervals = _fsrs.previewIntervals(currentCard.toFsrsCard());

    // UX-21: Dynamic swipe gradient feedback
    final swipeProgress = (_swipeDx.abs() / _swipeThreshold).clamp(0.0, 1.0);
    final swipeOpacity = swipeProgress * 0.3;
    final isSwipingRight = _swipeDx > 0;
    final showSwipeGradient = swipeProgress > 0.05;

    final swipeLabel = _swipeDx > _swipeThreshold * 0.7
        ? 'Good'
        : _swipeDx < -_swipeThreshold * 0.7
            ? 'Again'
            : null;

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              // Header: progress bar + session stats
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  0,
                ),
                child: Column(
                  children: [
                    // ── UX-18: Focus mode indicator ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Focus Mode',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ── UX-23: Reverse mode indicator badge ──
                        if (widget.reverseMode) ...[
                          const SizedBox(width: 6),
                          Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('\u{1F504}', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                Text(
                                  'Reverse',
                                  style: AppTypography.caption.copyWith(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    SessionProgressBar(
                      current: displayIndex,
                      total: totalCards,
                      courseLabel: 'Review',
                      onClose: () => Navigator.of(context).pop(JourneyResult.cancelled),
                    ),

                    // ── UX-16: Live session stats ──
                    if (_againCount + _hardCount + _goodCount + _easyCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Timer
                            Icon(Icons.timer_outlined, size: 12, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text(
                              _sessionTimeFormatted,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white38,
                                fontSize: 11,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Mini rating distribution dots
                            _MiniDot(color: const Color(0xFFEF4444), count: _againCount),
                            const SizedBox(width: 6),
                            _MiniDot(color: const Color(0xFFF97316), count: _hardCount),
                            const SizedBox(width: 6),
                            _MiniDot(color: const Color(0xFF22C55E), count: _goodCount),
                            const SizedBox(width: 6),
                            _MiniDot(color: const Color(0xFF3B82F6), count: _easyCount),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Card area with swipe gestures (UX-12)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: GestureDetector(
                    onTap: _onTapCard,
                    onHorizontalDragUpdate: _isRevealed
                        ? (details) {
                            setState(() => _swipeDx += details.delta.dx);
                            // UX-20: Progressive haptic feedback
                            final progress = (_swipeDx.abs() / _swipeThreshold).clamp(0.0, 1.0);
                            final progressPercent = (progress * 100).toInt();
                            if (progressPercent >= 75 && _lastHapticProgress < 75) {
                              HapticFeedback.heavyImpact();
                              _lastHapticProgress = 75;
                            } else if (progressPercent >= 50 && _lastHapticProgress < 50) {
                              HapticFeedback.mediumImpact();
                              _lastHapticProgress = 50;
                            } else if (progressPercent >= 25 && _lastHapticProgress < 25) {
                              HapticFeedback.lightImpact();
                              _lastHapticProgress = 25;
                            }
                            // UX-106: Semantic announcement at 50% swipe threshold
                            if (!_swipeAnnounced && progressPercent >= 50) {
                              _swipeAnnounced = true;
                              final direction = _swipeDx > 0
                                  ? 'Good'
                                  : 'Again';
                              SemanticsService.sendAnnouncement(
                                View.of(context),
                                '$direction \u2014 Release to confirm',
                                TextDirection.ltr,
                              );
                            }
                          }
                        : null,
                    onHorizontalDragEnd: _isRevealed
                        ? (details) {
                            if (_swipeDx > _swipeThreshold) {
                              _onRating(Rating.good, cards);
                            } else if (_swipeDx < -_swipeThreshold) {
                              _onRating(Rating.again, cards);
                            }
                            setState(() => _swipeDx = 0);
                            _lastHapticProgress = 0;
                            _swipeAnnounced = false;
                          }
                        : null,
                    onHorizontalDragCancel: () {
                      setState(() => _swipeDx = 0);
                      _lastHapticProgress = 0;
                      _swipeAnnounced = false;
                    },
                    child: Stack(
                      children: [
                        // UX-21: Dynamic swipe gradient overlay
                        if (showSwipeGradient)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: isSwipingRight
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  end: isSwipingRight
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  colors: [
                                    (isSwipingRight
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFFEF4444))
                                        .withValues(alpha: swipeOpacity),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                        // Swipe label
                        if (swipeLabel != null)
                          Positioned(
                            top: 24,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _swipeDx > 0
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  swipeLabel,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Transform.translate(
                          offset: Offset(_swipeDx * 0.3, 0),
                          child: FlashcardWidget(
                            key: ValueKey('card_${currentCard.id}${widget.reverseMode ? '_rev' : ''}'),
                            topic: currentCard.topic,
                            // UX-23: In reverse mode, swap question and answer sides
                            questionBefore: widget.reverseMode ? '' : currentCard.questionBefore,
                            keyword: widget.reverseMode ? currentCard.answer : currentCard.keyword,
                            questionAfter: widget.reverseMode ? '' : currentCard.questionAfter,
                            answer: widget.reverseMode
                                ? '${currentCard.questionBefore}${currentCard.keyword}${currentCard.questionAfter}'
                                : currentCard.answer,
                            isRevealed: _isRevealed,
                            isBookmarked: _bookmarkedIds.contains(currentCard.id),
                            isSpeaking: _isSpeaking,
                            fontSize: _deckFontSizes[currentCard.deckId],
                            relatedCards: relatedCards,
                            onTap: _onTapCard,
                            onSpeak: TtsService.instance.isEnabled
                                ? _speakCurrentCard
                                : null,
                            onBookmark: () {
                              final card = cards[_currentIndex];
                              final wasBookmarked = _bookmarkedIds.contains(card.id);
                              setState(() {
                                if (wasBookmarked) {
                                  _bookmarkedIds.remove(card.id);
                                } else {
                                  _bookmarkedIds.add(card.id);
                                }
                              });
                              HapticFeedback.lightImpact();
                              // Show brief feedback
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(wasBookmarked ? 'Bookmark removed' : 'Bookmarked ✓'),
                                  duration: const Duration(milliseconds: 1200),
                                  backgroundColor: AppColors.immersiveCard,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.only(
                                    bottom: 80,
                                    left: AppSpacing.xl,
                                    right: AppSpacing.xl,
                                  ),
                                ),
                              );
                              // Persist in background
                              ref
                                  .read(flashcardRepositoryProvider)
                                  .toggleBookmark(card.id, !wasBookmarked)
                                  .catchError((_) {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Rating buttons (only shown after reveal)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: AnimatedOpacity(
                  opacity: _isRevealed ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 250),
                  child: RatingButtons(
                    intervals: intervals,
                    onRating: (r) => _onRating(r, cards),
                    enabled: _isRevealed,
                  ),
                ),
              ),

              // Hint text when not revealed
              if (!_isRevealed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Text(
                    'Tap card to reveal \u00b7 Swipe to rate \u00b7 Space to flip',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          // ── UX-01: Multi-level Undo floating button ──
          if (_showUndo && _undoStack.isNotEmpty)
            Positioned(
              bottom: 140,
              right: AppSpacing.xl,
              child: AnimatedOpacity(
                opacity: _showUndo ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _undoLastRating,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.immersiveCard,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.immersiveBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.undo_rounded,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Undo',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_undoStack.length > 1) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${_undoStack.length}',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mini colored dot with count for session stats.
class _MiniDot extends StatelessWidget {
  final Color color;
  final int count;

  const _MiniDot({required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: AppTypography.caption.copyWith(
            color: Colors.white38,
            fontSize: 11,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ── UX-27: Mini golden sparkle overlay for card mastery ──────────────

/// Brief golden sparkle animation (3-5 stars that scale up and fade out).
/// Shown when a card is rated Easy with stability > 21 days.
class _MasterySparkleOverlay extends StatefulWidget {
  final VoidCallback? onComplete;

  const _MasterySparkleOverlay({this.onComplete});

  @override
  State<_MasterySparkleOverlay> createState() => _MasterySparkleOverlayState();
}

class _MasterySparkleOverlayState extends State<_MasterySparkleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Pre-computed star positions (relative to center, staggered)
  static const _stars = [
    _StarData(dx: -0.12, dy: -0.08, delay: 0.0, size: 28),
    _StarData(dx: 0.10, dy: -0.12, delay: 0.1, size: 22),
    _StarData(dx: 0.0, dy: 0.06, delay: 0.15, size: 32),
    _StarData(dx: -0.08, dy: 0.10, delay: 0.05, size: 20),
    _StarData(dx: 0.14, dy: 0.04, delay: 0.2, size: 24),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height * 0.4; // Roughly where the card is

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: _stars.map((star) {
              // Each star has a staggered start
              final adjustedProgress =
                  ((_controller.value - star.delay) / (1.0 - star.delay))
                      .clamp(0.0, 1.0);

              if (adjustedProgress <= 0) return const SizedBox.shrink();

              // Scale: 0 -> 1 in first 50%, then hold
              final scale = adjustedProgress < 0.5
                  ? (adjustedProgress / 0.5)
                  : 1.0;

              // Fade: full opacity until 40%, then fade out
              final opacity = adjustedProgress > 0.4
                  ? (1.0 - (adjustedProgress - 0.4) / 0.6).clamp(0.0, 1.0)
                  : 1.0;

              // Drift outward slightly
              final drift = adjustedProgress * 12;

              return Positioned(
                left: centerX + star.dx * size.width + (star.dx.sign * drift),
                top: centerY + star.dy * size.height + (star.dy.sign * drift),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Icon(
                      Icons.star_rounded,
                      size: star.size,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _StarData {
  final double dx;
  final double dy;
  final double delay;
  final double size;

  const _StarData({
    required this.dx,
    required this.dy,
    required this.delay,
    required this.size,
  });
}
