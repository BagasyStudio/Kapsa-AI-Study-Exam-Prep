import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/group_repository.dart';
import '../../data/models/group_model.dart';
import '../../data/models/group_member_model.dart';
import '../../data/models/group_activity_model.dart';

/// Repository provider.
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(supabaseClientProvider));
});

/// All groups the user belongs to.
final myGroupsProvider =
    FutureProvider.autoDispose<List<GroupModel>>((ref) async {
  return ref.watch(groupRepositoryProvider).getMyGroups();
});

/// Members of a specific group.
final groupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMemberModel>, String>((ref, groupId) async {
  return ref.watch(groupRepositoryProvider).getMembers(groupId);
});

/// Activity feed for a group.
final groupActivitiesProvider = FutureProvider.autoDispose
    .family<List<GroupActivityModel>, String>((ref, groupId) async {
  return ref.watch(groupRepositoryProvider).getActivities(groupId);
});

/// Leaderboard for a group.
final groupLeaderboardProvider = FutureProvider.autoDispose
    .family<List<GroupMemberModel>, String>((ref, groupId) async {
  return ref.watch(groupRepositoryProvider).getLeaderboard(groupId);
});

/// Single group details.
final groupDetailProvider = FutureProvider.autoDispose
    .family<GroupModel?, String>((ref, groupId) async {
  return ref.watch(groupRepositoryProvider).getGroup(groupId);
});
