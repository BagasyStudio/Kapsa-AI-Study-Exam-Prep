import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/confetti_overlay.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../widgets/session_progress_bar.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/card_stack.dart';
import '../widgets/swipe_indicator.dart';
import '../widgets/floating_toolbar.dart';
import '../widgets/share_deck_dialog.dart';
import '../providers/flashcard_provider.dart';
import '../../data/fsrs.dart';
import '../../data/models/flashcard_model.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../../sharing/presentation/widgets/share_preview_sheet.dart';
import '../../../sharing/presentation/widgets/flashcard_share_card.dart';
import '../../../sharing/data/milestone_service.dart';
import '../../../sharing/presentation/widgets/micro_cards/course_mastery_card.dart';
import '../../../../core/services/review_service.dart';

class FlashcardSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const FlashcardSessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<FlashcardSessionScreen> createState() =>
      _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState
    extends ConsumerState<FlashcardSessionScreen> {
  final FSRS _fsrs = FSRS();

  int _currentIndex = 0;
  bool _isRevealed = false;
  bool _hasCompletedOnce = false;
  bool _showCompleted = false;
  double _swipeProgress = 0; // -1 (left) to 1 (right)

  int _masteredCount = 0;
  int _againCount = 0;
  String _courseName = 'Flashcards';

  @override
  void initState() {
    super.initState();
    _loadCourseName();
  }

  Future<void> _loadCourseName() async {
    try {
      final courseId = await ref
          .read(flashcardRepositoryProvider)
          .getCourseIdForDeck(widget.sessionId);
      if (courseId != null && mounted) {
        final course = await ref
            .read(courseRepositoryProvider)
            .getCourse(courseId);
        if (course != null && mounted) {
          setState(() => _courseName = course.title);
        }
      }
    } catch (_) {
      // Best-effort — keep default 'Flashcards'
    }
  }

  void _onTapCard() {
    setState(() => _isRevealed = !_isRevealed);
    if (_isRevealed) SoundService.playFlashcardFlip();
  }

  void _onSwiped(SwipeDirection direction, List<FlashcardModel> cards) {
    if (cards.isEmpty) return;

    final card = cards[_currentIndex % cards.length];

    // Map swipe to FSRS rating: left = Again, right = Good
    final rating =
        direction == SwipeDirection.right ? Rating.good : Rating.again;
    final fsrsCard = card.toFsrsCard();
    final result = _fsrs.repeat(fsrsCard, rating);
    final updatedCard = card.applyFsrsResult(result.card);

    // Track mastered vs again
    if (direction == SwipeDirection.right) {
      _masteredCount++;
      SoundService.playCorrectAnswer();
    } else {
      _againCount++;
      SoundService.playWrongAnswer();
    }

    // Persist SRS update in background (catch errors silently — non-critical)
    ref
        .read(flashcardRepositoryProvider)
        .updateCardAfterReview(updatedCard, result.log)
        .catchError((_) {/* silent — mastery sync is best-effort */});

    final nextIndex = _currentIndex + 1;

    setState(() {
      _currentIndex = nextIndex;
      _isRevealed = false;
      _swipeProgress = 0;
    });

    // Trigger confetti, show completion overlay, and recalculate progress
    if (nextIndex == cards.length && !_hasCompletedOnce) {
      _hasCompletedOnce = true;
      setState(() => _showCompleted = true);
      ConfettiOverlay.show(context);
      _recalculateCourseProgress();
      ReviewService.recordPositiveEvent();
    }
  }

  Future<void> _recalculateCourseProgress() async {
    try {
      final courseId = await ref
          .read(flashcardRepositoryProvider)
          .getCourseIdForDeck(widget.sessionId);
      if (courseId != null) {
        await ref
            .read(courseRepositoryProvider)
            .recalculateProgress(courseId);
        ref.invalidate(coursesProvider);

        // Check if course reached 100% mastery
        _checkCourseMastery(courseId);
      }
    } catch (_) {
      // Best-effort — don't interrupt the user's session
    }
  }

  Future<void> _checkCourseMastery(String courseId) async {
    try {
      final course =
          await ref.read(courseRepositoryProvider).getCourse(courseId);
      if (course == null || course.progress < 1.0) return;

      // Check if already shown
      final milestone =
          await MilestoneService.checkMilestone('course_mastery', courseId);
      if (milestone == null || !mounted) return;

      await MilestoneService.markShown('course_mastery', courseId);

      final profile = ref.read(profileProvider).whenOrNull(data: (p) => p);
      final xpLevel = ref.read(xpLevelProvider);

      // Count total cards across all decks for this course
      final decks =
          await ref.read(flashcardRepositoryProvider).getDecks(courseId);
      final totalCards =
          decks.fold<int>(0, (sum, d) => sum + d.cardCount);

      if (!mounted) return;
      SharePreviewSheet.show(
        context,
        shareCard: CourseMasteryCard(
          courseName: course.title,
          totalCards: totalCards,
          quizzesTaken: 0, // simplified
          daysToMaster: DateTime.now()
              .difference(course.createdAt ?? DateTime.now())
              .inDays,
          userName: profile?.firstName ?? 'Student',
          xpLevel: xpLevel,
        ),
        shareType: 'course_mastery',
        referenceId: courseId,
      );
    } catch (_) {}
  }

  void _onSwipeProgress(double progress) {
    setState(() => _swipeProgress = progress);
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(flashcardsProvider(widget.sessionId));
    final brightness = Theme.of(context).brightness;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmExit();
        if (shouldLeave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      body: cardsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppColors.textMutedFor(brightness)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Could not load flashcards',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppErrorHandler.friendlyMessage(e),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMutedFor(brightness),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.style,
                          size: 48,
                          color: AppColors.textMutedFor(brightness)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No flashcards yet',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.textPrimaryFor(brightness),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Generate flashcards from your course materials first.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMutedFor(brightness),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return _buildCardSession(cards);
        },
      ),
    ),
    );
  }

  Future<bool> _confirmExit() async {
    if (_showCompleted) return true; // Session already done
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave session?'),
        content: const Text('Your progress in this session will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildCardSession(List<FlashcardModel> cards) {
    final totalCards = cards.length;
    final displayIndex =
        (_currentIndex % totalCards) + 1;
    final currentCard = cards[_currentIndex % totalCards];

    return Stack(
      children: [
        // Ambient glows
        // Left red glow (appears when swiping left)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: (_swipeProgress < 0 ? -_swipeProgress : 0) * 0.6,
              duration: Duration.zero,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.centerLeft,
                    radius: 0.7,
                    colors: [
                      const Color(0xFFEF4444).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Right green glow (appears when swiping right)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: (_swipeProgress > 0 ? _swipeProgress : 0) * 0.6,
              duration: Duration.zero,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.centerRight,
                    radius: 0.7,
                    colors: [
                      const Color(0xFF22C55E).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Decorative top blob
        Positioned(
          top: -130,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),

        // Main content
        SafeArea(
          child: Column(
            children: [
              // Header: progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  0,
                ),
                child: SessionProgressBar(
                  current: displayIndex,
                  total: totalCards,
                  courseLabel: 'Flashcards',
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),

              // Card area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    80, // space for toolbar
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Card stack with swipe
                      CardStack(
                        onTap: _onTapCard,
                        onSwiped: (dir) => _onSwiped(dir, cards),
                        onSwipeProgress: _onSwipeProgress,
                        frontCard: FlashcardWidget(
                          key: ValueKey('card_${currentCard.id}'),
                          topic: currentCard.topic,
                          questionBefore: currentCard.questionBefore,
                          keyword: currentCard.keyword,
                          questionAfter: currentCard.questionAfter,
                          answer: currentCard.answer,
                          isRevealed: _isRevealed,
                          onTap: _onTapCard,
                          onBookmark: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Card bookmarked')),
                            );
                          },
                        ),
                      ),

                      // Left swipe indicator (Study Again)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: SwipeIndicator(
                          isRight: false,
                          opacity: _swipeProgress < 0
                              ? (-_swipeProgress * 2).clamp(0.0, 1.0)
                              : 0.4,
                        ),
                      ),

                      // Right swipe indicator (Mastered)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: SwipeIndicator(
                          isRight: true,
                          opacity: _swipeProgress > 0
                              ? (_swipeProgress * 2).clamp(0.0, 1.0)
                              : 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Floating toolbar
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingToolbar(
              onRefresh: () {
                setState(() {
                  _currentIndex = 0;
                  _isRevealed = false;
                  _swipeProgress = 0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cards reshuffled')),
                );
              },
              onEdit: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit cards coming soon')),
                );
              },
              onShare: () async {
                try {
                  final code = await ref
                      .read(flashcardRepositoryProvider)
                      .shareDeck(widget.sessionId);
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => ShareDeckDialog(shareCode: code),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppErrorHandler.friendlyMessage(e)),
                    ),
                  );
                }
              },
            ),
          ),
        ),

        // Completion overlay
        if (_showCompleted)
          Positioned.fill(
            child: _buildCompletionOverlay(cards),
          ),
      ],
    );
  }

  Widget _buildCompletionOverlay(List<FlashcardModel> cards) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final profile = ref.watch(profileProvider).whenOrNull(data: (p) => p);
    final xpLevel = ref.watch(xpLevelProvider);
    final userName = profile?.firstName ?? 'Student';
    final streakDays = profile?.streakDays ?? 0;
    final totalCards = cards.length;
    final masteryRate = totalCards > 0
        ? (_masteredCount / totalCards * 100)
        : 0.0;

    return GestureDetector(
      onTap: () {}, // absorb taps
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1B2E).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      '\u{1f389} Session Complete!',
                      style: AppTypography.h2.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalCards cards reviewed',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMutedFor(brightness),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CompletionStat(
                          icon: Icons.check_circle,
                          value: '$_masteredCount',
                          label: 'Mastered',
                          color: const Color(0xFF10B981),
                          brightness: brightness,
                        ),
                        const SizedBox(width: 32),
                        _CompletionStat(
                          icon: Icons.refresh,
                          value: '$_againCount',
                          label: 'Again',
                          color: const Color(0xFFF97316),
                          brightness: brightness,
                        ),
                        const SizedBox(width: 32),
                        _CompletionStat(
                          icon: Icons.percent,
                          value: '${masteryRate.round()}%',
                          label: 'Mastery',
                          color: AppColors.primary,
                          brightness: brightness,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Share Results button
                    TapScale(
                      onTap: () {
                        SharePreviewSheet.show(
                          context,
                          shareCard: FlashcardShareCard(
                            cardsReviewed: totalCards,
                            masteredCount: _masteredCount,
                            studyAgainCount: _againCount,
                            courseName: _courseName,
                            userName: userName,
                            xpLevel: xpLevel,
                            streakDays: streakDays,
                          ),
                          shareType: 'flashcard_review',
                          referenceId: widget.sessionId,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6467F2)
                                  .withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.ios_share,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Share Results',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Continue Reviewing button
                    TapScale(
                      onTap: () => setState(() => _showCompleted = false),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Continue Reviewing',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.textPrimaryFor(brightness),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Done button
                    TapScale(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Done',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.textMutedFor(brightness),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Brightness brightness;

  const _CompletionStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.h3.copyWith(
            color: AppColors.textPrimaryFor(brightness),
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMutedFor(brightness),
          ),
        ),
      ],
    );
  }
}
