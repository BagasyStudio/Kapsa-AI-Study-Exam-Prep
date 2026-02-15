/// Model representing a chat message from the `chat_messages` table.
class ChatMessageModel {
  final String id;
  final String sessionId;
  final String role; // 'user' or 'assistant'
  final String content;
  final List<String> citations;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.citations = const [],
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      citations: (json['citations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'role': role,
      'content': content,
      'citations': citations,
    };
  }

  /// Whether this message was sent by the user.
  bool get isUser => role == 'user';

  /// Formatted timestamp for display.
  String? get timestamp {
    if (createdAt == null) return null;
    final hour = createdAt!.hour;
    final minute = createdAt!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }
}
