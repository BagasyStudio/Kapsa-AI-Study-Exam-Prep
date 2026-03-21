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
    String? materialId,
  }) async {
    final response = await _functions.invoke(
      'ai-generate-glossary',
      body: {
        'courseId': courseId,
        if (materialId != null) 'materialId': materialId,
      },
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

  /// Create a new glossary term.
  Future<GlossaryTermModel> createTerm({
    required String courseId,
    required String term,
    required String definition,
    List<String> relatedTerms = const [],
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client.from('glossary_terms').insert({
      'course_id': courseId,
      'user_id': userId,
      'term': term,
      'definition': definition,
      'related_terms': relatedTerms,
    }).select().single();
    return GlossaryTermModel.fromJson(data);
  }

  /// Update an existing glossary term.
  Future<GlossaryTermModel> updateTerm({
    required String id,
    required String term,
    required String definition,
    List<String>? relatedTerms,
  }) async {
    final updates = <String, dynamic>{
      'term': term,
      'definition': definition,
    };
    if (relatedTerms != null) {
      updates['related_terms'] = relatedTerms;
    }
    final data = await _client
        .from('glossary_terms')
        .update(updates)
        .eq('id', id)
        .select()
        .maybeSingle();
    if (data == null) {
      throw Exception('Term not found. It may have been deleted.');
    }
    return GlossaryTermModel.fromJson(data);
  }

  /// Delete a glossary term.
  Future<void> deleteTerm(String id) async {
    await _client.from('glossary_terms').delete().eq('id', id);
  }
}
