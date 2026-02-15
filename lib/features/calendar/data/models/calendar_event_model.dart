/// Model representing a calendar event from the `calendar_events` table.
class CalendarEventModel {
  final String id;
  final String userId;
  final String? courseId;
  final String title;
  final String type; // 'exam', 'task', 'suggestion'
  final DateTime startTime;
  final DateTime? endTime;
  final String? description;
  final bool isCompleted;
  final String? aiSuggestion;
  final DateTime? createdAt;

  const CalendarEventModel({
    required this.id,
    required this.userId,
    this.courseId,
    required this.title,
    required this.type,
    required this.startTime,
    this.endTime,
    this.description,
    this.isCompleted = false,
    this.aiSuggestion,
    this.createdAt,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String?,
      title: json['title'] as String,
      type: json['type'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      aiSuggestion: json['ai_suggestion'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'course_id': courseId,
      'title': title,
      'type': type,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'description': description,
      'is_completed': isCompleted,
      'ai_suggestion': aiSuggestion,
    };
  }

  CalendarEventModel copyWith({
    String? courseId,
    String? title,
    String? type,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    bool? isCompleted,
    String? aiSuggestion,
  }) {
    return CalendarEventModel(
      id: id,
      userId: userId,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      aiSuggestion: aiSuggestion ?? this.aiSuggestion,
      createdAt: createdAt,
    );
  }

  /// Whether this is an exam event.
  bool get isExam => type == 'exam';

  /// Whether this is an AI suggestion.
  bool get isSuggestion => type == 'suggestion';

  /// Formatted time string (e.g. "10:00").
  String get timeLabel {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  /// Formatted time range (e.g. "10:00 - 12:00").
  String get timeRange {
    final start = timeLabel;
    if (endTime == null) return start;
    final end =
        '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}
