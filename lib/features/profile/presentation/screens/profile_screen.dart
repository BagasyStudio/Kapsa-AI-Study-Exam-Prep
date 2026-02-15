import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/revenue_cat_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Sign Out',
          style: AppTypography.h3.copyWith(
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTypography.bodyMedium.copyWith(
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authRepositoryProvider).signOut();
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
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Ambient orbs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC084FC).withValues(alpha: 0.1),
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
                        color: AppColors.textSecondary,
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
                            color: Colors.white,
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
                          color: const Color(0xFF0F172A),
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayEmail,
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFF64748B),
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

                      // Settings section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SETTINGS',
                              style: AppTypography.sectionHeader,
                            ),
                            const SizedBox(height: AppSpacing.md),

                            _SettingsTile(
                              icon: Icons.notifications_outlined,
                              label: 'Notifications',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notifications settings coming soon')),
                                );
                              },
                            ),
                            _SettingsTile(
                              icon: Icons.palette_outlined,
                              label: 'Appearance',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Appearance settings coming soon')),
                                );
                              },
                            ),
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
                                color: const Color(0xFF94A3B8).withValues(alpha: 0.2),
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
                                onTap: () => _showSignOutDialog(context, ref),
                                child: Text(
                                  'Sign Out',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: const Color(0xFF64748B),
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
                                      color: const Color(0xFF94A3B8).withValues(alpha: 0.6),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
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
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All features unlocked',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF64748B),
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
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return TapScale(
      onTap: () => context.push(Routes.paywall),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  const Color(0xFF6366F1).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
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
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Unlock AI Oracle & Smart Study Plans',
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFF64748B),
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
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            fontSize: 13,
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFF94A3B8).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Glass stat card for profile stats.
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: AppTypography.h3.copyWith(
                  color: const Color(0xFF0F172A),
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings list tile with glass style.
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
                color: Colors.white.withValues(alpha: 0.5),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
