import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/sound_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/flashcard_model.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/session_progress_bar.dart';

/// Sort modes for cram session cards.
enum CramSortMode {
  random,
  hardestFirst,
  newestFirst,
  alphabetical,
}

/// Rapid-fire flashcard review without SRS scheduling.
///
/// Loads ALL cards from a deck, shows them one at a time with flip-to-reveal.
/// Cards marked "Need more practice" go back to the end of the queue.
/// Session ends when all cards are marked "Got it" or user manually exits.
class FlashcardCramScreen extends ConsumerStatefulWidget {
  final String deckId;

  const FlashcardCramScreen({super.key, required this.deckId});

  @override
  ConsumerState<FlashcardCramScreen> createState() =>
      _FlashcardCramScreenState();
}

class _FlashcardCramScreenState extends ConsumerState<FlashcardCramScreen>
    with TickerProviderStateMixin {
  // ── Card queue ──
  List<FlashcardModel>? _queue;
  int _currentIndex = 0;
  bool _isRevealed = false;
  bool _isCompleted = false;

  // ── Stats ──
  int _masteredCount = 0;
  int _totalCards = 0;

  // ── Sort ──
  CramSortMode _sortMode = CramSortMode.random;

  // ── Session timer ──
  final Stopwatch _sessionStopwatch = Stopwatch();
  Timer? _timerRefresh;

  // ── TTS ──
  bool _isSpeaking = false;

  // ── Card entrance animation ──
  late AnimationController _entranceController;
  late Animation<double> _entranceScale;
  late Animation<double> _entranceOpacity;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceScale = Tween<double>(begin: 0.95, end: 1.0).animate(curved);
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
  }

  @override
  void dispose() {
    _timerRefresh?.cancel();
    _sessionStopwatch.stop();
    _entranceController.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  // ── Timer ──

  void _startTimerIfNeeded() {
    if (!_sessionStopwatch.isRunning) {
      _sessionStopwatch.start();
      _timerRefresh = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  String get _sessionTimeFormatted {
    final elapsed = _sessionStopwatch.elapsed;
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Sorting ──

  void _applySortMode(List<FlashcardModel> cards) {
    switch (_sortMode) {
      case CramSortMode.random:
        cards.shuffle(Random());
      case CramSortMode.hardestFirst:
        cards.sort((a, b) => a.stability.compareTo(b.stability));
      case CramSortMode.newestFirst:
        cards.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(2000);
          final bDate = b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
      case CramSortMode.alphabetical:
        cards.sort(
            (a, b) => a.keyword.toLowerCase().compareTo(b.keyword.toLowerCase()));
    }
  }

  void _onSortChanged(CramSortMode mode) {
    if (_queue == null || mode == _sortMode) return;
    HapticFeedback.lightImpact();
    setState(() {
      _sortMode = mode;
      // Separate mastered (already removed from queue) from remaining
      // Just re-sort the remaining queue from current index onward
      final remaining = _queue!.sublist(_currentIndex);
      _applySortMode(remaining);
      _queue!.replaceRange(_currentIndex, _queue!.length, remaining);
      _isRevealed = false;
    });
    _playEntranceAnimation();
  }

  // ── Card actions ──

  void _onTapCard() {
    if (_isCompleted || _queue == null || _currentIndex >= _queue!.length) {
      return;
    }
    setState(() => _isRevealed = !_isRevealed);
    if (_isRevealed) {
      SoundService.playFlashcardFlip();
      if (TtsService.instance.isAutoRead &&
          TtsService.instance.isEnabled &&
          _currentIndex < _queue!.length) {
        _speakText(_queue![_currentIndex].answer);
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
    if (_queue == null || _currentIndex >= _queue!.length) return;
    final card = _queue![_currentIndex];
    final text = _isRevealed
        ? card.answer
        : '${card.questionBefore}${card.keyword}${card.questionAfter}';
    _speakText(text);
  }

  void _onGotIt() {
    if (_queue == null || _currentIndex >= _queue!.length) return;
    _startTimerIfNeeded();

    HapticFeedback.mediumImpact();
    SoundService.playCorrectAnswer();

    // Stop TTS
    TtsService.instance.stop();

    setState(() {
      _masteredCount++;
      _currentIndex++;
      _isRevealed = false;
      _isSpeaking = false;
    });

    if (_currentIndex >= _queue!.length) {
      // All cards mastered
      _sessionStopwatch.stop();
      _timerRefresh?.cancel();
      setState(() => _isCompleted = true);
    } else {
      _playEntranceAnimation();
    }
  }

  void _onNeedMorePractice() {
    if (_queue == null || _currentIndex >= _queue!.length) return;
    _startTimerIfNeeded();

    HapticFeedback.lightImpact();

    // Stop TTS
    TtsService.instance.stop();

    // Move current card to end of queue
    final card = _queue![_currentIndex];
    setState(() {
      _queue!.removeAt(_currentIndex);
      _queue!.add(card);
      _isRevealed = false;
      _isSpeaking = false;
    });

    _playEntranceAnimation();
  }

  void _playEntranceAnimation() {
    _entranceController.reset();
    _entranceController.forward();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(flashcardsProvider(widget.deckId));
    final deckAsync = ref.watch(deckProvider(widget.deckId));
    final deckName =
        deckAsync.whenOrNull(data: (d) => d?.displayTitle) ?? 'Deck';

    return PopScope(
      canPop: _isCompleted || _masteredCount == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmExit();
        if (shouldLeave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.immersiveBg,
        body: cardsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => _buildError(e),
          data: (cards) {
            if (cards.isEmpty) return _buildEmpty();

            // Initialize queue once
            if (_queue == null) {
              _queue = List.from(cards);
              _totalCards = cards.length;
              _applySortMode(_queue!);
              // Trigger entrance animation for first card
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _playEntranceAnimation();
              });
            }

            if (_isCompleted) return _buildSummary(deckName);

            return _buildCramSession(deckName);
          },
        ),
      ),
    );
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.immersiveCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Leave Cram Session?',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        content: Text(
          'You\'ve mastered $_masteredCount of $_totalCards cards. Your progress won\'t be saved.',
          style: AppTypography.bodySmall.copyWith(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Keep Going',
              style: AppTypography.labelLarge.copyWith(color: AppColors.ctaLime),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Leave',
              style: AppTypography.labelLarge.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildError(Object e) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.white38),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Could not load cards',
                style: AppTypography.h3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppErrorHandler.friendlyMessage(e),
                style: AppTypography.bodySmall.copyWith(color: Colors.white60),
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

  Widget _buildEmpty() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.style_outlined,
                  size: 64, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No cards in this deck',
                style: AppTypography.h3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add some flashcards first to start cramming.',
                style:
                    AppTypography.bodySmall.copyWith(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Go Back',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(String deckName) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ctaLime.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 40,
                color: AppColors.ctaLime,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Cram Complete!',
              style: AppTypography.h3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'You reviewed all $_totalCards cards in $deckName',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SummaryStat(
                  icon: Icons.check_circle_outline,
                  label: 'Cards',
                  value: '$_totalCards',
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xxl),
                _SummaryStat(
                  icon: Icons.timer_outlined,
                  label: 'Time',
                  value: _sessionTimeFormatted,
                  color: AppColors.ctaLime,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl * 2),

            // Done button
            TapScale(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.ctaLime,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ctaLime.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Done',
                  textAlign: TextAlign.center,
                  style: AppTypography.button.copyWith(
                    color: AppColors.ctaLimeText,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCramSession(String deckName) {
    final currentCard = _queue![_currentIndex];
    final remainingCount = _queue!.length - _currentIndex;

    // Build related cards list (same topic, excluding current)
    final relatedCards = _queue!
        .where((c) =>
            c.id != currentCard.id &&
            c.topic.toLowerCase() == currentCard.topic.toLowerCase())
        .map((c) => RelatedCardInfo(
              keyword: c.keyword,
              questionPreview:
                  '${c.questionBefore}${c.keyword}${c.questionAfter}',
            ))
        .toList();

    return SafeArea(
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              0,
            ),
            child: Column(
              children: [
                // Cram mode indicator
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.ctaLime.withValues(alpha: 0.08),
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
                          color: AppColors.ctaLime.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cram Mode',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.ctaLime.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SessionProgressBar(
                  current: _masteredCount,
                  total: _totalCards,
                  courseLabel: 'Cram',
                  onClose: () => Navigator.of(context).pop(),
                ),

                // Stats row
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Timer
                      const Icon(Icons.timer_outlined,
                          size: 12, color: Colors.white38),
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
                      // Progress text
                      Icon(Icons.check_circle_outline,
                          size: 12,
                          color: AppColors.ctaLime.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        '$_masteredCount/$_totalCards mastered',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Remaining
                      const Icon(Icons.layers_outlined,
                          size: 12, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        '$remainingCount left',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Sort Chips ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SortChip(
                    label: 'Random',
                    icon: Icons.shuffle_rounded,
                    isSelected: _sortMode == CramSortMode.random,
                    onTap: () => _onSortChanged(CramSortMode.random),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _SortChip(
                    label: 'Hardest First',
                    icon: Icons.trending_down_rounded,
                    isSelected: _sortMode == CramSortMode.hardestFirst,
                    onTap: () => _onSortChanged(CramSortMode.hardestFirst),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _SortChip(
                    label: 'Newest First',
                    icon: Icons.schedule_rounded,
                    isSelected: _sortMode == CramSortMode.newestFirst,
                    onTap: () => _onSortChanged(CramSortMode.newestFirst),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _SortChip(
                    label: 'Alphabetical',
                    icon: Icons.sort_by_alpha_rounded,
                    isSelected: _sortMode == CramSortMode.alphabetical,
                    onTap: () => _onSortChanged(CramSortMode.alphabetical),
                  ),
                ],
              ),
            ),
          ),

          // ── Card area with entrance animation ──
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
                child: AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _entranceOpacity.value,
                      child: Transform.scale(
                        scale: _entranceScale.value,
                        child: FlashcardWidget(
                          key: ValueKey(
                              'cram_${currentCard.id}_$_currentIndex'),
                          topic: currentCard.topic,
                          questionBefore: currentCard.questionBefore,
                          keyword: currentCard.keyword,
                          questionAfter: currentCard.questionAfter,
                          answer: currentCard.answer,
                          isRevealed: _isRevealed,
                          isSpeaking: _isSpeaking,
                          relatedCards: relatedCards,
                          onTap: _onTapCard,
                          onSpeak: TtsService.instance.isEnabled
                              ? _speakCurrentCard
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Action buttons (only shown after reveal) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: AnimatedOpacity(
              opacity: _isRevealed ? 1.0 : 0.35,
              duration: const Duration(milliseconds: 250),
              child: Row(
                children: [
                  // Need More Practice
                  Expanded(
                    child: TapScale(
                      onTap: _isRevealed ? _onNeedMorePractice : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.immersiveCard,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.replay_rounded,
                              size: 18,
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Again',
                              style: AppTypography.labelMedium.copyWith(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Got It
                  Expanded(
                    flex: 2,
                    child: TapScale(
                      onTap: _isRevealed ? _onGotIt : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.ctaLime,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: _isRevealed
                              ? [
                                  BoxShadow(
                                    color: AppColors.ctaLime
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: AppColors.ctaLimeText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Got it',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.ctaLimeText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hint text when not revealed
          if (!_isRevealed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                'Tap card to reveal answer',
                style: AppTypography.caption.copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Sort Chip
// ═════════════════════════════════════════════════════════════════════

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.immersiveBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primary : Colors.white38,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.primary : Colors.white54,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Summary Stat
// ═════════════════════════════════════════════════════════════════════

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
