import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/sound_service.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/aurora_background.dart';
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
        // Award streak XP once per day
        _awardStreakXp();
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
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(coursesProvider);
                ref.invalidate(profileProvider);
                ref.invalidate(studyPlanProvider);
                ref.invalidate(heatmapDataProvider);
                ref.invalidate(xpTotalProvider);
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
