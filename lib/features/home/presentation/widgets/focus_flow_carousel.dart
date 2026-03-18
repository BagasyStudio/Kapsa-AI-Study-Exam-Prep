import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'focus_flow_card.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../../core/utils/error_handler.dart';

/// Horizontal scrollable carousel of Focus Flow cards.
///
/// Uses PageView with viewportFraction 0.85 for the peek effect.
/// Applies scale and opacity transitions so the non-active card
/// peeks at 70% opacity and 95% scale (matching the HTML mockup).
class FocusFlowCarousel extends ConsumerStatefulWidget {
  const FocusFlowCarousel({super.key});

  @override
  ConsumerState<FocusFlowCarousel> createState() => _FocusFlowCarouselState();
}

class _FocusFlowCarouselState extends ConsumerState<FocusFlowCarousel>
    with SingleTickerProviderStateMixin {
  late final PageController _controller;
  double _currentPage = 0;

  /// Peek animation: hints there's more content off-screen.
  Timer? _peekTimer;
  AnimationController? _peekAnimController;
  bool _hasPeeked = false;
  bool _userHasScrolled = false;
  bool _isPeekScrolling = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.85);
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _currentPage = _controller.page ?? 0;
    });

    // If user manually scrolls (not the peek animation), cancel peek.
    if (!_hasPeeked && !_userHasScrolled && !_isPeekScrolling) {
      _userHasScrolled = true;
      _cancelPeek();
    }
  }

  /// Schedule the peek animation after data loads. Only runs once.
  void _schedulePeek() {
    if (_hasPeeked || _userHasScrolled) return;
    _peekTimer?.cancel();
    _peekTimer = Timer(const Duration(seconds: 4), _playPeek);
  }

  void _cancelPeek() {
    _peekTimer?.cancel();
    _peekTimer = null;
    _peekAnimController?.stop();
  }

  /// Auto-scroll 20px left and back to hint at more content.
  void _playPeek() {
    if (!mounted || _hasPeeked || _userHasScrolled) return;
    if (!_controller.hasClients) return;

    _hasPeeked = true;
    _isPeekScrolling = true;
    final startOffset = _controller.offset;
    final peekOffset = startOffset + 20.0;

    _peekAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: startOffset, end: peekOffset)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: peekOffset, end: startOffset)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(_peekAnimController!);

    animation.addListener(() {
      if (_controller.hasClients) {
        _controller.jumpTo(animation.value);
      }
    });

    _peekAnimController!.forward().then((_) {
      _isPeekScrolling = false;
    });
  }

  @override
  void dispose() {
    _peekTimer?.cancel();
    _peekAnimController?.dispose();
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FOCUS FLOW',
                style: AppTypography.sectionHeader,
              ),
              TapScale(
                onTap: () => context.go(Routes.courses),
                child: Text(
                  'See all',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Card carousel
        SizedBox(
          height: 310,
          child: coursesAsync.when(
            loading: () => const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                AppErrorHandler.friendlyMessage(e),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ),
            data: (courses) {
              if (courses.isEmpty) {
                return Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school,
                            size: 48,
                            color: AppColors.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No courses yet',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Create your first course to get started!',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMutedDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Show up to 5 courses in carousel
              final displayCourses = courses.take(5).toList();

              // Schedule peek hint if more than 1 card
              if (displayCourses.length > 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _schedulePeek();
                });
              }

              return PageView.builder(
                controller: _controller,
                clipBehavior: Clip.none,
                itemCount: displayCourses.length,
                itemBuilder: (context, index) {
                  final course = displayCourses[index];
                  final diff =
                      (index - _currentPage).abs().clamp(0.0, 1.0);
                  final scale = 1.0 - (diff * 0.05);
                  final opacity = 1.0 - (diff * 0.30);

                  final hasExam = course.examDate != null;
                  final tag = hasExam ? 'Exam Coming' : 'In Progress';
                  final tagColor = hasExam
                      ? const Color(0xFFFEF3C7).withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.08);
                  final tagTextColor = hasExam
                      ? const Color(0xFFFBBF24)
                      : AppColors.primaryLight;

                  return Consumer(
                    builder: (context, cRef, _) {
                      final dueCount = cRef
                          .watch(dueCardsCountProvider(course.id))
                          .whenOrNull(data: (c) => c) ?? 0;
                      final parentDecks = cRef
                          .watch(parentDecksProvider(course.id))
                          .whenOrNull(data: (d) => d);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xs,
                        ),
                        child: Opacity(
                          opacity: opacity,
                          child: Transform.scale(
                            scale: scale,
                            alignment: index < _currentPage
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: FocusFlowCard(
                              tag: tag,
                              tagColor: tagColor,
                              tagTextColor: tagTextColor,
                              title: course.displayTitle,
                              subtitle: course.subtitle ?? '',
                              progress: course.progress,
                              ctaLabel: 'Continue',
                              isSecondary: index > 0,
                              dueCount: dueCount,
                              onCtaTap: () {
                                if (parentDecks != null && parentDecks.isNotEmpty) {
                                  context.push(Routes.deckDetailPath(parentDecks.first.id));
                                } else {
                                  context.push(Routes.courseDetailPath(course.id));
                                }
                              },
                              onDueTap: dueCount > 0
                                  ? () => context.push(
                                      Routes.srsReviewPath(course.id))
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
