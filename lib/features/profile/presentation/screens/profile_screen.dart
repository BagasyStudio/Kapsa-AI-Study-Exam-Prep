import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/revenue_cat_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../subscription/presentation/widgets/ai_consent_dialog.dart';
import '../providers/profile_provider.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../../../core/constants/xp_config.dart';
import '../../../gamification/presentation/widgets/achievement_collection.dart';
import '../../../gamification/presentation/widgets/study_heatmap.dart';
import '../../../home/presentation/widgets/weekly_stats_card.dart';
import '../../../home/presentation/widgets/study_activity_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.immersiveCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Sign Out',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white60,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white60,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authRepositoryProvider).signOut();
              // Clear cached data from previous user session
              ref.invalidate(coursesProvider);
              ref.invalidate(recentMaterialsProvider);
            },
            child: Text(
              'Sign Out',
              style: AppTypography.labelLarge.copyWith(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final currentUser = ref.watch(currentUserProvider);
    final xpTotal = ref.watch(xpTotalProvider).valueOrNull ?? 0;
    final xpLevel = XpConfig.levelFromXp(xpTotal);

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: Stack(
        children: [
          // Ethereal mesh gradients — forced dark opacities
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.0, -1.0),
                  radius: 1.2,
                  colors: [
                    const Color(0xFF1E1A2E).withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -1.0),
                  radius: 1.0,
                  colors: [
                    const Color(0xFF1A1E30).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.0, -1.0),
                  radius: 1.0,
                  colors: [
                    const Color(0xFF2A1A22).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              child: profileAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Center(
                    child: Text(
                      'Error loading profile',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ),
                data: (profile) {
                  final displayName = profile?.fullName ?? 'Student';
                  final displayInitial = profile?.initials ?? '?';
                  final displayEmail = currentUser?.email ?? '';
                  final streakDays = profile?.streakDays ?? 0;
                  final totalCourses = profile?.totalCourses ?? 0;
                  final averageGrade = profile?.averageGrade ?? '--';

                  return StaggeredColumn(
                    children: [
                      const SizedBox(height: AppSpacing.xl),

                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.primaryToIndigo,
                          border: Border.all(
                            color: AppColors.immersiveSurface,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            displayInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 32,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Name
                      Text(
                        displayName,
                        style: AppTypography.h2.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayEmail,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white60,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // XP Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              const Color(0xFFF97316).withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Level $xpLevel',
                              style: AppTypography.labelLarge.copyWith(
                                color: const Color(0xFFF59E0B),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Container(
                              width: 3,
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                              ),
                            ),
                            Text(
                              '${_formatNumber(xpTotal)} XP',
                              style: AppTypography.caption.copyWith(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Stats row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                value: '$streakDays',
                                label: 'Day Streak',
                                icon: Icons.local_fire_department,
                                iconColor: const Color(0xFFF97316),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _StatCard(
                                value: '$totalCourses',
                                label: 'Courses',
                                icon: Icons.menu_book,
                                iconColor: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _StatCard(
                                value: averageGrade,
                                label: 'Average',
                                icon: Icons.trending_up,
                                iconColor: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Knowledge Score banner
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: TapScale(
                          onTap: () => context.push(Routes.knowledgeScore),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF6467F2).withValues(alpha: 0.15),
                                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                  const Color(0xFFEC4899).withValues(alpha: 0.08),
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xFF6467F2).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.insights,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Knowledge Score',
                                        style: AppTypography.labelLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'See your academic profile & share it',
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Month in Review banner
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: TapScale(
                          onTap: () => context.push(Routes.monthReview),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF10B981).withValues(alpha: 0.12),
                                  const Color(0xFF3B82F6).withValues(alpha: 0.08),
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
                                    ),
                                  ),
                                  child: const Icon(Icons.calendar_month, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Month in Review',
                                        style: AppTypography.labelLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Your study highlights & personality',
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Color(0xFF10B981), size: 22),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Achievement Badges
                      const AchievementCollection(),

                      const SizedBox(height: AppSpacing.xxl),

                      // My Stats section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MY STATS',
                              style: AppTypography.sectionHeader.copyWith(
                                color: Colors.white38,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const StudyHeatmap(),
                            const SizedBox(height: AppSpacing.md),
                            const WeeklyStatsCard(),
                            const SizedBox(height: AppSpacing.md),
                            const StudyActivityCard(),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Settings section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SETTINGS',
                              style: AppTypography.sectionHeader.copyWith(
                                color: Colors.white38,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            if (!kIsWeb) _NotificationToggleTile(),
                            _SoundToggleTile(),
                            _TtsToggleTile(),
                            _TtsAutoReadToggleTile(),
                            _AiDataToggleTile(),
                            _ThemeToggleTile(),
                            _SettingsTile(
                              icon: Icons.download_outlined,
                              label: 'Downloads',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Downloads coming soon')),
                                );
                              },
                            ),

                            // Divider
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                              child: Divider(
                                color: AppColors.immersiveBorder.withValues(alpha: 0.6),
                              ),
                            ),

                            // Legal
                            _SettingsTile(
                              icon: Icons.description_outlined,
                              label: 'Terms of Service',
                              onTap: () => context.push(Routes.terms),
                            ),
                            _SettingsTile(
                              icon: Icons.privacy_tip_outlined,
                              label: 'Privacy Policy',
                              onTap: () => context.push(Routes.privacy),
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // Subscription section — conditional
                            _SubscriptionSection(),

                            const SizedBox(height: AppSpacing.xxl),

                            // Sign Out with confirmation
                            Center(
                              child: TapScale(
                                onTap: () => _showSignOutDialog(context),
                                child: Text(
                                  'Sign Out',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // Delete Account
                            Center(
                              child: TapScale(
                                onTap: () => context.push(Routes.deleteAccount),
                                child: Text(
                                  'Delete Account',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.xxl),

                            // Version number
                            Center(
                              child: FutureBuilder<PackageInfo>(
                                future: PackageInfo.fromPlatform(),
                                builder: (context, snapshot) {
                                  final version = snapshot.data?.version ?? '...';
                                  final build = snapshot.data?.buildNumber ?? '';
                                  return Text(
                                    'Version $version${build.isNotEmpty ? ' ($build)' : ''}',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.white38.withValues(alpha: 0.4),
                                      fontSize: 11,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

/// Subscription section — shows Pro badge if subscribed, or Upgrade + Restore if free.
class _SubscriptionSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProAsync = ref.watch(isProProvider);

    return isProAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _buildUpgradeCard(context),
      data: (isPro) {
        if (isPro) {
          return _buildProBadge(context);
        }
        return Column(
          children: [
            _buildUpgradeCard(context),
            const SizedBox(height: AppSpacing.md),
            _buildRestoreButton(context, ref),
          ],
        );
      },
    );
  }

  Widget _buildProBadge(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withValues(alpha: 0.15),
                const Color(0xFF059669).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kapsa Pro Active',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All features unlocked',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.auto_awesome,
                color: const Color(0xFFFBBF24),
                size: 22,
              ),
            ],
          ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return TapScale(
      onTap: () => context.push(Routes.paywall),
      child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  const Color(0xFF6366F1).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primaryToIndigo,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upgrade to Pro',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Unlock AI Oracle & Smart Study Plans',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildRestoreButton(BuildContext context, WidgetRef ref) {
    return Center(
      child: TapScale(
        onTap: () async {
          final success = await ref
              .read(purchaseNotifierProvider.notifier)
              .restore();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Purchases restored! Welcome back to Pro.'
                      : 'No previous purchases found.',
                ),
              ),
            );
          }
        },
        child: Text(
          'Restore Purchases',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white60,
            fontWeight: FontWeight.w500,
            fontSize: 13,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white38.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Glass stat card for profile stats — immersive dark.
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          constraints: const BoxConstraints(minHeight: 100),
          decoration: BoxDecoration(
            color: AppColors.immersiveCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.immersiveBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: Colors.white60,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
    );
  }
}

/// Notification toggle tile with permission request and smart scheduling.
class _NotificationToggleTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NotificationToggleTile> createState() =>
      _NotificationToggleTileState();
}

class _NotificationToggleTileState
    extends ConsumerState<_NotificationToggleTile> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await NotificationService.isEnabled();
    if (mounted) setState(() { _enabled = enabled; _loading = false; });
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      // Request permission first
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable notifications in Settings'),
            ),
          );
        }
        return;
      }
    }

    await NotificationService.setEnabled(value);
    if (!mounted) return;
    setState(() => _enabled = value);

    if (value) {
      // Schedule smart reminders with current user data
      await _scheduleReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study reminders enabled! 🔔'),
          ),
        );
      }
    }
  }

  Future<void> _scheduleReminders() async {
    final profile = ref.read(profileProvider).valueOrNull;
    final courses = ref.read(coursesProvider).valueOrNull ?? [];

    final exams = courses
        .where((c) => c.examDate != null && c.examDate!.isAfter(DateTime.now()))
        .map((c) => ExamReminder(courseName: c.displayTitle, date: c.examDate!))
        .toList();

    // Query due SRS cards for notification
    int dueCardCount = 0;
    List<String> courseNamesWithDue = [];
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final dueCards = await Supabase.instance.client
          .from('flashcards')
          .select('id, flashcard_decks!inner(courses!inner(title))')
          .lte('due', now)
          .limit(200);
      dueCardCount = (dueCards as List).length;
      // Extract unique course names
      final names = <String>{};
      for (final card in dueCards) {
        final deck = card['flashcard_decks'];
        if (deck != null) {
          final course = deck['courses'];
          if (course != null && course['title'] != null) {
            names.add(course['title'] as String);
          }
        }
      }
      courseNamesWithDue = names.toList();
    } catch (_) {
      // Best-effort — don't block reminders
    }

    await NotificationService.scheduleSmartReminders(
      streakDays: profile?.streakDays ?? 0,
      upcomingExams: exams,
      userName: profile?.firstName ?? 'Student',
      dueCardCount: dueCardCount,
      courseNamesWithDue: courseNamesWithDue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () => _toggle(!_enabled),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                _enabled
                    ? Icons.notifications_active
                    : Icons.notifications_outlined,
                size: 18,
                color: _enabled
                    ? AppColors.primary
                    : Colors.white60,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study Reminders',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _enabled ? 'On — daily at 8:00 PM' : 'Off',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch.adaptive(
                value: _enabled,
                onChanged: _toggle,
                activeTrackColor: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Sound effects toggle tile.
class _SoundToggleTile extends StatefulWidget {
  @override
  State<_SoundToggleTile> createState() => _SoundToggleTileState();
}

class _SoundToggleTileState extends State<_SoundToggleTile> {
  bool _enabled = SoundService.isEnabled;

  Future<void> _toggle(bool value) async {
    await SoundService.setEnabled(value);
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () => _toggle(!_enabled),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                _enabled ? Icons.volume_up : Icons.volume_off_outlined,
                size: 18,
                color: _enabled
                    ? AppColors.primary
                    : Colors.white60,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sound Effects',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _enabled ? 'On' : 'Off',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _enabled,
              onChanged: _toggle,
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// TTS (Text-to-Speech) toggle for flashcard reading.
class _TtsToggleTile extends StatefulWidget {
  @override
  State<_TtsToggleTile> createState() => _TtsToggleTileState();
}

class _TtsToggleTileState extends State<_TtsToggleTile> {
  bool _enabled = TtsService.instance.isEnabled;

  Future<void> _toggle(bool value) async {
    await TtsService.instance.setEnabled(value);
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () => _toggle(!_enabled),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF14B8A6).withValues(alpha: 0.08),
                border: Border.all(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                _enabled ? Icons.record_voice_over : Icons.voice_over_off_outlined,
                size: 18,
                color: _enabled
                    ? const Color(0xFF14B8A6)
                    : Colors.white60,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Text-to-Speech',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _enabled ? 'Read flashcards aloud' : 'Off',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _enabled,
              onChanged: _toggle,
              activeTrackColor: const Color(0xFF14B8A6),
            ),
          ],
        ),
      ),
    );
  }
}

/// TTS Auto-Read toggle — automatically reads the answer when revealed.
class _TtsAutoReadToggleTile extends StatefulWidget {
  @override
  State<_TtsAutoReadToggleTile> createState() => _TtsAutoReadToggleTileState();
}

class _TtsAutoReadToggleTileState extends State<_TtsAutoReadToggleTile> {
  bool _enabled = TtsService.instance.isAutoRead;

  Future<void> _toggle(bool value) async {
    await TtsService.instance.setAutoRead(value);
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!TtsService.instance.isEnabled) return const SizedBox.shrink();
    return TapScale(
      onTap: () => _toggle(!_enabled),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, top: 2, bottom: 14),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF14B8A6).withValues(alpha: 0.05),
              ),
              child: Icon(
                Icons.auto_mode,
                size: 15,
                color: _enabled
                    ? const Color(0xFF14B8A6)
                    : Colors.white60,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Auto-read answers',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch.adaptive(
              value: _enabled,
              onChanged: _toggle,
              activeTrackColor: const Color(0xFF14B8A6),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI Data Processing consent toggle.
class _AiDataToggleTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AiDataToggleTile> createState() => _AiDataToggleTileState();
}

class _AiDataToggleTileState extends ConsumerState<_AiDataToggleTile> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    // Try cache first
    final cached = ref.read(aiConsentCacheProvider);
    if (cached != null) {
      if (mounted) setState(() { _enabled = cached; _loading = false; });
      return;
    }
    // Load from DB
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('ai_consent_accepted')
          .eq('id', user.id)
          .maybeSingle();
      final value = profile?['ai_consent_accepted'] as bool? ?? false;
      ref.read(aiConsentCacheProvider.notifier).state = value;
      if (mounted) setState(() { _enabled = value; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(bool value) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (value) {
      // Re-show consent dialog when re-enabling
      final accepted = await AiConsentDialog.show(context);
      if (!accepted) return;
    }

    await Supabase.instance.client.from('profiles').update({
      'ai_consent_accepted': value,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    ref.read(aiConsentCacheProvider.notifier).state = value;
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () => _toggle(!_enabled),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                _enabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                size: 18,
                color: _enabled
                    ? AppColors.primary
                    : Colors.white60,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Data Processing',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _enabled ? 'Allowed' : 'Not allowed',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch.adaptive(
                value: _enabled,
                onChanged: _toggle,
                activeTrackColor: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Theme / Appearance toggle tile — System / Light / Dark.
class _ThemeToggleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final label = switch (themeMode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

    final icon = switch (themeMode) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };

    return TapScale(
      onTap: () => _showThemePicker(context, ref, themeMode),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.immersiveCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance',
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ThemeOption(
                icon: Icons.brightness_auto,
                label: 'System',
                subtitle: 'Match device settings',
                isSelected: current == ThemeMode.system,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                  Navigator.of(ctx).pop();
                },
              ),
              _ThemeOption(
                icon: Icons.light_mode,
                label: 'Light',
                subtitle: 'Always use light theme',
                isSelected: current == ThemeMode.light,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                  Navigator.of(ctx).pop();
                },
              ),
              _ThemeOption(
                icon: Icons.dark_mode,
                label: 'Dark',
                subtitle: 'Always use dark theme',
                isSelected: current == ThemeMode.dark,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual theme option in the bottom sheet picker.
class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : Colors.white60,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Settings list tile — immersive dark.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: Colors.white60,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
