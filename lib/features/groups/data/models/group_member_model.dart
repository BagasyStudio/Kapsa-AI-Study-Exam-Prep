/// Model representing a member of a study group.
class GroupMemberModel {
  final String id;
  final String groupId;
  final String userId;
  final String role;
  final DateTime? joinedAt;
  final String? fullName;
  final int? xpTotal;

  const GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,
    this.role = 'member',
    this.joinedAt,
    this.fullName,
    this.xpTotal,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    // Handle joined profile data
    final profile = json['profiles'] as Map<String, dynamic>?;
    return GroupMemberModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      fullName: profile?['full_name'] as String?,
      xpTotal: profile?['xp_total'] as int?,
    );
  }
}
