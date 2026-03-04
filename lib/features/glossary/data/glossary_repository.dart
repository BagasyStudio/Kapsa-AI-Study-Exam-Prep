import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_functions.dart';
import 'models/glossary_term_model.dart';

class GlossaryRepository {
  final SupabaseClient _client;
  final SupabaseFunctions _functions;

  GlossaryRepository(this._client, this._functions);

  /// Generate glossary terms for a course via Edge Function.
  Future<List<GlossaryTermModel>> generateGlossary({
    required String courseId,
  }) async {
    final response = await _functions.invoke(
      'ai-generate-glossary',
      body: {'courseId': courseId},
    );

    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from glossary generation');
    }
    final terms = data['terms'] as List? ?? [];
    return terms
        .map((e) => GlossaryTermModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all glossary terms for a course.
  Future<List<GlossaryTermModel>> getTerms(String courseId) async {
    final data = await _client
        .from('glossary_terms')
        .select()
        .eq('course_id', courseId)
        .order('term', ascending: true);
    return (data as List)
        .map((e) => GlossaryTermModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Delete a glossary term.
  Future<void> deleteTerm(String id) async {
    await _client.from('glossary_terms').delete().eq('id', id);
  }
}
