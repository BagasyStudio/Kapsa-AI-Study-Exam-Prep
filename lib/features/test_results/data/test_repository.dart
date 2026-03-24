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

/// An in-progress quiz with its course name, for the home resume banner.
class InProgressQuiz {
  final TestModel test;
  final String courseName;

  const InProgressQuiz({required this.test, required this.courseName});

  /// Number of questions answered so far.
  int get answeredCount => test.currentQuestion;

  /// Progress fraction (0.0 to 1.0).
  double get progress =>
      test.totalCount > 0 ? answeredCount / test.totalCount : 0.0;

  /// Motivational text based on progress.
  String get motivationText {
    final pct = progress;
    if (pct <= 0.3) return 'You just started! Keep going';
    if (pct <= 0.7) return "You're on fire! Don't stop now";
    return 'Almost there! Finish strong';
  }

  /// Emoji matching the motivation level.
  String get motivationEmoji {
    final pct = progress;
    if (pct <= 0.3) return '\u{1F4AA}'; // 💪
    if (pct <= 0.7) return '\u{1F525}'; // 🔥
    return '\u{1F3C6}'; // 🏆
  }
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
    List<String>? focusTopics,
    String? materialId,
  }) async {
    final response = await _functions.invoke(
      'ai-generate-quiz',
      body: {
        'action': 'generate',
        'courseId': courseId,
        if (count != null) 'count': count,
        'isPracticeExam': isPracticeExam,
        if (focusTopics != null && focusTopics.isNotEmpty)
          'focusTopics': focusTopics,
        if (materialId != null) 'materialId': materialId,
      },
    );

    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from quiz generation');
    }
    if (data['test'] == null || data['questions'] == null) {
      throw Exception('Missing test or questions in quiz response');
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
        .maybeSingle();
    if (testData == null) {
      throw Exception('Quiz not found. It may have been deleted.');
    }
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

  // ── Auto-save & Resume ───────────────────────────────────────────────

  /// Save a single question answer and update the current position.
  ///
  /// Called fire-and-forget from the quiz session on each navigation.
  Future<void> saveQuestionAnswer({
    required String testId,
    required String questionId,
    required String answer,
    required int currentIndex,
  }) async {
    await Future.wait([
      _client
          .from('test_questions')
          .update({'user_answer': answer})
          .eq('id', questionId),
      _client
          .from('tests')
          .update({'current_question': currentIndex})
          .eq('id', testId),
    ]);
  }

  /// Fetch all in-progress quizzes for the current user (for home banner).
  Future<List<InProgressQuiz>> getInProgressQuizzes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('tests')
        .select('*, courses!inner(title)')
        .eq('user_id', userId)
        .eq('status', 'in_progress')
        .order('created_at', ascending: false);
    return (data as List).map((e) {
      final coursesJoin = e['courses'];
      final courseName = coursesJoin is Map
          ? (coursesJoin['title'] as String? ?? 'Course')
          : 'Course';
      return InProgressQuiz(
        test: TestModel.fromJson(e),
        courseName: courseName,
      );
    }).toList();
  }

  /// Mark a test as completed (called before submitting for evaluation).
  Future<void> markTestCompleted(String testId) async {
    await _client
        .from('tests')
        .update({'status': 'completed'})
        .eq('id', testId);
  }
}
