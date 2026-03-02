import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_functions.dart';
import 'models/snap_solution_model.dart';

/// Repository for Snap & Solve operations.
///
/// Handles AI problem solving via edge function and solution CRUD.
class SnapSolveRepository {
  final SupabaseClient _client;
  final SupabaseFunctions _functions;

  SnapSolveRepository(this._client, this._functions);

  /// Sends an image to the AI solver and returns the solution.
  ///
  /// [imageUrl] is the public URL of the uploaded image in Supabase Storage.
  /// [courseId] is an optional course association.
  Future<SnapSolutionModel> solveProblem({
    required String imageUrl,
    String? courseId,
  }) async {
    final response = await _functions.invoke(
      'snap-solve',
      body: {
        'imageUrl': imageUrl,
        if (courseId != null) 'courseId': courseId,
      },
    );

    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from solver');
    }

    if (data['error'] != null) {
      throw Exception(data['error'] as String);
    }

    final userId = _client.auth.currentUser?.id ?? '';
    return SnapSolutionModel.fromJson({
      ...data,
      'user_id': userId,
      'image_url': imageUrl,
    });
  }

  /// Fetches the user's solution history, most recent first.
  Future<List<SnapSolutionModel>> getSolutions(String userId) async {
    final response = await _client
        .from('snap_solutions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((json) =>
            SnapSolutionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single solution by ID.
  Future<SnapSolutionModel?> getSolution(String id) async {
    final response = await _client
        .from('snap_solutions')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return SnapSolutionModel.fromJson(response);
  }

  /// Deletes a solution.
  Future<void> deleteSolution(String id) async {
    await _client.from('snap_solutions').delete().eq('id', id);
  }
}
