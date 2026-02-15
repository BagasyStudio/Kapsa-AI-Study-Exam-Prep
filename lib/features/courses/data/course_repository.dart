import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/course_model.dart';

/// Repository for course CRUD operations.
class CourseRepository {
  final SupabaseClient _client;

  CourseRepository(this._client);

  /// Fetch all courses for the given user.
  Future<List<CourseModel>> getCourses(String userId) async {
    final data = await _client
        .from('courses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => CourseModel.fromJson(e)).toList();
  }

  /// Fetch a single course by ID.
  ///
  /// Returns null if course not found.
  Future<CourseModel?> getCourse(String courseId) async {
    final data = await _client
        .from('courses')
        .select()
        .eq('id', courseId)
        .maybeSingle();
    if (data == null) return null;
    return CourseModel.fromJson(data);
  }

  /// Create a new course.
  Future<CourseModel> createCourse({
    required String userId,
    required String title,
    String? subtitle,
    String iconName = 'menu_book',
    String colorHex = '6467F2',
    DateTime? examDate,
  }) async {
    final data = await _client
        .from('courses')
        .insert({
          'user_id': userId,
          'title': title,
          'subtitle': subtitle,
          'icon_name': iconName,
          'color_hex': colorHex,
          'exam_date': examDate?.toIso8601String(),
        })
        .select()
        .single();
    return CourseModel.fromJson(data);
  }

  /// Update course fields.
  Future<void> updateCourse(
    String courseId, {
    String? title,
    String? subtitle,
    String? iconName,
    String? colorHex,
    double? progress,
    DateTime? examDate,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (title != null) updates['title'] = title;
    if (subtitle != null) updates['subtitle'] = subtitle;
    if (iconName != null) updates['icon_name'] = iconName;
    if (colorHex != null) updates['color_hex'] = colorHex;
    if (progress != null) updates['progress'] = progress;
    if (examDate != null) updates['exam_date'] = examDate.toIso8601String();

    await _client.from('courses').update(updates).eq('id', courseId);
  }

  /// Delete a course.
  Future<void> deleteCourse(String courseId) async {
    await _client.from('courses').delete().eq('id', courseId);
  }
}
