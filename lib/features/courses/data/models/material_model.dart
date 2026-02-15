/// Model representing a course material from the `course_materials` table.
class MaterialModel {
  final String id;
  final String courseId;
  final String userId;
  final String title;
  final String type; // 'pdf', 'audio', 'notes', 'paste'
  final String? content;
  final String? fileUrl;
  final int? fileSize;
  final int? durationSeconds;
  final bool isReviewed;
  final DateTime? createdAt;

  const MaterialModel({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.title,
    required this.type,
    this.content,
    this.fileUrl,
    this.fileSize,
    this.durationSeconds,
    this.isReviewed = false,
    this.createdAt,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      content: json['content'] as String?,
      fileUrl: json['file_url'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      isReviewed: json['is_reviewed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'user_id': userId,
      'title': title,
      'type': type,
      'content': content,
      'file_url': fileUrl,
      'file_size': fileSize,
      'duration_seconds': durationSeconds,
      'is_reviewed': isReviewed,
    };
  }

  MaterialModel copyWith({
    String? title,
    String? type,
    String? content,
    String? fileUrl,
    int? fileSize,
    int? durationSeconds,
    bool? isReviewed,
  }) {
    return MaterialModel(
      id: id,
      courseId: courseId,
      userId: userId,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isReviewed: isReviewed ?? this.isReviewed,
      createdAt: createdAt,
    );
  }

  /// Human-readable label for the material type.
  String get typeLabel {
    switch (type) {
      case 'pdf':
        return 'PDF';
      case 'audio':
        return 'Audio';
      case 'notes':
        return 'Note';
      case 'paste':
        return 'Paste';
      default:
        return type.toUpperCase();
    }
  }

  /// Human-readable size or duration label.
  String get sizeLabel {
    if (type == 'audio' && durationSeconds != null) {
      final minutes = durationSeconds! ~/ 60;
      return '$minutes min';
    }
    if (fileSize != null) {
      if (fileSize! > 1024 * 1024) {
        return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(fileSize! / 1024).toStringAsFixed(0)} KB';
    }
    return '';
  }
}
