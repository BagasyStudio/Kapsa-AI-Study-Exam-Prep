import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../data/models/study_task_model.dart';
import '../../../../core/navigation/routes.dart';

/// Computes the daily study plan from existing data.
///
/// Pulls together:
/// - Due flashcards per course (FSRS)
/// - Courses without recent quizzes
/// - Today's calendar events (exams/tasks)
///
/// Uses batched queries (3 total) instead of N+1 per-course queries.
final studyPlanProvider = FutureProvider<List<StudyTask>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final courses = await ref.watch(coursesProvider.future);
  if (courses.isEmpty) return [];

  final client = ref.read(supabaseClientProvider);
  final courseIds = courses.map((c) => c.id).toList();
  final courseMap = {for (final c in courses) c.id: c.title};
  final tasks = <StudyTask>[];

  // ── 1. Flashcard due cards — single batched query ──
  try {
    final now = DateTime.now().toUtc().toIso8601String();
    // Get all due flashcards joined with their deck's course_id
    final dueCards = await client
        .from('flashcards')
        .select('id, flashcard_decks!inner(course_id)')
        .or('next_review.is.null,next_review.lte.$now')
        .inFilter('flashcard_decks.course_id', courseIds);

    // Group by course_id
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
        tasks.add(StudyTask(
          type: StudyTaskType.flashcardReview,
          title: 'Review $count flashcard${count > 1 ? 's' : ''}',
          subtitle: title,
          courseId: entry.key,
          route: Routes.srsReviewPath(entry.key),
          count: count,
        ));
      }
    }
  } catch (_) {
    // Best-effort
  }

  // ── 2. Courses without recent quizzes — single batched query ──
  try {
    final sevenDaysAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .toUtc()
        .toIso8601String();

    // Get all tests from the last 7 days for user's courses
    final recentTests = await client
        .from('tests')
        .select('course_id')
        .eq('user_id', user.id)
        .gte('created_at', sevenDaysAgo)
        .inFilter('course_id', courseIds);

    final coursesWithRecentQuiz = <String>{};
    for (final test in recentTests as List) {
      final courseId = test['course_id'] as String?;
      if (courseId != null) coursesWithRecentQuiz.add(courseId);
    }

    for (final course in courses) {
      if (!coursesWithRecentQuiz.contains(course.id)) {
        tasks.add(StudyTask(
          type: StudyTaskType.quiz,
          title: 'Take a quiz',
          subtitle: course.title,
          courseId: course.id,
          route: Routes.courseDetailPath(course.id),
        ));
      }
    }
  } catch (_) {
    // Best-effort
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
      tasks.add(StudyTask(
        type: event.isExam
            ? StudyTaskType.calendarExam
            : StudyTaskType.calendarTask,
        title: event.title,
        subtitle: event.timeLabel,
        courseId: event.courseId,
        route: Routes.calendar,
      ));
    }
  } catch (_) {
    // Best-effort
  }

  return tasks;
});
