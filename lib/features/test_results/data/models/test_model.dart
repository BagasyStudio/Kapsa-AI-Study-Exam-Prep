/// Model representing a test from the `tests` table.
class TestModel {
  final String id;
  final String courseId;
  final String userId;
  final String? title;
  final double? score; // 0.0 to 1.0
  final String? grade; // 'A+', 'B', 'F', etc.
  final int correctCount;
  final int totalCount;
  final String? motivationText;
  final bool isPracticeExam;
  final String status; // 'in_progress' | 'completed'
  final int currentQuestion; // 0-based index of last visited question
  final DateTime? createdAt;

  const TestModel({
    required this.id,
    required this.courseId,
    required this.userId,
    this.title,
    this.score,
    this.grade,
    this.correctCount = 0,
    this.totalCount = 0,
    this.motivationText,
    this.isPracticeExam = false,
    this.status = 'completed',
    this.currentQuestion = 0,
    this.createdAt,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      grade: json['grade'] as String?,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      motivationText: json['motivation_text'] as String?,
      isPracticeExam: json['is_practice_exam'] as bool? ?? false,
      status: json['status'] as String? ?? 'completed',
      currentQuestion: (json['current_question'] as num?)?.toInt() ?? 0,
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
      'score': score,
      'grade': grade,
      'correct_count': correctCount,
      'total_count': totalCount,
      'motivation_text': motivationText,
      'is_practice_exam': isPracticeExam,
      'status': status,
      'current_question': currentQuestion,
    };
  }

  TestModel copyWith({
    String? title,
    double? score,
    String? grade,
    int? correctCount,
    int? totalCount,
    String? motivationText,
    bool? isPracticeExam,
    String? status,
    int? currentQuestion,
  }) {
    return TestModel(
      id: id,
      courseId: courseId,
      userId: userId,
      title: title ?? this.title,
      score: score ?? this.score,
      grade: grade ?? this.grade,
      correctCount: correctCount ?? this.correctCount,
      totalCount: totalCount ?? this.totalCount,
      motivationText: motivationText ?? this.motivationText,
      isPracticeExam: isPracticeExam ?? this.isPracticeExam,
      status: status ?? this.status,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      createdAt: createdAt,
    );
  }

  /// Whether this quiz is still in progress (not yet submitted).
  bool get isInProgress => status == 'in_progress';

  /// The number of mistakes.
  int get mistakeCount => totalCount - correctCount;

  /// Display percentage (e.g. 60).
  int get percentage => score != null ? (score! * 100).round() : 0;
}
