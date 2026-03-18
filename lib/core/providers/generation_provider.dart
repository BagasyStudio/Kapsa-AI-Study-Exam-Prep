import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/generation_task.dart';
export '../models/generation_task.dart';
import '../navigation/routes.dart';
import '../services/sound_service.dart';
import '../utils/error_handler.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/flashcards/presentation/providers/flashcard_provider.dart';
import '../../features/glossary/presentation/providers/glossary_provider.dart';
import '../../features/summaries/presentation/providers/summary_provider.dart';
import '../../features/subscription/presentation/providers/subscription_provider.dart';
import '../../features/test_results/presentation/providers/test_provider.dart';

/// Retry helper with exponential backoff for AI generation calls.
Future<T> _retryWithBackoff<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 2),
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } catch (e) {
      if (attempt == maxAttempts) rethrow;
      // Only retry on timeout/network errors, not on validation errors
      final msg = e.toString().toLowerCase();
      final isRetryable = msg.contains('timeout') ||
          msg.contains('unavailable') ||
          msg.contains('socket') ||
          msg.contains('connection') ||
          msg.contains('network') ||
          msg.contains('500') ||
          msg.contains('502') ||
          msg.contains('503') ||
          msg.contains('429');
      if (!isRetryable) rethrow;
      final delay = initialDelay * (1 << (attempt - 1)); // 2s, 4s
      debugPrint('Generation retry $attempt/$maxAttempts after ${delay.inSeconds}s: $e');
      await Future.delayed(delay);
    }
  }
  throw StateError('Unreachable');
}

// ═══════════════════════════════════════════════════════════════════════════════
// Background Generation Provider
// ═══════════════════════════════════════════════════════════════════════════════
//
// Manages AI generation tasks (flashcards, quiz, summary, glossary) that run
// in the background. The user can navigate freely while generation happens.
// A banner on the home screen shows progress and results.
//
// NOT autoDispose — state persists across the entire app lifecycle.
// ═══════════════════════════════════════════════════════════════════════════════

class GenerationNotifier extends StateNotifier<List<GenerationTask>> {
  final Ref _ref;

  GenerationNotifier(this._ref) : super([]);

  // ── Public API ───────────────────────────────────────────────────────────

  /// Start generating flashcards in background. Returns false if already running.
  ///
  /// Optionally pass [materialId] to generate from a specific material.
  /// If [count] is not provided, free users are capped at 30 cards.
  bool generateFlashcards(String courseId, String courseName, {String? materialId, int? count}) {
    if (isRunning(GenerationType.flashcards, courseId)) return false;

    final task = _createTask(GenerationType.flashcards, courseId, courseName);

    // Fire-and-forget — check credits, resolve pro status, generate
    () async {
      // Check credits before starting (prevents bypass via concurrent requests)
      if (!await _checkCredits('flashcards', task.id)) return;

      // Cap free users to 30 cards regardless of requested count
      var effectiveCount = count;
      try {
        final isPro = await _ref.read(isProProvider.future);
        if (!isPro) {
          effectiveCount = (effectiveCount ?? 30).clamp(1, 30);
        }
      } catch (e) {
        debugPrint('GenerationNotifier: pro status check failed: $e');
        effectiveCount = (effectiveCount ?? 30).clamp(1, 30);
      }

      try {
        final deck = await _retryWithBackoff(() => _ref
            .read(flashcardRepositoryProvider)
            .generateFlashcards(courseId: courseId, materialId: materialId, count: effectiveCount));
        _recordUsage('flashcards');
        _ref.invalidate(flashcardDecksProvider(courseId));
        _ref.invalidate(parentDecksProvider(courseId));
        _completeTask(task.id, Routes.deckDetailPath(deck.id));
      } catch (e) {
        _failTask(task.id, e);
      }
    }();

    return true;
  }

  /// Start generating a quiz in background. Returns false if already running.
  bool generateQuiz(String courseId, String courseName, {List<String>? focusTopics}) {
    if (isRunning(GenerationType.quiz, courseId)) return false;

    final task = _createTask(GenerationType.quiz, courseId, courseName);

    () async {
      if (!await _checkCredits('quiz', task.id)) return;
      try {
        final result = await _retryWithBackoff(() => _ref
            .read(testRepositoryProvider)
            .generateQuiz(courseId: courseId, focusTopics: focusTopics));
        _recordUsage('quiz');
        _completeTask(task.id, Routes.quizSessionPath(result.test.id));
      } catch (e) {
        _failTask(task.id, e);
      }
    }();

    return true;
  }

  /// Start generating a summary in background. Returns false if already running.
  bool generateSummary(String courseId, String courseName) {
    if (isRunning(GenerationType.summary, courseId)) return false;

    final task = _createTask(GenerationType.summary, courseId, courseName);

    () async {
      if (!await _checkCredits('summary', task.id)) return;
      try {
        final summary = await _retryWithBackoff(() => _ref
            .read(summaryRepositoryProvider)
            .generateSummary(courseId: courseId));
        _recordUsage('summary');
        _ref.invalidate(courseSummariesProvider(courseId));
        _completeTask(task.id, Routes.summaryPath(summary.id));
      } catch (e) {
        _failTask(task.id, e);
      }
    }();

    return true;
  }

  /// Start generating a glossary in background. Returns false if already running.
  bool generateGlossary(String courseId, String courseName) {
    if (isRunning(GenerationType.glossary, courseId)) return false;

    final task = _createTask(GenerationType.glossary, courseId, courseName);

    () async {
      if (!await _checkCredits('glossary', task.id)) return;
      try {
        await _retryWithBackoff(() => _ref
            .read(glossaryRepositoryProvider)
            .generateGlossary(courseId: courseId));
        _recordUsage('glossary');
        _ref.invalidate(glossaryTermsProvider(courseId));
        _completeTask(task.id, Routes.glossaryPath(courseId));
      } catch (e) {
        _failTask(task.id, e);
      }
    }();

    return true;
  }

  /// Remove a task from the list (dismiss banner card).
  void dismiss(String taskId) {
    state = state.where((t) => t.id != taskId).toList();
  }

  /// Whether a task of this type+courseId is currently running.
  bool isRunning(GenerationType type, String courseId) {
    return state.any(
      (t) => t.type == type && t.courseId == courseId && t.isRunning,
    );
  }

  /// Whether ANY task is currently running.
  bool get hasRunning => state.any((t) => t.isRunning);

  // ── Internal ─────────────────────────────────────────────────────────────

  GenerationTask _createTask(
    GenerationType type,
    String courseId,
    String courseName,
  ) {
    final task = GenerationTask(
      id: '${type.name}_${courseId}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      courseId: courseId,
      courseName: courseName,
      status: GenerationStatus.running,
      startedAt: DateTime.now(),
    );
    state = [...state, task];
    return task;
  }

  /// Check if user has enough credits before starting generation.
  /// Returns false and fails the task if credits are insufficient.
  Future<bool> _checkCredits(String feature, String taskId) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        _failTask(taskId, Exception('Not authenticated'));
        return false;
      }
      final canUse = await _ref
          .read(subscriptionRepositoryProvider)
          .checkCanUseFeature(user.id, feature);
      if (!canUse) {
        _failTask(taskId, Exception('Daily credit limit reached. Credits reset tomorrow.'));
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('GenerationNotifier: credit check failed: $e');
      // Fail-open only for Pro users; free users must pass the check
      try {
        final isPro = await _ref.read(isProProvider.future);
        if (isPro) return true;
      } catch (_) {}
      _failTask(taskId, Exception('Could not verify credits. Please try again.'));
      return false;
    }
  }

  void _completeTask(String taskId, String resultRoute) {
    if (!mounted) return;
    // Guard: task may have been cancelled/dismissed while running
    if (!state.any((t) => t.id == taskId)) return;
    state = state.map((t) {
      if (t.id != taskId) return t;
      return t.copyWith(
        status: GenerationStatus.completed,
        resultRoute: resultRoute,
        completedAt: DateTime.now(),
      );
    }).toList();

    // Haptic + sound feedback
    HapticFeedback.mediumImpact();
    SoundService.playProcessingComplete();
  }

  void _failTask(String taskId, Object error) {
    if (!mounted) return;
    // Guard: task may have been cancelled/dismissed while running
    if (!state.any((t) => t.id == taskId)) return;
    final friendly = AppErrorHandler.friendlyMessage(error);
    state = state.map((t) {
      if (t.id != taskId) return t;
      return t.copyWith(
        status: GenerationStatus.error,
        errorMessage: friendly,
        completedAt: DateTime.now(),
      );
    }).toList();
  }

  /// Record feature usage (mirrors recordFeatureUsage but uses Ref).
  void _recordUsage(String feature) {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;
      _ref.read(subscriptionRepositoryProvider).recordUsage(user.id, feature);
      _ref.invalidate(dailyUsageProvider);
      _ref.invalidate(remainingCreditsProvider);
      _ref.invalidate(creditsUsedTodayProvider);
    } catch (e) {
      // Non-critical — don't fail the generation
      debugPrint('GenerationNotifier: recordUsage failed: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════════════════════

/// Main generation provider — NOT autoDispose so tasks persist across screens.
final generationProvider =
    StateNotifierProvider<GenerationNotifier, List<GenerationTask>>((ref) {
  return GenerationNotifier(ref);
});

/// Only running tasks.
final activeGenerationsProvider = Provider<List<GenerationTask>>((ref) {
  return ref.watch(generationProvider).where((t) => t.isRunning).toList();
});

/// Completed or errored tasks (ready for user interaction).
final finishedGenerationsProvider = Provider<List<GenerationTask>>((ref) {
  return ref
      .watch(generationProvider)
      .where((t) => t.isCompleted || t.isError)
      .toList();
});

/// Quick bool — any task exists (running, completed, or error).
final hasGenerationsProvider = Provider<bool>((ref) {
  return ref.watch(generationProvider).isNotEmpty;
});
