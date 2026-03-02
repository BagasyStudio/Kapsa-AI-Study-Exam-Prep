/// Model representing a study group.
class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String inviteCode;
  final String ownerId;
  final int maxMembers;
  final bool isPublic;
  final DateTime? createdAt;
  final int? memberCount;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.ownerId,
    this.maxMembers = 20,
    this.isPublic = false,
    this.createdAt,
    this.memberCount,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      inviteCode: json['invite_code'] as String? ?? '',
      ownerId: json['owner_id'] as String,
      maxMembers: json['max_members'] as int? ?? 20,
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      memberCount: json['member_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'owner_id': ownerId,
        'max_members': maxMembers,
        'is_public': isPublic,
      };
}
