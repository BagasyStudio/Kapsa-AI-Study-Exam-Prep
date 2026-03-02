import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/widgets/empty_state.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: TextStyle(color: AppColors.textMutedFor(brightness))),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.groups_rounded,
                title: 'No groups yet',
                subtitle:
                    'Create a study group or join one with an invite code.',
                ctaLabel: 'Create Group',
                onCtaTap: () => context.push(Routes.createGroup),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: groups.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final group = groups[index];
              return GroupCard(
                group: group,
                onTap: () =>
                    context.push(Routes.groupDetailPath(group.id)),
              );
            },
          );
        },
      ),
    );
  }
}
