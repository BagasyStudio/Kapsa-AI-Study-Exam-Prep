import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _streakUpdated = false;

  void _updateStreakOnce() {
    if (_streakUpdated) return;
    _streakUpdated = true;
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(profileRepositoryProvider).updateStreak(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    // Update streak once when home loads
    profileAsync.whenData((_) => _updateStreakOnce());

    // Extract profile data with fallbacks
    final userName = profileAsync.whenOrNull(
          data: (profile) => profile?.firstName,
        ) ??
        'Student';
    final streakDays = profileAsync.whenOrNull(
          data: (profile) => profile?.streakDays,
        ) ??
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
