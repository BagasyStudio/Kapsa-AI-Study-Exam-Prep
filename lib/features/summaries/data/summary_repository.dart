import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_functions.dart';
import 'models/summary_model.dart';

class SummaryRepository {
  final SupabaseClient _client;
  final SupabaseFunctions _functions;

  SummaryRepository(this._client, this._functions);

  /// Generate a summary for a course (or single material) via Edge Function.
  Future<SummaryModel> generateSummary({
    required String courseId,
    String? materialId,
  }) async {
    final response = await _functions.invoke(
      'ai-generate-summary',
      body: {
        'courseId': courseId,
        if (materialId != null) 'materialId': materialId,
      },
    );

    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from summary generation');
    }
    return SummaryModel.fromJson(data);
  }

  /// Fetch all summaries for a course.
  Future<List<SummaryModel>> getSummariesForCourse(String courseId) async {
    final data = await _client
        .from('summaries')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => SummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single summary by ID.
  Future<SummaryModel?> getSummary(String id) async {
    final data = await _client
        .from('summaries')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return SummaryModel.fromJson(data);
  }

  /// Delete a summary.
  Future<void> deleteSummary(String id) async {
    await _client.from('summaries').delete().eq('id', id);
  }
}
