/// Model representing an activity event in a study group feed.
class GroupActivityModel {
  final String id;
  final String groupId;
  final String userId;
  final String activityType;
  final String title;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final String? userName;

  const GroupActivityModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.activityType,
    required this.title,
    this.metadata = const {},
    this.createdAt,
    this.userName,
  });

  factory GroupActivityModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return GroupActivityModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      activityType: json['activity_type'] as String,
      title: json['title'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      userName: profile?['full_name'] as String?,
    );
  }

  /// Time ago string for display.
  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
