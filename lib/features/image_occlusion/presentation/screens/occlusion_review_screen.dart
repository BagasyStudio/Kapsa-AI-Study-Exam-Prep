import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../flashcards/data/models/flashcard_model.dart';
import '../../data/models/occlusion_rect_model.dart';
import '../widgets/occlusion_painter.dart';

/// Review screen for image occlusion flashcards.
///
/// Displays the image with all regions occluded except the one being studied.
/// User taps to reveal each answer.
class OcclusionReviewScreen extends StatefulWidget {
  final List<FlashcardModel> cards;
  final String deckTitle;

  const OcclusionReviewScreen({
    super.key,
    required this.cards,
    required this.deckTitle,
  });

  @override
  State<OcclusionReviewScreen> createState() => _OcclusionReviewScreenState();
}

class _OcclusionReviewScreenState extends State<OcclusionReviewScreen> {
  int _currentIndex = 0;
  bool _revealed = false;
  Size _imageSize = Size.zero;

  FlashcardModel get _currentCard => widget.cards[_currentIndex];

  List<OcclusionRect> get _allRects {
    final data = _currentCard.occlusionData;
    if (data == null) return [];
    return data.map((e) => OcclusionRect.fromJson(e)).toList();
  }

  int? get _revealedRectIndex {
    if (!_revealed) return null;
    // Find which rect corresponds to this card's keyword/answer
    final rects = _allRects;
    for (int i = 0; i < rects.length; i++) {
      if (rects[i].label == _currentCard.answer) return i;
    }
    return null;
  }

  void _reveal() {
    HapticFeedback.lightImpact();
    setState(() => _revealed = true);
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_currentIndex < widget.cards.length - 1) {
      setState(() {
        _currentIndex++;
        _revealed = false;
      });
    } else {
      // Done reviewing
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final brightness = Theme.of(context).brightness;
    final progress = ((_currentIndex + 1) / widget.cards.length);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close,
              color: AppColors.textPrimaryFor(brightness)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              '${_currentIndex + 1} / ${widget.cards.length}',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textPrimaryFor(brightness),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFE2E8F0),
                color: AppColors.primary,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Image with occlusions
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _currentCard.imageUrl != null
                    ? GestureDetector(
                        onTap: _revealed ? null : _reveal,
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: _currentCard.imageUrl!,
                              fit: BoxFit.contain,
                              imageBuilder: (context, imageProvider) {
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Image(
                                      image: imageProvider,
                                      fit: BoxFit.contain,
                                      frameBuilder: (context, child, frame,
                                          wasSynchronouslyLoaded) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          final renderBox = context
                                              .findRenderObject() as RenderBox?;
                                          if (renderBox != null &&
                                              renderBox.hasSize &&
                                              renderBox.size != _imageSize) {
                                            setState(() =>
                                                _imageSize = renderBox.size);
                                          }
                                        });
                                        return child;
                                      },
                                    );
                                  },
                                );
                              },
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                            if (_imageSize != Size.zero)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: OcclusionPainter(
                                    rects: _allRects,
                                    revealedIndex: _revealedRectIndex,
                                    imageSize: _imageSize,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : Text(
                        'No image available',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMutedFor(brightness),
                        ),
                      ),
              ),
            ),
          ),

          // Answer area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  if (!_revealed) ...[
                    Text(
                      'Tap the image to reveal the answer',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMutedFor(brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TapScale(
                      onTap: _reveal,
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            'Show Answer',
                            style: AppTypography.button.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      _currentCard.answer,
                      style: AppTypography.h2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TapScale(
                      onTap: _next,
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            _currentIndex < widget.cards.length - 1
                                ? 'Next Card'
                                : 'Finish',
                            style: AppTypography.button.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
