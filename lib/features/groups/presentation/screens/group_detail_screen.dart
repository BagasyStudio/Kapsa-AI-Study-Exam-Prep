import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/providers/theme_provider.dart';
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
    final brightness = Theme.of(context).brightness;
    final isDark = context.isDark;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      body: SafeArea(
        child: groupAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
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
                            color: AppColors.textPrimaryFor(brightness)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: AppTypography.h3.copyWith(
                                color: AppColors.textPrimaryFor(brightness),
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
                                  color: AppColors.textMutedFor(brightness),
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
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.5),
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
                    unselectedLabelColor: AppColors.textMutedFor(brightness),
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
    final brightness = Theme.of(context).brightness;

    return activitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (activities) {
        if (activities.isEmpty) {
          return Center(
            child: Text(
              'No activity yet.\nStart studying to share progress!',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedFor(brightness),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          itemCount: activities.length,
          itemBuilder: (context, index) =>
              ActivityFeedItem(activity: activities[index]),
        );
      },
    );
  }
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (members) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          itemCount: members.length,
          itemBuilder: (context, index) => LeaderboardRow(
            member: members[index],
            rank: index + 1,
            isCurrentUser: members[index].userId == currentUserId,
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
    final brightness = Theme.of(context).brightness;

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (members) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return Container(
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
                            color: AppColors.textPrimaryFor(brightness),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          member.role == 'owner' ? 'Owner' : 'Member',
                          style: AppTypography.caption.copyWith(
                            color: member.role == 'owner'
                                ? AppColors.primary
                                : AppColors.textMutedFor(brightness),
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
            );
          },
        );
      },
    );
  }
}
