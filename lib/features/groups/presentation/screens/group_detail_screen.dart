import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/xp_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../../sharing/data/milestone_service.dart';
import '../../../sharing/presentation/widgets/share_preview_sheet.dart';
import '../../../sharing/presentation/widgets/micro_cards/leaderboard_position_card.dart';
import '../../data/models/group_member_model.dart';
import '../providers/groups_provider.dart';
import '../widgets/activity_feed_item.dart';
import '../widgets/leaderboard_row.dart';

/// Detail screen for a study group with tabs: Feed, Leaderboard, Members.
class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite code copied!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: SafeArea(
        child: groupAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: ShimmerList(count: 4, itemHeight: 70),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                AppErrorHandler.friendlyMessage(e),
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white38,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (group) {
            if (group == null) {
              return const Center(child: Text('Group not found'));
            }
            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: AppTypography.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (group.description != null &&
                                group.description!.isNotEmpty)
                              Text(
                                group.description!,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white38,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      TapScale(
                        onTap: () => _copyInviteCode(group.inviteCode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.copy,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                group.inviteCode,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    labelStyle: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Feed'),
                      Tab(text: 'Leaderboard'),
                      Tab(text: 'Members'),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _FeedTab(groupId: widget.groupId),
                      _LeaderboardTab(
                        groupId: widget.groupId,
                        currentUserId: currentUserId ?? '',
                      ),
                      _MembersTab(
                        groupId: widget.groupId,
                        isOwner: group.ownerId == currentUserId,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  final String groupId;

  const _FeedTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(groupActivitiesProvider(groupId));

    return activitiesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: ShimmerList(count: 5, itemHeight: 72),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            AppErrorHandler.friendlyMessage(e),
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white38,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (activities) {
        if (activities.isEmpty) {
          return Center(
            child: Text(
              'No activity yet.\nStart studying to share progress!',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white38,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          itemCount: activities.length,
          itemBuilder: (context, index) => EntranceAnimation(
            index: index,
            child: ActivityFeedItem(activity: activities[index]),
          ),
        );
      },
    );
  }
}

void _maybeShowLeaderboardShare(
  BuildContext context,
  WidgetRef ref,
  GroupMemberModel topMember,
  String groupId,
) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final milestone =
          await MilestoneService.checkMilestone('leaderboard_1', groupId);
      if (milestone == null) return;
      if (!context.mounted) return;

      await MilestoneService.markShown('leaderboard_1', groupId);

      final profile =
          ref.read(profileProvider).whenOrNull(data: (p) => p);
      final totalXp =
          ref.read(xpTotalProvider).whenOrNull(data: (v) => v) ?? 0;
      final xpLevel = XpConfig.levelFromXp(totalXp);

      final group = ref
          .read(groupDetailProvider(groupId))
          .whenOrNull(data: (g) => g);

      if (!context.mounted) return;
      SharePreviewSheet.show(
        context,
        shareCard: LeaderboardPositionCard(
          position: 1,
          groupName: group?.name ?? 'Study Group',
          totalXp: topMember.xpTotal ?? totalXp,
          userName: profile?.firstName ?? 'Student',
          xpLevel: xpLevel,
        ),
        shareType: 'leaderboard_position',
        referenceId: groupId,
      );
    } catch (e) {
      debugPrint('GroupDetail: show leaderboard share failed: $e');
    }
  });
}

class _LeaderboardTab extends ConsumerWidget {
  final String groupId;
  final String currentUserId;

  const _LeaderboardTab({
    required this.groupId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(groupLeaderboardProvider(groupId));

    return leaderboardAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: ShimmerList(count: 5, itemHeight: 56),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            AppErrorHandler.friendlyMessage(e),
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white38,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (members) {
        // Check if current user is #1 and prompt share
        if (members.isNotEmpty && members[0].userId == currentUserId) {
          _maybeShowLeaderboardShare(context, ref, members[0], groupId);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          itemCount: members.length,
          itemBuilder: (context, index) => EntranceAnimation(
            index: index,
            child: LeaderboardRow(
              member: members[index],
              rank: index + 1,
              isCurrentUser: members[index].userId == currentUserId,
            ),
          ),
        );
      },
    );
  }
}

class _MembersTab extends ConsumerWidget {
  final String groupId;
  final bool isOwner;

  const _MembersTab({required this.groupId, required this.isOwner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return membersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: ShimmerList(count: 4, itemHeight: 56),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            AppErrorHandler.friendlyMessage(e),
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white38,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (members) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return EntranceAnimation(
              index: index,
              child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      (member.fullName ?? '?')[0].toUpperCase(),
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.fullName ?? 'Member',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          member.role == 'owner' ? 'Owner' : 'Member',
                          style: AppTypography.caption.copyWith(
                            color: member.role == 'owner'
                                ? AppColors.primary
                                : Colors.white38,
                            fontWeight: member.role == 'owner'
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }
}
