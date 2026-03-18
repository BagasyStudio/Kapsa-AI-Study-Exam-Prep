import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../test_results/data/test_repository.dart';
import '../../../test_results/data/models/test_question_model.dart';
import '../../../test_results/presentation/providers/test_provider.dart';

// ── Phase enum ───────────────────────────────────────────────────────────────

/// The overall phase of the inline quiz.
enum InlineQuizPhase { idle, generating, answering, evaluating, complete, error }

/// Per-question display state.
enum QuestionUiState { typing, answered, revealed }

// ── State ────────────────────────────────────────────────────────────────────

class InlineQuizState {
  final InlineQuizPhase phase;
  final int currentIndex;
  final List<TestQuestionModel> questions;
  final Map<int, String> userAnswers;
  final Map<int, bool> localResults;
  final Map<int, QuestionUiState> questionStates;
  final TestWithQuestions? evaluatedResult;
  final String? testId;
  final String? errorMessage;
  final bool isNoMaterials;
  final Map<String, dynamic>? mistakesExplanation;
  final bool isLoadingMistakes;

  const InlineQuizState({
    this.phase = InlineQuizPhase.idle,
    this.currentIndex = 0,
    this.questions = const [],
    this.userAnswers = const {},
    this.localResults = const {},
    this.questionStates = const {},
    this.evaluatedResult,
    this.testId,
    this.errorMessage,
    this.isNoMaterials = false,
    this.mistakesExplanation,
    this.isLoadingMistakes = false,
  });

  /// Whether the quiz is in an active (non-idle, non-complete) phase.
  bool get isActive =>
      phase == InlineQuizPhase.generating ||
      phase == InlineQuizPhase.answering ||
      phase == InlineQuizPhase.evaluating;

  /// Current question's UI state.
  QuestionUiState get currentQuestionState =>
      questionStates[currentIndex] ?? QuestionUiState.typing;

  /// How many questions the user got right (local check).
  int get correctCount => localResults.values.where((v) => v).length;

  InlineQuizState copyWith({
    InlineQuizPhase? phase,
    int? currentIndex,
    List<TestQuestionModel>? questions,
    Map<int, String>? userAnswers,
    Map<int, bool>? localResults,
    Map<int, QuestionUiState>? questionStates,
    TestWithQuestions? evaluatedResult,
    String? testId,
    String? errorMessage,
    bool? isNoMaterials,
    Map<String, dynamic>? mistakesExplanation,
    bool? isLoadingMistakes,
  }) {
    return InlineQuizState(
      phase: phase ?? this.phase,
      currentIndex: currentIndex ?? this.currentIndex,
      questions: questions ?? this.questions,
      userAnswers: userAnswers ?? this.userAnswers,
      localResults: localResults ?? this.localResults,
      questionStates: questionStates ?? this.questionStates,
      evaluatedResult: evaluatedResult ?? this.evaluatedResult,
      testId: testId ?? this.testId,
      errorMessage: errorMessage ?? this.errorMessage,
      isNoMaterials: isNoMaterials ?? this.isNoMaterials,
      mistakesExplanation: mistakesExplanation ?? this.mistakesExplanation,
      isLoadingMistakes: isLoadingMistakes ?? this.isLoadingMistakes,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class InlineQuizNotifier extends StateNotifier<InlineQuizState> {
  final TestRepository _repo;
  final String _courseId;

  InlineQuizNotifier(this._repo, this._courseId)
      : super(const InlineQuizState());

  // ── Public API ──

  /// Generate a 3-question quiz for this course.
  Future<void> startQuiz() async {
    state = const InlineQuizState(phase: InlineQuizPhase.generating);

    try {
      final result = await _repo.generateQuiz(
        courseId: _courseId,
        count: 3,
      );
      state = state.copyWith(
        phase: InlineQuizPhase.answering,
        questions: result.questions,
        testId: result.test.id,
        currentIndex: 0,
        questionStates: {0: QuestionUiState.typing},
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final noMaterials = msg.contains('no materials') ||
          msg.contains('not enough') ||
          msg.contains('no content') ||
          msg.contains('400');
      state = state.copyWith(
        phase: InlineQuizPhase.error,
        errorMessage: noMaterials
            ? "This course doesn't have enough material to generate a quiz yet."
            : 'Failed to generate quiz. Please try again.',
        isNoMaterials: noMaterials,
      );
    }
  }

  /// Check the user's answer for the current question (local comparison).
  void checkAnswer(String answer) {
    final idx = state.currentIndex;
    final question = state.questions[idx];

    final isCorrect = _isCorrect(answer, question.correctAnswer);

    final newAnswers = Map<int, String>.from(state.userAnswers);
    newAnswers[idx] = answer;

    final newResults = Map<int, bool>.from(state.localResults);
    newResults[idx] = isCorrect;

    final newStates = Map<int, QuestionUiState>.from(state.questionStates);
    newStates[idx] = QuestionUiState.revealed;

    state = state.copyWith(
      userAnswers: newAnswers,
      localResults: newResults,
      questionStates: newStates,
    );
  }

  /// Move to the next question. If last, trigger evaluation.
  void nextQuestion() {
    final nextIdx = state.currentIndex + 1;
    if (nextIdx >= state.questions.length) {
      _evaluate();
      return;
    }

    final newStates = Map<int, QuestionUiState>.from(state.questionStates);
    newStates[nextIdx] = QuestionUiState.typing;

    state = state.copyWith(
      currentIndex: nextIdx,
      questionStates: newStates,
    );
  }

  /// Submit all answers for AI evaluation.
  Future<void> _evaluate() async {
    state = state.copyWith(phase: InlineQuizPhase.evaluating);

    try {
      final answers = state.questions.map((q) {
        final idx = q.questionNumber - 1;
        return {
          'questionId': q.id,
          'answer': state.userAnswers[idx] ?? '',
        };
      }).toList();

      final result = await _repo.submitAnswers(
        testId: state.testId!,
        answers: answers,
      );

      state = state.copyWith(
        phase: InlineQuizPhase.complete,
        evaluatedResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        phase: InlineQuizPhase.error,
        errorMessage: 'Failed to evaluate answers. Tap retry to try again.',
      );
    }
  }

  /// Retry evaluation without losing answers.
  Future<void> retryEvaluation() async {
    if (state.userAnswers.isEmpty) return;
    await _evaluate();
  }

  /// Load AI explanation of mistakes.
  Future<void> loadMistakesExplanation() async {
    if (state.testId == null) return;
    state = state.copyWith(isLoadingMistakes: true);

    try {
      final data = await _repo.explainMistakes(testId: state.testId!);
      state = state.copyWith(
        mistakesExplanation: data,
        isLoadingMistakes: false,
      );
    } catch (e) {
      debugPrint('InlineQuizProvider: loadMistakesExplanation failed: $e');
      state = state.copyWith(isLoadingMistakes: false);
    }
  }

  /// Reset quiz back to idle (cancel / continue chatting).
  void reset() {
    state = const InlineQuizState();
  }

  // ── Correctness matching ──

  static String _normalize(String s) {
    return s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool _isCorrect(String user, String correct) {
    final u = _normalize(user);
    final c = _normalize(correct);
    if (u.isEmpty || c.isEmpty) return false;
    if (u == c) return true;
    // For answers > 3 chars, allow contains only if >= 60% of length
    if (u.length > 3 && c.contains(u) && u.length >= c.length * 0.6) {
      return true;
    }
    if (c.length > 3 && u.contains(c) && c.length >= u.length * 0.6) {
      return true;
    }
    return false;
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final inlineQuizProvider = StateNotifierProvider.autoDispose
    .family<InlineQuizNotifier, InlineQuizState, String>(
  (ref, courseId) {
    final repo = ref.watch(testRepositoryProvider);
    return InlineQuizNotifier(repo, courseId);
  },
);
