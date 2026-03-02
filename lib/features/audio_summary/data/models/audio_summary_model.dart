/// Model representing an audio summary record.
class AudioSummaryModel {
  final String id;
  final String userId;
  final String materialId;
  final String courseId;
  final String title;
  final String audioUrl;
  final int? durationSeconds;
  final String? summaryText;
  final String status;
  final DateTime? createdAt;

  const AudioSummaryModel({
    required this.id,
    required this.userId,
    required this.materialId,
    required this.courseId,
    required this.title,
    required this.audioUrl,
    this.durationSeconds,
    this.summaryText,
    this.status = 'ready',
    this.createdAt,
  });

  factory AudioSummaryModel.fromJson(Map<String, dynamic> json) {
    return AudioSummaryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      materialId: json['material_id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      audioUrl: json['audio_url'] as String? ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      summaryText: json['summary_text'] as String?,
      status: json['status'] as String? ?? 'ready',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Whether this summary has playable audio.
  bool get hasAudio => audioUrl.isNotEmpty && status == 'ready';

  /// Formatted duration like "2:45".
  String get formattedDuration {
    if (durationSeconds == null) return '--:--';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
