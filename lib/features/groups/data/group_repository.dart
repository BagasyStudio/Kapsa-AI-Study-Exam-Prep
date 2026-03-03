import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/group_model.dart';
import 'models/group_member_model.dart';
import 'models/group_activity_model.dart';

/// Repository for study group operations.
class GroupRepository {
  final SupabaseClient _client;

  GroupRepository(this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('No authenticated user');
    return user.id;
  }

  // ── Groups CRUD ──

  /// Create a new study group.
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    final data = await _client
        .from('study_groups')
        .insert({
          'name': name,
          'description': description,
          'owner_id': _userId,
          'is_public': isPublic,
        })
        .select()
        .single();

    final group = GroupModel.fromJson(data);

    // Add owner as first member with 'owner' role
    await _client.from('group_members').insert({
      'group_id': group.id,
      'user_id': _userId,
      'role': 'owner',
    });

    return group;
  }

  /// Get all groups the current user is a member of.
  Future<List<GroupModel>> getMyGroups() async {
    final memberships = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', _userId);

    final groupIds =
        (memberships as List).map((m) => m['group_id'] as String).toList();

    if (groupIds.isEmpty) return [];

    final data = await _client
        .from('study_groups')
        .select()
        .inFilter('id', groupIds)
        .order('created_at', ascending: false);

    return (data as List).map((e) => GroupModel.fromJson(e)).toList();
  }

  /// Get a single group by ID.
  Future<GroupModel?> getGroup(String groupId) async {
    final data = await _client
        .from('study_groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();

    return data != null ? GroupModel.fromJson(data) : null;
  }

  /// Delete a group (owner only).
  Future<void> deleteGroup(String groupId) async {
    await _client.from('study_groups').delete().eq('id', groupId);
  }

  // ── Membership ──

  /// Join a group via invite code.
  Future<GroupModel> joinByCode(String inviteCode) async {
    final data = await _client
        .from('study_groups')
        .select()
        .eq('invite_code', inviteCode.trim().toLowerCase())
        .maybeSingle();

    if (data == null) throw Exception('Invalid invite code');

    final group = GroupModel.fromJson(data);

    // Check if already member
    final existing = await _client
        .from('group_members')
        .select('id')
        .eq('group_id', group.id)
        .eq('user_id', _userId)
        .maybeSingle();

    if (existing != null) throw Exception('You are already a member');

    // Join
    await _client.from('group_members').insert({
      'group_id': group.id,
      'user_id': _userId,
      'role': 'member',
    });

    // Post activity
    await postActivity(
      groupId: group.id,
      type: 'member_joined',
      title: 'joined the group',
    );

    return group;
  }

  /// Leave a group.
  Future<void> leaveGroup(String groupId) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', _userId);
  }

  /// Get members of a group with profile info.
  Future<List<GroupMemberModel>> getMembers(String groupId) async {
    final data = await _client
        .from('group_members')
        .select('*, profiles(full_name, xp_total)')
        .eq('group_id', groupId)
        .order('joined_at', ascending: true);

    return (data as List).map((e) => GroupMemberModel.fromJson(e)).toList();
  }

  // ── Activity Feed ──

  /// Post an activity to the group feed.
  Future<void> postActivity({
    required String groupId,
    required String type,
    required String title,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('group_activities').insert({
      'group_id': groupId,
      'user_id': _userId,
      'activity_type': type,
      'title': title,
      if (metadata != null) 'metadata': metadata,
    });
  }

  /// Get recent activity feed for a group.
  Future<List<GroupActivityModel>> getActivities(String groupId,
      {int limit = 30}) async {
    final data = await _client
        .from('group_activities')
        .select('*, profiles(full_name)')
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => GroupActivityModel.fromJson(e))
        .toList();
  }

  // ── Leaderboard ──

  /// Get leaderboard (members sorted by XP).
  Future<List<GroupMemberModel>> getLeaderboard(String groupId) async {
    final data = await _client
        .from('group_members')
        .select('*, profiles(full_name, xp_total)')
        .eq('group_id', groupId);

    final members =
        (data as List).map((e) => GroupMemberModel.fromJson(e)).toList();

    // Sort by XP descending
    members.sort((a, b) => (b.xpTotal ?? 0).compareTo(a.xpTotal ?? 0));
    return members;
  }
}
