/// Model representing a single XP event from the `xp_events` table.
class XpEventModel {
  final String id;
  final String userId;
  final String action;
  final int xpAmount;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const XpEventModel({
    required this.id,
    required this.userId,
    required this.action,
    required this.xpAmount,
    this.metadata = const {},
    required this.createdAt,
  });

  factory XpEventModel.fromJson(Map<String, dynamic> json) {
    return XpEventModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      action: json['action'] as String,
      xpAmount: (json['xp_amount'] as num).toInt(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'action': action,
        'xp_amount': xpAmount,
        'metadata': metadata,
      };
}
