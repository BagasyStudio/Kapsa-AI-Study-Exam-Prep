import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/session_manager.dart';
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

  TestRepository(this._client);

  /// Generate a quiz via Edge Function.
  Future<TestWithQuestions> generateQuiz({
    required String courseId,
    int count = 5,
  }) async {
    try { await SessionManager.refreshIfNeeded(_client); } catch (_) {}
    final response = await _client.functions.invoke(
      'ai-generate-quiz',
      body: {
        'action': 'generate',
        'courseId': courseId,
        'count': count,
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
    try { await SessionManager.refreshIfNeeded(_client); } catch (_) {}
    final response = await _client.functions.invoke(
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
