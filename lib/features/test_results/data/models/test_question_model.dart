/// Model representing a test question from the `test_questions` table.
class TestQuestionModel {
  final String id;
  final String testId;
  final int questionNumber;
  final String question;
  final String? userAnswer;
  final String correctAnswer;
  final String? aiInsight;
  final bool isCorrect;
  final DateTime? createdAt;

  const TestQuestionModel({
    required this.id,
    required this.testId,
    required this.questionNumber,
    required this.question,
    this.userAnswer,
    required this.correctAnswer,
    this.aiInsight,
    this.isCorrect = false,
    this.createdAt,
  });

  factory TestQuestionModel.fromJson(Map<String, dynamic> json) {
    return TestQuestionModel(
      id: json['id'] as String,
      testId: json['test_id'] as String,
      questionNumber: (json['question_number'] as num).toInt(),
      question: json['question'] as String,
      userAnswer: json['user_answer'] as String?,
      correctAnswer: json['correct_answer'] as String,
      aiInsight: json['ai_insight'] as String?,
      isCorrect: json['is_correct'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'test_id': testId,
      'question_number': questionNumber,
      'question': question,
      'user_answer': userAnswer,
      'correct_answer': correctAnswer,
      'ai_insight': aiInsight,
      'is_correct': isCorrect,
    };
  }

  TestQuestionModel copyWith({
    String? userAnswer,
    String? aiInsight,
    bool? isCorrect,
  }) {
    return TestQuestionModel(
      id: id,
      testId: testId,
      questionNumber: questionNumber,
      question: question,
      userAnswer: userAnswer ?? this.userAnswer,
      correctAnswer: correctAnswer,
      aiInsight: aiInsight ?? this.aiInsight,
      isCorrect: isCorrect ?? this.isCorrect,
      createdAt: createdAt,
    );
  }
}
