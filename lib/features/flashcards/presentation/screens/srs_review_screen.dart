import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/sound_service.dart';
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

/// SRS Review screen — reviews all due cards for a course using FSRS ratings.
///
/// Shows cards one by one, tap to reveal answer, then rate with 4 buttons.
class SrsReviewScreen extends ConsumerStatefulWidget {
  final String courseId;

  const SrsReviewScreen({super.key, required this.courseId});

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

  // Mutable working list (cards get updated after each review)
  List<FlashcardModel>? _cards;

  void _onTapCard() {
    if (_isCompleted) return;
    setState(() => _isRevealed = !_isRevealed);
    if (_isRevealed) SoundService.playFlashcardFlip();
  }

  void _onRating(Rating rating, List<FlashcardModel> cards) {
    if (cards.isEmpty || _currentIndex >= cards.length) return;

    final card = cards[_currentIndex];
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

    // Persist update in background (fire-and-forget)
    ref
        .read(flashcardRepositoryProvider)
        .updateCardAfterReview(updatedCard, result.log)
        .catchError((_) {/* silent — best-effort */});

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

    final nextIndex = _currentIndex + 1;

    if (nextIndex >= cards.length) {
      // Session complete
      setState(() {
        _isCompleted = true;
        _isRevealed = false;
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
      });
    }
  }

  Future<void> _showSrsShareSheet() async {
    final profile = ref.read(profileProvider).valueOrNull;
    final xpTotal = ref.read(xpTotalProvider).valueOrNull ?? 0;
    final total = _againCount + _hardCount + _goodCount + _easyCount;

    // Get course name
    String courseName = 'My Course';
    try {
      final course = await Supabase.instance.client
          .from('courses')
          .select('title')
          .eq('id', widget.courseId)
          .maybeSingle();
      courseName = course?['title'] as String? ?? 'My Course';
    } catch (_) {}

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

  Future<void> _recalculateCourseProgress() async {
    try {
      await ref
          .read(courseRepositoryProvider)
          .recalculateProgress(widget.courseId);
      ref.invalidate(coursesProvider);
    } catch (_) {
      // Best-effort
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueCardsAsync = ref.watch(dueCardsProvider(widget.courseId));
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
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
                Icon(Icons.error_outline,
                    size: 48, color: AppColors.textMutedFor(brightness)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Could not load due cards',
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
            return _buildEmptyState();
          }
          // Initialize working list once
          _cards ??= List.from(cards);
          return _isCompleted
              ? _buildSummary()
              : _buildReviewSession(_cards!);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final brightness = Theme.of(context).brightness;
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
                  color: AppColors.textPrimaryFor(brightness),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No cards due for review right now.\nCheck back later!',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMutedFor(brightness),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
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
    return SafeArea(
      child: ReviewSummary(
        totalReviewed: total,
        againCount: _againCount,
        hardCount: _hardCount,
        goodCount: _goodCount,
        easyCount: _easyCount,
        xpEarned: _sessionXp,
        onDone: () => Navigator.of(context).pop(),
        onShare: _showSrsShareSheet,
      ),
    );
  }

  Widget _buildReviewSession(List<FlashcardModel> cards) {
    final totalCards = cards.length;
    final displayIndex = _currentIndex + 1;
    final currentCard = cards[_currentIndex];

    // Get interval previews for rating buttons
    final intervals = _fsrs.previewIntervals(currentCard.toFsrsCard());

    return SafeArea(
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
              courseLabel: 'Review',
              onClose: () => Navigator.of(context).pop(),
            ),
          ),

          // Card area
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
                child: FlashcardWidget(
                  topic: currentCard.topic,
                  questionBefore: currentCard.questionBefore,
                  keyword: currentCard.keyword,
                  questionAfter: currentCard.questionAfter,
                  answer: currentCard.answer,
                  isRevealed: _isRevealed,
                  onTap: _onTapCard,
                  onBookmark: () {},
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
              child: Builder(builder: (context) {
                final brightness = Theme.of(context).brightness;
                return Text(
                  'Tap card to reveal answer',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                    fontWeight: FontWeight.w500,
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
