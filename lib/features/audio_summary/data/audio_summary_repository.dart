import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_functions.dart';
import 'models/audio_summary_model.dart';

/// Repository for audio summary operations.
class AudioSummaryRepository {
  final SupabaseClient _client;
  final SupabaseFunctions _functions;

  AudioSummaryRepository(this._client, this._functions);

  /// Generate an audio summary for a material.
  Future<AudioSummaryModel> generateSummary({
    required String materialId,
    required String courseId,
  }) async {
    final response = await _functions.invoke(
      'generate-audio-summary',
      body: {
        'materialId': materialId,
        'courseId': courseId,
      },
    );

    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from audio summary generation');
    }
    return AudioSummaryModel.fromJson(data);
  }

  /// Get all audio summaries for a course.
  Future<List<AudioSummaryModel>> getSummariesForCourse(
      String courseId) async {
    final data = await _client
        .from('audio_summaries')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => AudioSummaryModel.fromJson(e))
        .toList();
  }

  /// Get audio summaries for a specific material.
  Future<List<AudioSummaryModel>> getSummariesForMaterial(
      String materialId) async {
    final data = await _client
        .from('audio_summaries')
        .select()
        .eq('material_id', materialId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => AudioSummaryModel.fromJson(e))
        .toList();
  }
}
