import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../courses/presentation/providers/course_provider.dart';

/// Which course is currently selected on the home screen.
/// null means "use the first course" (auto-select).
final selectedHomeCourseIdProvider = StateProvider<String?>((ref) => null);

/// Resolved course ID to display on home.
/// Uses the selected course if set, otherwise the first course.
final activeHomeCourseIdProvider = Provider<String?>((ref) {
  final selected = ref.watch(selectedHomeCourseIdProvider);
  if (selected != null) return selected;
  final courses = ref.watch(coursesProvider).valueOrNull ?? [];
  return courses.isNotEmpty ? courses.first.id : null;
});
