import 'package:flutter/foundation.dart';
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
    debugPrint('[SnapSolve] Calling snap-solve with imageUrl: $imageUrl');
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _functions.invoke(
        'snap-solve',
        body: {
          'imageUrl': imageUrl,
          if (courseId != null) 'courseId': courseId,
        },
      );

      stopwatch.stop();
      debugPrint('[SnapSolve] Response received in ${stopwatch.elapsedMilliseconds}ms');

      final data = response.data;
      debugPrint('[SnapSolve] Response data type: ${data.runtimeType}');

      if (data == null || data is! Map<String, dynamic>) {
        debugPrint('[SnapSolve] Invalid data: $data');
        throw Exception('Invalid response from solver');
      }

      if (data['error'] != null) {
        debugPrint('[SnapSolve] Server error: ${data['error']}');
        throw Exception(data['error'] as String);
      }

      final userId = _client.auth.currentUser?.id ?? '';
      return SnapSolutionModel.fromJson({
        ...data,
        'user_id': userId,
        'image_url': imageUrl,
      });
    } on FunctionException catch (e) {
      stopwatch.stop();
      debugPrint('[SnapSolve] FunctionException after ${stopwatch.elapsedMilliseconds}ms: '
          'status=${e.status}, details=${e.details} (${e.details.runtimeType}), '
          'reasonPhrase=${e.reasonPhrase}');
      rethrow;
    } catch (e) {
      stopwatch.stop();
      debugPrint('[SnapSolve] Error after ${stopwatch.elapsedMilliseconds}ms: '
          '${e.runtimeType}: $e');
      rethrow;
    }
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
