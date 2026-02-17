import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/confetti_overlay.dart';
import '../widgets/session_progress_bar.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/card_stack.dart';
import '../widgets/swipe_indicator.dart';
import '../widgets/floating_toolbar.dart';
import '../providers/flashcard_provider.dart';
import '../../data/models/flashcard_model.dart';
import '../../../courses/presentation/providers/course_provider.dart';

class FlashcardSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const FlashcardSessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<FlashcardSessionScreen> createState() =>
      _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState
    extends ConsumerState<FlashcardSessionScreen> {
  int _currentIndex = 0;
  bool _isRevealed = false;
  bool _hasCompletedOnce = false;
  double _swipeProgress = 0; // -1 (left) to 1 (right)

  void _onTapCard() {
    setState(() => _isRevealed = !_isRevealed);
    if (_isRevealed) SoundService.playFlashcardFlip();
  }

  void _onSwiped(SwipeDirection direction, List<FlashcardModel> cards) {
    if (cards.isEmpty) return;

    final card = cards[_currentIndex % cards.length];
    final newMastery =
        direction == SwipeDirection.right ? 'mastered' : 'learning';

    // Play appropriate sound
    if (direction == SwipeDirection.right) {
      SoundService.playCorrectAnswer();
    } else {
      SoundService.playWrongAnswer();
    }

    // Update mastery in background (catch errors silently — non-critical)
    ref
        .read(flashcardRepositoryProvider)
        .updateMastery(card.id, newMastery)
        .catchError((_) {/* silent — mastery sync is best-effort */});

    final nextIndex = _currentIndex + 1;

    setState(() {
      _currentIndex = nextIndex;
      _isRevealed = false;
      _swipeProgress = 0;
    });

    // Trigger confetti and recalculate progress when deck is completed
    if (nextIndex == cards.length && !_hasCompletedOnce) {
      _hasCompletedOnce = true;
      ConfettiOverlay.show(context);
      _recalculateCourseProgress();
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
      }
    } catch (_) {
      // Best-effort — don't interrupt the user's session
    }
  }

  void _onSwipeProgress(double progress) {
    setState(() => _swipeProgress = progress);
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(flashcardsProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.darkImmersive),
        child: cardsAsync.when(
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
                      size: 48, color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Could not load flashcards',
                    style: AppTypography.h3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppErrorHandler.friendlyMessage(e),
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
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
                            color:
                                Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No flashcards yet',
                          style:
                              AppTypography.h3.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Generate flashcards from your course materials first.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
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
              onShare: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share deck coming soon')),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
