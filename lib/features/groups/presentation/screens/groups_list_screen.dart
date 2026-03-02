import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_button.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../providers/groups_provider.dart';
import '../widgets/group_card.dart';

/// Screen listing all study groups the user belongs to.
class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: AppColors.textPrimaryFor(brightness)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Study Groups',
          style: AppTypography.h2.copyWith(
            color: AppColors.textPrimaryFor(brightness),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TapScale(
            onTap: () => context.push(Routes.joinGroup),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.login, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Join',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TapScale(
            onTap: () => context.push(Routes.createGroup),
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'New',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: ShimmerList(count: 3, itemHeight: 90),
        ),
        error: (e, _) => Center(
          child: EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load groups',
            subtitle: 'Check your connection and try again.',
            ctaLabel: 'Retry',
            onCtaTap: () => ref.invalidate(myGroupsProvider),
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return _GroupsEmptyState(brightness: brightness);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: groups.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final group = groups[index];
              return EntranceAnimation(
                index: index,
                child: GroupCard(
                  group: group,
                  onTap: () =>
                      context.push(Routes.groupDetailPath(group.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Engaging empty state shown when the user has no groups.
///
/// Features a gradient icon container, descriptive copy, and two
/// full-width CTA buttons (create + join).
class _GroupsEmptyState extends StatefulWidget {
  final Brightness brightness;

  const _GroupsEmptyState({required this.brightness});

  @override
  State<_GroupsEmptyState> createState() => _GroupsEmptyStateState();
}

class _GroupsEmptyStateState extends State<_GroupsEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // -- Animated icon with gradient background --
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.primary.withValues(alpha: 0.35),
                            const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                          ]
                        : [
                            AppColors.primary.withValues(alpha: 0.15),
                            const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // -- Title --
            Text(
              'Study better together',
              textAlign: TextAlign.center,
              style: AppTypography.h2.copyWith(
                color: AppColors.textPrimaryFor(widget.brightness),
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // -- Subtitle --
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                'Create a study group or join one with an invite code '
                'to share progress and compete with classmates',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryFor(widget.brightness),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // -- Social proof lines --
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: AppColors.textSecondaryFor(widget.brightness)
                      .withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  '2,400+ students in study groups',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryFor(widget.brightness)
                        .withValues(alpha: 0.6),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\u{1F4C8}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 6),
                Text(
                  'Groups study 40% more effectively',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryFor(widget.brightness)
                        .withValues(alpha: 0.6),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),

            // -- Primary CTA: Create Group --
            SizedBox(
              width: double.infinity,
              child: ShimmerButton(
                label: 'Create Group',
                icon: Icons.add_rounded,
                gradientColors: const [
                  Color(0xFF6467F2),
                  Color(0xFF8B5CF6),
                ],
                onPressed: () => context.push(Routes.createGroup),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // -- Secondary CTA: Join with Code --
            SizedBox(
              width: double.infinity,
              child: TapScale(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(Routes.joinGroup);
                },
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.primary.withValues(alpha: 0.04),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Join with Code',
                        style: AppTypography.button.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
