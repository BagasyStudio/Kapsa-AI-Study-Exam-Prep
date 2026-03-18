import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Exercise Data Provider — calls edge function to generate exercises
// ═══════════════════════════════════════════════════════════════════════════════

/// Generates exercise content by calling the ai-generate-exercise edge function.
final exerciseDataProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String courseId, String exerciseType})>(
        (ref, params) async {
  final supabase = Supabase.instance.client;

  final response = await supabase.functions.invoke(
    'ai-generate-exercise',
    body: {
      'exerciseType': params.exerciseType,
      'courseId': params.courseId,
    },
  );

  if (response.status != 200) {
    throw Exception('Failed to generate exercise');
  }

  final data = response.data;
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is String) {
    return jsonDecode(data) as Map<String, dynamic>;
  }
  throw Exception('Invalid response format');
});

// ═══════════════════════════════════════════════════════════════════════════════
// Exercise Score Tracking
// ═══════════════════════════════════════════════════════════════════════════════

/// Stores exercise scores locally for difficulty estimation and progress tracking.
class ExerciseScoreNotifier extends StateNotifier<Map<String, int>> {
  final String courseId;

  ExerciseScoreNotifier(this.courseId) : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('exercise_scores_$courseId');
    if (raw == null) return;
    try {
      final map = (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as int));
      state = map;
    } catch (e) {
      debugPrint('ExerciseProvider: load saved scores failed: $e');
    }
  }

  Future<void> saveScore(String nodeId, int score) async {
    state = {...state, nodeId: score};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exercise_scores_$courseId', jsonEncode(state));
  }

  int? getScore(String nodeId) => state[nodeId];

  /// Average score across all exercises (0-100).
  double get averageScore {
    if (state.isEmpty) return 0.0;
    final total = state.values.fold<int>(0, (sum, v) => sum + v);
    return total / state.length;
  }
}

final exerciseScoreProvider = StateNotifierProvider.family<
    ExerciseScoreNotifier, Map<String, int>, String>(
  (ref, courseId) => ExerciseScoreNotifier(courseId),
);

// ═══════════════════════════════════════════════════════════════════════════════
// Streak Multiplier
// ═══════════════════════════════════════════════════════════════════════════════

/// Tracks how many nodes completed in current session for streak multiplier.
class StreakMultiplierNotifier extends StateNotifier<int> {
  StreakMultiplierNotifier() : super(0);

  void increment() => state++;
  void reset() => state = 0;

  /// Current XP multiplier based on consecutive completions.
  int get multiplier {
    if (state >= 5) return 3;
    if (state >= 3) return 2;
    return 1;
  }
}

final streakMultiplierProvider =
    StateNotifierProvider<StreakMultiplierNotifier, int>(
  (ref) => StreakMultiplierNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════════
// Weekly Recap Data
// ═══════════════════════════════════════════════════════════════════════════════

/// Weekly recap computed from completion data.
class WeeklyRecap {
  final int nodesCompleted;
  final int xpEarned;
  final int newTopics;
  final int reviewed;

  const WeeklyRecap({
    required this.nodesCompleted,
    required this.xpEarned,
    required this.newTopics,
    required this.reviewed,
  });
}

final weeklyRecapProvider =
    Provider.autoDispose.family<WeeklyRecap, String>((ref, courseId) {
  // Simple placeholder — in production would aggregate from completion timestamps
  final scores = ref.watch(exerciseScoreProvider(courseId));
  return WeeklyRecap(
    nodesCompleted: scores.length,
    xpEarned: scores.values.fold<int>(0, (sum, v) => sum + (v > 0 ? 20 : 0)),
    newTopics: (scores.length * 0.6).round(),
    reviewed: (scores.length * 0.4).round(),
  );
});
