/// Data model for a Snap & Solve solution.
class SnapSolutionModel {
  final String? id;
  final String userId;
  final String? courseId;
  final String imageUrl;
  final String? problemText;
  final String? subject;
  final SolutionData solution;
  final DateTime? createdAt;
  final bool saved;

  const SnapSolutionModel({
    this.id,
    required this.userId,
    this.courseId,
    required this.imageUrl,
    this.problemText,
    this.subject,
    required this.solution,
    this.createdAt,
    this.saved = true,
  });

  factory SnapSolutionModel.fromJson(Map<String, dynamic> json) {
    // The solution can come as:
    // 1. Nested inside 'solution' key (from DB row)
    // 2. Flat at root level (from edge function response)
    final solutionJson = json['solution'] is Map<String, dynamic>
        ? json['solution'] as Map<String, dynamic>
        : json; // fallback: treat root as solution data

    return SnapSolutionModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String? ?? '',
      courseId: json['course_id'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
      problemText: json['problem_text'] as String? ?? solutionJson['problem'] as String?,
      subject: json['subject'] as String? ?? solutionJson['subject'] as String?,
      solution: SolutionData.fromJson(solutionJson),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      saved: json['saved'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        if (courseId != null) 'course_id': courseId,
        'image_url': imageUrl,
        'problem_text': problemText,
        'subject': subject,
        'solution': solution.toJson(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  SnapSolutionModel copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? imageUrl,
    String? problemText,
    String? subject,
    SolutionData? solution,
    DateTime? createdAt,
    bool? saved,
  }) =>
      SnapSolutionModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        courseId: courseId ?? this.courseId,
        imageUrl: imageUrl ?? this.imageUrl,
        problemText: problemText ?? this.problemText,
        subject: subject ?? this.subject,
        solution: solution ?? this.solution,
        createdAt: createdAt ?? this.createdAt,
        saved: saved ?? this.saved,
      );
}

/// Structured solution data returned by the AI.
class SolutionData {
  final String problem;
  final String subject;
  final List<SolutionStep> steps;
  final String finalAnswer;
  final String explanation;

  const SolutionData({
    required this.problem,
    required this.subject,
    required this.steps,
    required this.finalAnswer,
    required this.explanation,
  });

  factory SolutionData.fromJson(Map<String, dynamic> json) {
    final stepsRaw = json['steps'] as List<dynamic>? ?? [];
    return SolutionData(
      problem: json['problem'] as String? ?? '',
      subject: json['subject'] as String? ?? 'Other',
      steps: stepsRaw
          .map((s) => SolutionStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      finalAnswer: json['final_answer'] as String? ??
          json['finalAnswer'] as String? ??
          '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'problem': problem,
        'subject': subject,
        'steps': steps.map((s) => s.toJson()).toList(),
        'final_answer': finalAnswer,
        'explanation': explanation,
      };
}

/// A single step in the solution.
class SolutionStep {
  final int step;
  final String title;
  final String content;
  final String? formula;

  const SolutionStep({
    required this.step,
    required this.title,
    required this.content,
    this.formula,
  });

  factory SolutionStep.fromJson(Map<String, dynamic> json) {
    return SolutionStep(
      step: json['step'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      formula: json['formula'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'step': step,
        'title': title,
        'content': content,
        'formula': formula,
      };
}
