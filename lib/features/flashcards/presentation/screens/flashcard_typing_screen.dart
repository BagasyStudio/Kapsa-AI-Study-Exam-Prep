import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/flashcard_model.dart';
import '../providers/flashcard_provider.dart';

/// Typing Mode: user types the answer to each flashcard and gets scored.
///
/// Shows the question (front of card), a TextField for the user to type
/// their answer, and a "Check" button. After checking, the user sees
/// feedback (exact match, close match, or incorrect) and can proceed
/// to the next card.
class FlashcardTypingScreen extends ConsumerStatefulWidget {
  final String deckId;

  const FlashcardTypingScreen({super.key, required this.deckId});

  @override
  ConsumerState<FlashcardTypingScreen> createState() =>
      _FlashcardTypingScreenState();
}

class _FlashcardTypingScreenState extends ConsumerState<FlashcardTypingScreen> {
  List<FlashcardModel>? _cards;
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _hasChecked = false;
  _AnswerResult? _lastResult;

  final _answerController = TextEditingController();
  final _answerFocusNode = FocusNode();

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  // ── String similarity ──────────────────────────────────────────────

  /// Simple string similarity: count positional character matches / max length.
  double _stringSimilarity(String a, String b) {
    final s1 = a.trim().toLowerCase();
    final s2 = b.trim().toLowerCase();
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;

    final maxLen = max(s1.length, s2.length);
    final minLen = min(s1.length, s2.length);
    int matches = 0;
    for (int i = 0; i < minLen; i++) {
      if (s1[i] == s2[i]) matches++;
    }
    return matches / maxLen;
  }

  // ── Check answer ───────────────────────────────────────────────────

  void _checkAnswer() {
    if (_cards == null || _hasChecked) return;

    final userAnswer = _answerController.text.trim();
    if (userAnswer.isEmpty) return;

    final card = _cards![_currentIndex];
    final correctAnswer = card.answer;
    final similarity = _stringSimilarity(userAnswer, correctAnswer);

    _AnswerResult result;
    if (similarity >= 1.0) {
      result = _AnswerResult.exact;
      _correctCount++;
      HapticFeedback.lightImpact();
    } else if (similarity > 0.80) {
      result = _AnswerResult.close;
      _correctCount++;
      HapticFeedback.mediumImpact();
    } else {
      result = _AnswerResult.wrong;
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _hasChecked = true;
      _lastResult = result;
    });
  }

  // ── Next card ──────────────────────────────────────────────────────

  void _nextCard() {
    if (_cards == null) return;

    if (_currentIndex >= _cards!.length - 1) {
      // Session complete
      return;
    }

    setState(() {
      _currentIndex++;
      _hasChecked = false;
      _lastResult = null;
      _answerController.clear();
    });

    // Re-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _answerFocusNode.canRequestFocus) {
        _answerFocusNode.requestFocus();
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cardsAsync =
        ref.watch(allCardsForParentDeckProvider(widget.deckId));

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.darkImmersive,
        ),
        child: cardsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => _buildError(),
          data: (cards) {
            if (cards.isEmpty) return _buildEmpty();
            _cards ??= List.from(cards)..shuffle();
            return _buildSession();
          },
        ),
      ),
    );
  }

  Widget _buildError() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load cards',
              style: AppTypography.h3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back',
                  style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined,
                size: 48, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No flashcards in this deck',
              style: AppTypography.h3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back',
                  style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSession() {
    final cards = _cards!;
    final total = cards.length;
    final current = _currentIndex + 1;
    final progress = current / total;
    final card = cards[_currentIndex];
    final isLast = _currentIndex == total - 1;
    final isComplete = isLast && _hasChecked;

    final question =
        '${card.questionBefore}${card.keyword}${card.questionAfter}';

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
            child: Row(
              children: [
                // Close button
                TapScale(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Icon(Icons.close,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Progress bar
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.1),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Score counter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$_correctCount/$total',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Mode label ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_rounded,
                    size: 12,
                    color: AppColors.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  'Typing Mode',
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

          // ── Question area ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card number badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6467F2),
                          Color(0xFF8B5CF6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Card $current',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Question text
                  Text(
                    question,
                    style: AppTypography.h2.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Answer text field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _hasChecked
                            ? _resultColor(_lastResult).withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: TextField(
                      controller: _answerController,
                      focusNode: _answerFocusNode,
                      enabled: !_hasChecked,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: 3,
                      minLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type your answer...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.50),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.all(AppSpacing.lg),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (!_hasChecked) _checkAnswer();
                      },
                    ),
                  ),

                  // ── Feedback section ──
                  if (_hasChecked) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildFeedback(card),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom action button ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              MediaQuery.of(context).padding.bottom + AppSpacing.md,
            ),
            child: isComplete
                ? _buildFinishButton()
                : _hasChecked
                    ? _buildNextButton()
                    : _buildCheckButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback(FlashcardModel card) {
    final result = _lastResult!;
    final color = _resultColor(result);
    final icon = _resultIcon(result);
    final message = _resultMessage(result, card.answer);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _resultTitle(result),
                style: AppTypography.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckButton() {
    final hasText = _answerController.text.trim().isNotEmpty;
    return TapScale(
      onTap: hasText ? _checkAnswer : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: hasText
              ? AppColors.ctaLime
              : AppColors.ctaLime.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: Text(
            'Check',
            style: AppTypography.button.copyWith(
              color: hasText
                  ? AppColors.ctaLimeText
                  : AppColors.ctaLimeText.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return TapScale(
      onTap: _nextCard,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Next Card',
                style: AppTypography.button.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishButton() {
    final total = _cards!.length;
    return Column(
      children: [
        // Score summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.immersiveCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.immersiveBorder),
          ),
          child: Column(
            children: [
              Text(
                'Session Complete',
                style: AppTypography.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$_correctCount / $total correct',
                style: AppTypography.bodyMedium.copyWith(
                  color: _correctCount == total
                      ? const Color(0xFF22C55E)
                      : _correctCount > total / 2
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        TapScale(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.ctaLime,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Text(
                'Done',
                style: AppTypography.button.copyWith(
                  color: AppColors.ctaLimeText,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Color _resultColor(_AnswerResult? result) {
    switch (result) {
      case _AnswerResult.exact:
        return const Color(0xFF22C55E);
      case _AnswerResult.close:
        return const Color(0xFFF59E0B);
      case _AnswerResult.wrong:
        return const Color(0xFFEF4444);
      case null:
        return Colors.white;
    }
  }

  IconData _resultIcon(_AnswerResult result) {
    switch (result) {
      case _AnswerResult.exact:
        return Icons.check_circle;
      case _AnswerResult.close:
        return Icons.info_outline;
      case _AnswerResult.wrong:
        return Icons.cancel_outlined;
    }
  }

  String _resultTitle(_AnswerResult result) {
    switch (result) {
      case _AnswerResult.exact:
        return 'Perfect!';
      case _AnswerResult.close:
        return 'Close!';
      case _AnswerResult.wrong:
        return 'Not quite';
    }
  }

  String _resultMessage(_AnswerResult result, String correctAnswer) {
    switch (result) {
      case _AnswerResult.exact:
        return 'You got it exactly right.';
      case _AnswerResult.close:
        return 'The correct answer was: $correctAnswer';
      case _AnswerResult.wrong:
        return 'The correct answer was: $correctAnswer';
    }
  }
}

enum _AnswerResult { exact, close, wrong }
