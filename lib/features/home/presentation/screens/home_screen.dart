import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/services/sound_service.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

import '../../../../core/widgets/kapsa_refresh_indicator.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../../gamification/presentation/widgets/xp_popup.dart';
import '../../../../core/constants/xp_config.dart';
import '../widgets/greeting_header.dart';
import '../widgets/focus_flow_carousel.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/home_empty_state.dart';
import '../../../subscription/presentation/widgets/usage_limit_banner.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../providers/study_plan_provider.dart';
import '../widgets/quick_actions_row.dart';
import '../providers/resume_quiz_provider.dart';
import '../../../../core/providers/generation_provider.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../providers/flashcard_quick_access_provider.dart';
import '../widgets/flashcard_quick_access_section.dart';
import '../widgets/journey_hero_widget.dart';
import '../providers/journey_provider.dart';
import '../../../gamification/data/models/achievement_model.dart';
import '../../../gamification/presentation/providers/achievement_provider.dart';
import '../../../gamification/presentation/widgets/achievement_popup.dart';
import '../../../sharing/data/milestone_service.dart';
import '../../../sharing/presentation/widgets/share_preview_sheet.dart';
import '../../../sharing/presentation/widgets/micro_cards/streak_milestone_card.dart';
import '../../../sharing/presentation/widgets/micro_cards/exam_day_card.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../../core/constants/app_limits.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _streakUpdated = false;

  static const _streakMilestones = {3, 7, 14, 30, 60, 100, 365};

  @override
  void initState() {
    super.initState();
    // Streak update is triggered via ref.listen in build() method
    // (Riverpod requires ref.listen to be called inside build)
  }

  void _updateStreakOnce() {
    if (_streakUpdated) return;
    _streakUpdated = true;
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(profileRepositoryProvider).updateStreak(user.id).then((_) {
        if (!mounted) return;
        final days = ref.read(profileProvider).whenOrNull(
              data: (p) => p?.streakDays,
            ) ??
            0;
        if (_streakMilestones.contains(days)) {
          SoundService.playStreakMilestone();
        }
        _checkStreakMilestone(days);
        _checkExamDay();
        _awardStreakXp();
        _checkAchievements();
        _recalculateCourseProgress();
      });
    }
  }

  Future<void> _awardStreakXp() async {
    try {
      final xpRepo = ref.read(xpRepositoryProvider);
      final alreadyAwarded = await xpRepo.hasStreakXpToday();
      if (alreadyAwarded) return;

      await xpRepo.awardXp(
        action: 'streak_day',
        amount: XpConfig.streakDay,
      );
      ref.invalidate(xpTotalProvider);
      if (mounted) {
        XpPopup.show(context, xp: XpConfig.streakDay, label: 'Daily Streak');
      }
    } catch (_) {}
  }

  Future<void> _recalculateCourseProgress() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      await ref.read(courseRepositoryProvider).recalculateAllProgress(user.id);
      ref.invalidate(coursesProvider);
    } catch (_) {}
  }

  Future<void> _checkAchievements() async {
    try {
      final repo = ref.read(achievementRepositoryProvider);
      final newBadges = await repo.checkAndUnlock();
      if (newBadges.isEmpty || !mounted) return;

      final badge = Badges.byKey[newBadges.first];
      if (badge != null) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          AchievementPopup.show(context, badge: badge);
        }
      }

      ref.invalidate(unlockedAchievementsProvider);
    } catch (_) {}
  }

  Future<void> _checkStreakMilestone(int days) async {
    try {
      final milestone = await MilestoneService.checkStreakMilestone(days);
      if (milestone == null || !mounted) return;

      final profile = ref.read(profileProvider).whenOrNull(data: (p) => p);
      final userName = profile?.firstName ?? 'Student';
      final totalXp = ref.read(xpTotalProvider).whenOrNull(data: (v) => v) ?? 0;
      final xpLevel = XpConfig.levelFromXp(totalXp);

      await MilestoneService.markShown('streak', '$milestone');

      if (!mounted) return;
      SharePreviewSheet.show(
        context,
        shareCard: StreakMilestoneCard(
          streakDays: milestone,
          totalXp: totalXp,
          userName: userName,
          xpLevel: xpLevel,
        ),
        shareType: 'streak_milestone',
      );
    } catch (_) {}
  }

  Future<void> _checkExamDay() async {
    try {
      final courses =
          ref.read(coursesProvider).whenOrNull(data: (c) => c) ?? [];
      final today = DateTime.now();

      for (final course in courses) {
        if (course.examDate == null) continue;
        final examDate = course.examDate!;
        if (examDate.year == today.year &&
            examDate.month == today.month &&
            examDate.day == today.day) {
          final milestone =
              await MilestoneService.checkMilestone('exam_day', course.id);
          if (milestone == null || !mounted) return;

          await MilestoneService.markShown('exam_day', course.id);

          final profile =
              ref.read(profileProvider).whenOrNull(data: (p) => p);
          final totalXp =
              ref.read(xpTotalProvider).whenOrNull(data: (v) => v) ?? 0;
          final xpLevel = XpConfig.levelFromXp(totalXp);

          int cardsReviewed = 0;
          double practiceScore = 0;
          try {
            final decks = await Supabase.instance.client
                .from('flashcard_decks')
                .select('id')
                .eq('course_id', course.id);
            cardsReviewed = (decks as List).length * 10;

            final tests = await Supabase.instance.client
                .from('tests')
                .select('score')
                .eq('course_id', course.id)
                .not('score', 'is', null)
                .order('created_at', ascending: false)
                .limit(1);
            if ((tests as List).isNotEmpty) {
              practiceScore =
                  ((tests[0]['score'] as num?) ?? 0) * 100;
            }
          } catch (_) {}

          if (!mounted) return;
          SharePreviewSheet.show(
            context,
            shareCard: ExamDayCard(
              courseName: course.displayTitle,
              cardsReviewed: cardsReviewed,
              practiceScore: practiceScore,
              userName: profile?.firstName ?? 'Student',
              xpLevel: xpLevel,
            ),
            shareType: 'exam_day',
            referenceId: course.id,
          );
          return;
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Listen for profile changes to trigger streak update once
    ref.listen<AsyncValue<ProfileModel?>>(profileProvider, (prev, next) {
      next.whenData((_) => _updateStreakOnce());
    });

    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: Stack(
        children: [
          // Subtle dark radial glows
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  radius: 1.2,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 288,
              height: 288,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E40AF).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  radius: 1.0,
                ),
              ),
            ),
          ),

          // Main content — 4 data states
          SafeArea(
            bottom: false,
            child: coursesAsync.when(
              loading: () => const _HomeShimmer(),
              error: (e, _) => _HomeErrorRetry(
                error: e,
                onRetry: () => ref.invalidate(coursesProvider),
              ),
              data: (courses) {
                if (courses.isEmpty) {
                  return const HomeEmptyState();
                }
                return _buildNormalHome(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Simplified Home: 4 sections ────────────────────────────────────────────

  Widget _buildNormalHome(BuildContext context) {
    final userName = ref.watch(profileProvider.select(
          (async) => async.whenOrNull(data: (p) => p?.firstName),
        )) ??
        'Student';
    final streakDays = ref.watch(profileProvider.select(
          (async) => async.whenOrNull(data: (p) => p?.streakDays),
        )) ??
        0;

    final generationTasks = ref.watch(generationProvider);
    final hasRunningGeneration = generationTasks.any((t) => t.isRunning);

    return KapsaRefreshIndicator(
      onRefresh: () async {
        ref.invalidate(coursesProvider);
        ref.invalidate(profileProvider);
        ref.invalidate(studyPlanProvider);
        ref.invalidate(inProgressQuizzesProvider);
        ref.invalidate(totalDueCardsProvider);
        ref.invalidate(flashcardQuickAccessProvider);
        final activeCourse = ref.read(activeJourneyCourseProvider);
        if (activeCourse != null) {
          ref.invalidate(journeyNodesProvider(activeCourse));
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 120),
        child: StaggeredColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Greeting Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: GreetingHeader(
                userName: userName,
                streakDays: streakDays,
              ),
            ),

            // 2. Journey Hero — primary study continuation surface
            const JourneyHeroWidget(),
            const SizedBox(height: AppSpacing.lg),

            // 3. Hero Card (contextual: generation/quiz/due cards)
            const HomeHeroCard(),
            const SizedBox(height: AppSpacing.lg),

            // 4. Quick Actions Row (reduced opacity during generation)
            Opacity(
              opacity: hasRunningGeneration ? 0.6 : 1.0,
              child: const QuickActionsRow(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 5. Focus Flow Carousel or compact link during generation
            if (hasRunningGeneration)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: GestureDetector(
                  onTap: () => context.go(Routes.courses),
                  child: Row(
                    children: [
                      Text(
                        'Your Decks',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Colors.white60,
                      ),
                    ],
                  ),
                ),
              )
            else
              const FocusFlowCarousel(),

            const SizedBox(height: AppSpacing.lg),

            // 6. Flashcard Quick Access (auto-hides if no decks)
            const FlashcardQuickAccessSection(),

            // Usage Limit Banner — only when credits < 20%
            const SizedBox(height: AppSpacing.lg),
            const _ConditionalUsageBanner(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Usage banner — only shows when remaining credits < 20% of daily limit
// ═══════════════════════════════════════════════════════════════════════════════

class _ConditionalUsageBanner extends ConsumerWidget {
  const _ConditionalUsageBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(remainingCreditsProvider).whenOrNull(data: (r) => r);
    if (remaining == null) return const SizedBox.shrink();

    final total = AppLimits.freeCreditsPerDay;
    final threshold = (total * 0.2).ceil();

    // Only show when credits are below 20%
    if (remaining > threshold) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: UsageLimitBanner(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Loading State — Shimmer skeleton
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    final shimmerBase = Colors.white.withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          // Greeting shimmer
          _ShimmerBox(width: 180, height: 24, color: shimmerBase),
          const SizedBox(height: 8),
          _ShimmerBox(width: 120, height: 20, color: shimmerBase),
          const SizedBox(height: AppSpacing.xl),
          // Hero card shimmer
          _ShimmerBox(
            width: double.infinity,
            height: 88,
            color: shimmerBase,
            borderRadius: 20,
          ),
          const SizedBox(height: AppSpacing.xl),
          // Quick actions shimmer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (_) => Column(
                children: [
                  _ShimmerBox(
                    width: 58,
                    height: 58,
                    color: shimmerBase,
                    borderRadius: 29,
                  ),
                  const SizedBox(height: 8),
                  _ShimmerBox(width: 48, height: 10, color: shimmerBase),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Carousel shimmer
          _ShimmerBox(width: 140, height: 16, color: shimmerBase),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ShimmerBox(
                  width: double.infinity,
                  height: 140,
                  color: shimmerBase,
                  borderRadius: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ShimmerBox(
                  width: double.infinity,
                  height: 140,
                  color: shimmerBase,
                  borderRadius: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.color,
    this.borderRadius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Error State — Compact retry card
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _HomeErrorRetry({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.immersiveCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.immersiveBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Something went wrong',
                style: AppTypography.h4.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Check your connection and try again',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white60,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TapScale(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Retry',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
