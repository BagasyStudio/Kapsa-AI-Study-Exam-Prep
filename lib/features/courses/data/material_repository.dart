import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_limits.dart';
import 'models/material_model.dart';

/// Repository for course materials (PDFs, audio, notes, etc.).
class MaterialRepository {
  final SupabaseClient _client;

  MaterialRepository(this._client);

  /// Fetch all materials for a course.
  Future<List<MaterialModel>> getMaterials(String courseId) async {
    final data = await _client
        .from('course_materials')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => MaterialModel.fromJson(e)).toList();
  }

  /// Fetch recent materials for a user (across all courses).
  Future<List<MaterialModel>> getRecentMaterials(String userId,
      {int limit = 10}) async {
    final data = await _client
        .from('course_materials')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => MaterialModel.fromJson(e)).toList();
  }

  /// Create a material directly (e.g. Quick Paste).
  Future<MaterialModel> createMaterial({
    required String courseId,
    required String userId,
    required String title,
    required String type,
    String? content,
    String? fileUrl,
    int? fileSize,
    int? durationSeconds,
  }) async {
    final data = await _client
        .from('course_materials')
        .insert({
          'course_id': courseId,
          'user_id': userId,
          'title': title,
          'type': type,
          'content': content,
          'file_url': fileUrl,
          'file_size': fileSize,
          'duration_seconds': durationSeconds,
        })
        .select()
        .single();
    return MaterialModel.fromJson(data);
  }

  /// Process a capture via Edge Function (OCR or Whisper).
  Future<MaterialModel> processCapture({
    required String courseId,
    required String type,
    required String fileUrl,
    required String title,
  }) async {
    final response = await _client.functions.invoke(
      'process-capture',
      body: {
        'courseId': courseId,
        'type': type,
        'fileUrl': fileUrl,
        'title': title,
        'maxPages': AppLimits.maxPdfPages,
      },
    );
    return MaterialModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mark a material as reviewed.
  Future<void> markReviewed(String materialId) async {
    await _client
        .from('course_materials')
        .update({'is_reviewed': true})
        .eq('id', materialId);
  }

  /// Delete a material.
  Future<void> deleteMaterial(String materialId) async {
    await _client.from('course_materials').delete().eq('id', materialId);
  }
}
