/// Types of study tasks that can appear in the daily plan.
enum StudyTaskType {
  flashcardReview,
  quiz,
  calendarExam,
  calendarTask,
  materialReview,
  summaryGeneration,
  glossaryGeneration,
}

/// A single task in the user's daily study plan.
class StudyTask {
  final StudyTaskType type;
  final String title;
  final String subtitle;
  final String? courseId;
  final String? route;
  final int? count; // e.g. number of due cards
  final int priority; // 0 = highest priority
  final String? reason; // AI-generated reason for the task

  const StudyTask({
    required this.type,
    required this.title,
    required this.subtitle,
    this.courseId,
    this.route,
    this.count,
    this.priority = 50,
    this.reason,
  });

  /// Icon name for the task type.
  String get iconName {
    switch (type) {
      case StudyTaskType.flashcardReview:
        return 'style';
      case StudyTaskType.quiz:
        return 'quiz';
      case StudyTaskType.calendarExam:
        return 'event';
      case StudyTaskType.calendarTask:
        return 'task_alt';
      case StudyTaskType.materialReview:
        return 'description';
      case StudyTaskType.summaryGeneration:
        return 'auto_stories';
      case StudyTaskType.glossaryGeneration:
        return 'menu_book';
    }
  }
}
