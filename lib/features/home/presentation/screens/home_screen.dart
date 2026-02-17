import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/sound_service.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/greeting_header.dart';
import '../widgets/focus_flow_carousel.dart';
import '../widgets/recent_materials_grid.dart';
import '../../../assistant/presentation/widgets/oracle_smart_card.dart';
import '../../../subscription/presentation/widgets/usage_limit_banner.dart';
import '../widgets/study_activity_card.dart';

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
        // Check if current streak is a milestone after update
        final days = ref.read(profileProvider).whenOrNull(
              data: (p) => p?.streakDays,
            ) ??
            0;
        if (_streakMilestones.contains(days)) {
          SoundService.playStreakMilestone();
        }
      });
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
                color: AppColors.primary.withValues(alpha: 0.2),
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
                color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
              ),
            ),
          ),

          // Main content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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

                  // Usage Limit Banner (freemium)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: UsageLimitBanner(),
                  ),

                  // Oracle AI Insight Card
                  const SizedBox(height: AppSpacing.md),
                  const OracleSmartCard(),

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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
