import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_functions.dart';
import 'models/test_model.dart';
import 'models/test_question_model.dart';

/// Combined result of a test with its questions.
class TestWithQuestions {
  final TestModel test;
  final List<TestQuestionModel> questions;

  const TestWithQuestions({required this.test, required this.questions});
}

/// Repository for test/quiz operations.
class TestRepository {
  final SupabaseClient _client;
  final SupabaseFunctions _functions;

  TestRepository(this._client, this._functions);

  /// Generate a quiz via Edge Function.
  ///
  /// If [count] is omitted, the edge function auto-calculates an optimal
  /// number of questions based on the total content length.
  Future<TestWithQuestions> generateQuiz({
    required String courseId,
    int? count,
    bool isPracticeExam = false,
  }) async {
    final response = await _functions.invoke(
      'ai-generate-quiz',
      body: {
        'action': 'generate',
        'courseId': courseId,
        if (count != null) 'count': count,
        'isPracticeExam': isPracticeExam,
      },
    );

    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from quiz generation');
    }
    final test = TestModel.fromJson(data['test'] as Map<String, dynamic>);
    final questions = (data['questions'] as List)
        .map((e) => TestQuestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return TestWithQuestions(test: test, questions: questions);
  }

  /// Submit answers and get AI evaluation via Edge Function.
  Future<TestWithQuestions> submitAnswers({
    required String testId,
    required List<Map<String, String>> answers,
  }) async {
    final response = await _functions.invoke(
      'ai-generate-quiz',
      body: {
        'action': 'evaluate',
        'testId': testId,
        'answers': answers,
      },
    );

    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from quiz evaluation');
    }
    final test = TestModel.fromJson(data['test'] as Map<String, dynamic>);
    final questions = (data['questions'] as List)
        .map((e) => TestQuestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return TestWithQuestions(test: test, questions: questions);
  }

  /// Get AI-generated explanation of mistakes for a completed test.
  ///
  /// Returns a map with `explanation`, `weakTopics`, and `studyTips`.
  Future<Map<String, dynamic>> explainMistakes({
    required String testId,
  }) async {
    final response = await _functions.invoke(
      'ai-generate-quiz',
      body: {
        'action': 'explain_mistakes',
        'testId': testId,
      },
    );

    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from explain mistakes');
    }
    return data;
  }

  /// Fetch test results with questions.
  Future<TestWithQuestions> getTestResults(String testId) async {
    final testData = await _client
        .from('tests')
        .select()
        .eq('id', testId)
        .single();
    final questionsData = await _client
        .from('test_questions')
        .select()
        .eq('test_id', testId)
        .order('question_number', ascending: true);

    return TestWithQuestions(
      test: TestModel.fromJson(testData),
      questions: (questionsData as List)
          .map((e) => TestQuestionModel.fromJson(e))
          .toList(),
    );
  }

  /// Fetch all tests for a course.
  Future<List<TestModel>> getTestsForCourse(String courseId) async {
    final data = await _client
        .from('tests')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => TestModel.fromJson(e)).toList();
  }
}
