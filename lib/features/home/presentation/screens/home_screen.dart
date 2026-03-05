import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/sound_service.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/kapsa_refresh_indicator.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../../gamification/presentation/widgets/xp_popup.dart';
import '../../../../core/constants/xp_config.dart';
import '../widgets/greeting_header.dart';
import '../widgets/focus_flow_carousel.dart';
import '../widgets/recent_materials_grid.dart';
import '../../../assistant/presentation/widgets/oracle_smart_card.dart';
import '../../../subscription/presentation/widgets/usage_limit_banner.dart';
import '../../../snap_solve/presentation/widgets/snap_solve_card.dart';
import '../../../snap_solve/presentation/widgets/snap_solve_banner.dart';
import '../widgets/generation_banner.dart';
import '../../../../core/navigation/routes.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../widgets/study_activity_card.dart';
import '../widgets/study_plan_card.dart';
import '../providers/study_plan_provider.dart';
import '../../../gamification/presentation/widgets/study_heatmap.dart';
import '../../../gamification/presentation/providers/heatmap_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../groups/presentation/widgets/group_card.dart';
import '../widgets/weekly_stats_card.dart';
import '../widgets/quick_actions_row.dart';
import '../providers/study_activity_provider.dart';
import '../providers/flashcard_quick_access_provider.dart';
import '../providers/resume_quiz_provider.dart';
import '../widgets/flashcard_quick_access_section.dart';
import '../widgets/resume_quiz_banner.dart';
import '../widgets/quick_review_card.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../gamification/data/models/achievement_model.dart';
import '../../../gamification/presentation/providers/achievement_provider.dart';
import '../../../gamification/presentation/widgets/achievement_popup.dart';
import '../../../sharing/data/milestone_service.dart';
import '../../../sharing/presentation/widgets/share_preview_sheet.dart';
import '../../../sharing/presentation/widgets/micro_cards/streak_milestone_card.dart';
import '../../../sharing/presentation/widgets/micro_cards/exam_day_card.dart';
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
    // Use ref.listen (not ref.watch) to trigger the streak update as a
    // side-effect — running this inside build() caused rebuild loops.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AsyncValue<ProfileModel?>>(profileProvider, (prev, next) {
        next.whenData((_) => _updateStreakOnce());
      });
    });
  }

  void _updateStreakOnce() {
    if (_streakUpdated) return;
    _streakUpdated = true;
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(profileRepositoryProvider).updateStreak(user.id).then((_) {
        if (!mounted) return;
        // Check if current streak is a milestone after update
        final days = ref.read(profileProvider).whenOrNull(
              data: (p) => p?.streakDays,
            ) ??
            0;
        if (_streakMilestones.contains(days)) {
          SoundService.playStreakMilestone();
        }
        // Check if this streak is a shareable milestone
        _checkStreakMilestone(days);
        // Check if today is an exam day for any course
        _checkExamDay();
        // Award streak XP once per day
        _awardStreakXp();
        // Check for new achievement badges
        _checkAchievements();
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
    } catch (_) {
      // Best-effort — don't interrupt the user
    }
  }

  Future<void> _checkAchievements() async {
    try {
      final repo = ref.read(achievementRepositoryProvider);
      final newBadges = await repo.checkAndUnlock();
      if (newBadges.isEmpty || !mounted) return;

      // Show popup for the first newly unlocked badge
      final badge = Badges.byKey[newBadges.first];
      if (badge != null) {
        // Small delay so it doesn't overlap with streak/XP popups
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          AchievementPopup.show(context, badge: badge);
        }
      }

      ref.invalidate(unlockedAchievementsProvider);
    } catch (_) {
      // Best-effort
    }
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
    } catch (_) {
      // Best-effort — don't interrupt the user
    }
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

          // Get prep stats
          int cardsReviewed = 0;
          double practiceScore = 0;
          try {
            // Count flashcard decks for this course
            final decks = await Supabase.instance.client
                .from('flashcard_decks')
                .select('id')
                .eq('course_id', course.id);
            cardsReviewed = (decks as List).length * 10; // rough estimate

            // Get latest test score
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
              courseName: course.title,
              cardsReviewed: cardsReviewed,
              practiceScore: practiceScore,
              userName: profile?.firstName ?? 'Student',
              xpLevel: xpLevel,
            ),
            shareType: 'exam_day',
            referenceId: course.id,
          );
          return; // Only show one exam day card at a time
        }
      }
    } catch (_) {
      // Best-effort — don't interrupt the user
    }
  }

  @override
  Widget build(BuildContext context) {
    // Selective watches: only rebuild when the specific field changes
    final userName = ref.watch(profileProvider.select(
          (async) => async.whenOrNull(data: (p) => p?.firstName),
        )) ??
        'Student';
    final streakDays = ref.watch(profileProvider.select(
          (async) => async.whenOrNull(data: (p) => p?.streakDays),
        )) ??
        0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuroraBackground(
      child: Stack(
        children: [
          // Ambient light glows
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.2),
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
                color: const Color(0xFF60A5FA).withValues(alpha: isDark ? 0.1 : 0.2),
              ),
            ),
          ),

          // Main content
          SafeArea(
            bottom: false,
            child: KapsaRefreshIndicator(
              onRefresh: () async {
                ref.invalidate(coursesProvider);
                ref.invalidate(profileProvider);
                ref.invalidate(studyPlanProvider);
                ref.invalidate(heatmapDataProvider);
                ref.invalidate(xpTotalProvider);
                ref.invalidate(studyActivityProvider);
                ref.invalidate(flashcardQuickAccessProvider);
                ref.invalidate(inProgressQuizzesProvider);
                ref.invalidate(totalDueCardsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(bottom: 120), // nav bar space
              child: StaggeredColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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

                  // Quick Actions Row
                  const QuickActionsRow(),
                  const SizedBox(height: AppSpacing.md),

                  // Usage Limit Banner (freemium)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: UsageLimitBanner(),
                  ),

                  // Snap & Solve background job banner
                  const SnapSolveBanner(),

                  // AI generation background banners
                  const GenerationBanner(),

                  // Resume in-progress quiz banner
                  const ResumeQuizBanner(),

                  // Quick Review — micro SRS session across all courses
                  const QuickReviewCard(),

                  // Flashcard Quick Access — one-tap deck access
                  const SizedBox(height: AppSpacing.lg),
                  const FlashcardQuickAccessSection(),

                  // Snap & Solve — #1 acquisition hook
                  const SizedBox(height: AppSpacing.md),
                  SnapSolveCard(
                    onTap: () => context.push(Routes.snapSolve),
                  ),

                  // Oracle AI Insight Card
                  const SizedBox(height: AppSpacing.md),
                  const OracleSmartCard(),

                  // Today's Study Plan
                  const SizedBox(height: AppSpacing.md),
                  const StudyPlanCard(),

                  // Study Heatmap
                  const SizedBox(height: AppSpacing.lg),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: StudyHeatmap(),
                  ),

                  // Weekly Stats
                  const SizedBox(height: AppSpacing.md),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: WeeklyStatsCard(),
                  ),

                  // Focus Flow Carousel
                  const SizedBox(height: AppSpacing.lg),
                  const FocusFlowCarousel(),

                  // Study Activity (recent quizzes & flashcards)
                  const SizedBox(height: AppSpacing.xxl),
                  const StudyActivityCard(),

                  // Recent Materials Grid
                  const SizedBox(height: AppSpacing.xxl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: RecentMaterialsGrid(),
                  ),

                  // Your Groups
                  const SizedBox(height: AppSpacing.xxl),
                  _GroupsSection(),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section showing user's study groups on the home screen.
class _GroupsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final brightness = Theme.of(context).brightness;

    return groupsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (groups) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Study Groups',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textPrimaryFor(brightness),
                    ),
                  ),
                  TapScale(
                    onTap: () => context.push(Routes.groupsList),
                    child: Text(
                      groups.isEmpty ? 'Create' : 'View All',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (groups.isEmpty)
                TapScale(
                  onTap: () => context.push(Routes.groupsList),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.groups_rounded,
                            color: AppColors.primary.withValues(alpha: 0.5)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Create or join a study group',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryFor(brightness),
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.textMutedFor(brightness)),
                      ],
                    ),
                  ),
                )
              else
                ...groups.take(2).map((group) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: GroupCard(
                        group: group,
                        onTap: () =>
                            context.push(Routes.groupDetailPath(group.id)),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}
