import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/course_repository.dart';
import '../../data/material_repository.dart';
import '../../data/models/course_model.dart';
import '../../data/models/material_model.dart';

/// Provider for the course repository.
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(ref.watch(supabaseClientProvider));
});

/// Provider for the material repository.
final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  return MaterialRepository(ref.watch(supabaseClientProvider));
});

/// Fetches all courses for the current user.
final coursesProvider =
    FutureProvider.autoDispose<List<CourseModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(courseRepositoryProvider).getCourses(user.id);
});

/// Fetches a single course by ID.
final courseProvider =
    FutureProvider.autoDispose.family<CourseModel?, String>((ref, courseId) async {
  return ref.watch(courseRepositoryProvider).getCourse(courseId);
});

/// Fetches materials for a course.
final courseMaterialsProvider = FutureProvider.autoDispose
    .family<List<MaterialModel>, String>((ref, courseId) async {
  return ref.watch(materialRepositoryProvider).getMaterials(courseId);
});

/// Fetches recent materials for the current user (for Home screen).
final recentMaterialsProvider =
    FutureProvider.autoDispose<List<MaterialModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(materialRepositoryProvider).getRecentMaterials(user.id, limit: 4);
});
