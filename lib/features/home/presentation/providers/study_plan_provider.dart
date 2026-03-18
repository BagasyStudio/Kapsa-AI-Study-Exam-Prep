import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../data/models/study_task_model.dart';
import '../../../../core/navigation/routes.dart';

/// Computes the daily study plan from existing data with intelligent prioritization.
///
/// Pulls together:
/// - Due flashcards per course (FSRS) — highest priority
/// - Upcoming exams (calendar) — high priority when close
/// - Courses without recent quizzes
/// - Materials not reviewed recently
/// - Today's calendar events (exams/tasks)
///
/// Uses batched queries (3 total) instead of N+1 per-course queries.
/// Tasks are priority-sorted: exam close > SRS due > low quiz scores > unreviewed materials.
final studyPlanProvider = FutureProvider<List<StudyTask>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final courses = await ref.watch(coursesProvider.future);
  if (courses.isEmpty) return [];

  final client = ref.read(supabaseClientProvider);
  final courseIds = courses.map((c) => c.id).toList();
  final courseMap = {for (final c in courses) c.id: c.displayTitle};
  final tasks = <StudyTask>[];

  // ── 1. Flashcard due cards — single batched query ──
  try {
    final now = DateTime.now().toUtc().toIso8601String();
    final dueCards = await client
        .from('flashcards')
        .select('id, flashcard_decks!inner(course_id)')
        .or('next_review.is.null,next_review.lte.$now')
        .inFilter('flashcard_decks.course_id', courseIds);

    final dueCounts = <String, int>{};
    for (final card in dueCards as List) {
      final deckData = card['flashcard_decks'];
      final courseId = deckData is Map ? deckData['course_id'] as String? : null;
      if (courseId != null) {
        dueCounts[courseId] = (dueCounts[courseId] ?? 0) + 1;
      }
    }

    for (final entry in dueCounts.entries) {
      final count = entry.value;
      final title = courseMap[entry.key];
      if (title != null && count > 0) {
        // Priority: more due cards = higher priority
        final priority = count > 50 ? 5 : (count > 20 ? 10 : 15);
        final reason = count > 50
            ? 'You have a large backlog — tackle 20 cards to stay on track'
            : count > 10
                ? 'These cards are due for review to maintain retention'
                : 'Quick 5-minute review to keep your memory fresh';
        tasks.add(StudyTask(
          type: StudyTaskType.flashcardReview,
          title: 'Review $count flashcard${count > 1 ? 's' : ''}',
          subtitle: title,
          courseId: entry.key,
          route: Routes.srsReviewPath(entry.key),
          count: count,
          priority: priority,
          reason: reason,
        ));
      }
    }
  } catch (e) {
    debugPrint('StudyPlan: fetch due flashcards failed: $e');
  }

  // ── 2. Courses without recent quizzes — single batched query ──
  try {
    final sevenDaysAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .toUtc()
        .toIso8601String();

    final recentTests = await client
        .from('tests')
        .select('course_id, score')
        .eq('user_id', user.id)
        .gte('created_at', sevenDaysAgo)
        .inFilter('course_id', courseIds);

    final coursesWithRecentQuiz = <String>{};
    final lowScoreCourses = <String, double>{};
    for (final test in recentTests as List) {
      final courseId = test['course_id'] as String?;
      final score = (test['score'] as num?)?.toDouble();
      if (courseId != null) {
        coursesWithRecentQuiz.add(courseId);
        if (score != null && score < 70) {
          // Track lowest score per course
          final existing = lowScoreCourses[courseId];
          if (existing == null || score < existing) {
            lowScoreCourses[courseId] = score;
          }
        }
      }
    }

    // Suggest quiz for courses with low scores (higher priority)
    for (final entry in lowScoreCourses.entries) {
      final title = courseMap[entry.key];
      if (title != null) {
        tasks.add(StudyTask(
          type: StudyTaskType.quiz,
          title: 'Retake quiz',
          subtitle: title,
          courseId: entry.key,
          route: '${Routes.practiceExam}?courseId=${entry.key}',
          priority: 20,
          reason: 'Your last score was ${entry.value.toInt()}% — practice to improve',
        ));
      }
    }

    // Suggest quiz for courses without recent quizzes
    for (final course in courses) {
      if (!coursesWithRecentQuiz.contains(course.id) &&
          !lowScoreCourses.containsKey(course.id)) {
        tasks.add(StudyTask(
          type: StudyTaskType.quiz,
          title: 'Take a quiz',
          subtitle: course.displayTitle,
          courseId: course.id,
          route: '${Routes.practiceExam}?courseId=${course.id}',
          priority: 35,
          reason: 'No quiz in 7+ days — test your knowledge',
        ));
      }
    }
  } catch (e) {
    debugPrint('StudyPlan: fetch quiz suggestions failed: $e');
  }

  // ── 3. Today's calendar events (already a single query) ──
  try {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final events = await ref
        .watch(calendarRepositoryProvider)
        .getEvents(user.id, todayDate);
    for (final event in events) {
      if (event.isCompleted) continue;
      final isExam = event.isExam;
      tasks.add(StudyTask(
        type: isExam ? StudyTaskType.calendarExam : StudyTaskType.calendarTask,
        title: event.title,
        subtitle: event.timeLabel,
        courseId: event.courseId,
        route: Routes.calendar,
        priority: isExam ? 1 : 30, // Exams today get top priority
        reason: isExam
            ? 'Exam today — focus your study session here'
            : null,
      ));
    }
  } catch (e) {
    debugPrint('StudyPlan: fetch calendar events failed: $e');
  }

  // ── 4. Courses with low progress (< 30%) — suggest material review ──
  try {
    for (final course in courses) {
      if (course.progress < 0.3) {
        tasks.add(StudyTask(
          type: StudyTaskType.materialReview,
          title: 'Review materials',
          subtitle: course.displayTitle,
          courseId: course.id,
          route: Routes.courseDetailPath(course.id),
          priority: 40,
          reason: 'Only ${(course.progress * 100).toInt()}% progress — review your notes',
        ));
      }
    }
  } catch (e) {
    debugPrint('StudyPlan: check low progress courses failed: $e');
  }

  // Sort by priority (lower number = higher priority)
  tasks.sort((a, b) => a.priority.compareTo(b.priority));

  return tasks;
});

// ═══════════════════════════════════════════════════════════════════════════════
// AI-Enhanced Study Plan Provider
// ═══════════════════════════════════════════════════════════════════════════════

/// Map edge function type strings to [StudyTaskType].
StudyTaskType _parseTaskType(String type) {
  switch (type) {
    case 'flashcard_review':
      return StudyTaskType.flashcardReview;
    case 'quiz':
      return StudyTaskType.quiz;
    case 'exam_prep':
      return StudyTaskType.calendarExam;
    case 'material_review':
      return StudyTaskType.materialReview;
    case 'summary':
      return StudyTaskType.summaryGeneration;
    case 'glossary':
      return StudyTaskType.glossaryGeneration;
    default:
      return StudyTaskType.materialReview;
  }
}

/// Route for AI-generated task based on type and courseId.
String? _routeForTask(StudyTaskType type, String? courseId) {
  if (courseId == null) return null;
  switch (type) {
    case StudyTaskType.flashcardReview:
      return Routes.srsReviewPath(courseId);
    case StudyTaskType.quiz:
      return '${Routes.practiceExam}?courseId=$courseId';
    case StudyTaskType.materialReview:
    case StudyTaskType.summaryGeneration:
    case StudyTaskType.glossaryGeneration:
      return Routes.courseDetailPath(courseId);
    case StudyTaskType.calendarExam:
    case StudyTaskType.calendarTask:
      return Routes.calendar;
  }
}

/// Fetches an AI-enhanced study plan via the `ai-assistant` edge function.
///
/// Falls back to the local [studyPlanProvider] if the AI call fails or
/// returns empty results. The AI enhances tasks with personalized reasons
/// and may suggest additional tasks the local logic wouldn't catch.
final aiEnhancedStudyPlanProvider = FutureProvider<List<StudyTask>>((ref) async {
  // First, get the local tasks as fallback (this is fast)
  final localTasks = await ref.watch(studyPlanProvider.future);

  // Try AI enhancement
  try {
    final functions = ref.read(supabaseFunctionsProvider);

    // Send local tasks as context for the AI
    final taskPayload = localTasks.map((t) {
      return {
        'type': t.type.name,
        'title': t.title,
        'subtitle': t.subtitle,
        'courseId': t.courseId,
        'count': t.count,
        'priority': t.priority,
      };
    }).toList();

    final response = await functions.invoke(
      'ai-assistant',
      body: {
        'mode': 'generate_study_path',
        'tasks': taskPayload,
      },
    );

    final data = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    final aiTasks = data['tasks'] as List? ?? [];
    if (aiTasks.isEmpty) return localTasks;

    // Build AI-enhanced task list
    final enhancedTasks = <StudyTask>[];

    for (final raw in aiTasks) {
      final map = raw as Map<String, dynamic>;
      final type = _parseTaskType(map['type'] as String? ?? 'material_review');
      final courseId = map['courseId'] as String?;

      // Try to find matching local task for route
      final matchingLocal = localTasks.where((t) =>
          t.courseId == courseId && t.type == type).toList();
      final route = matchingLocal.isNotEmpty
          ? matchingLocal.first.route
          : _routeForTask(type, courseId);

      enhancedTasks.add(StudyTask(
        type: type,
        title: map['title'] as String? ?? 'Study task',
        subtitle: map['subtitle'] as String? ?? '',
        courseId: courseId,
        route: route,
        count: matchingLocal.isNotEmpty ? matchingLocal.first.count : null,
        priority: (map['priority'] as num?)?.toInt() ?? 25,
        reason: map['reason'] as String?,
      ));
    }

    // Sort by priority
    enhancedTasks.sort((a, b) => a.priority.compareTo(b.priority));

    return enhancedTasks;
  } catch (e) {
    // AI failed — return local tasks
    debugPrint('StudyPlanProvider: AI enhance failed: $e');
    return localTasks;
  }
});
