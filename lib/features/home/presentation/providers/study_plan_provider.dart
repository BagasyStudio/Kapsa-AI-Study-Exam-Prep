import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../test_results/presentation/providers/test_provider.dart';
import '../../data/models/study_task_model.dart';
import '../../../../core/navigation/routes.dart';

/// Computes the daily study plan from existing data.
///
/// Pulls together:
/// - Due flashcards per course (FSRS)
/// - Courses without recent quizzes
/// - Today's calendar events (exams/tasks)
final studyPlanProvider = FutureProvider<List<StudyTask>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final courses = await ref.watch(coursesProvider.future);
  if (courses.isEmpty) return [];

  final tasks = <StudyTask>[];

  // ── 1. Flashcard due cards per course ──
  for (final course in courses) {
    try {
      final dueCount = await ref
          .read(flashcardRepositoryProvider)
          .getDueCardsCount(course.id);
      if (dueCount > 0) {
        tasks.add(StudyTask(
          type: StudyTaskType.flashcardReview,
          title: 'Review $dueCount flashcard${dueCount > 1 ? 's' : ''}',
          subtitle: course.title,
          courseId: course.id,
          route: Routes.srsReviewPath(course.id),
          count: dueCount,
        ));
      }
    } catch (_) {
      // Skip on error
    }
  }

  // ── 2. Courses without recent quizzes → suggest quiz ──
  for (final course in courses) {
    try {
      final tests = await ref
          .read(testRepositoryProvider)
          .getTestsForCourse(course.id);
      final hasRecentQuiz = tests.any((t) {
        if (t.createdAt == null) return false;
        return DateTime.now().difference(t.createdAt!).inDays < 7;
      });
      if (!hasRecentQuiz) {
        tasks.add(StudyTask(
          type: StudyTaskType.quiz,
          title: 'Take a quiz',
          subtitle: course.title,
          courseId: course.id,
          route: Routes.courseDetailPath(course.id),
        ));
      }
    } catch (_) {
      // Skip on error
    }
  }

  // ── 3. Today's calendar events ──
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
    // Skip on error
  }

  return tasks;
});
