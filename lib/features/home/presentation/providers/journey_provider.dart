import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/navigation/routes.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../data/models/journey_node_model.dart';
import 'exercise_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Exercise types to inject between content nodes
// ═══════════════════════════════════════════════════════════════════════════════

/// Rotating pool of exercise types to keep the journey varied.
const _exercisePool = [
  JourneyNodeType.fillGaps,
  JourneyNodeType.speedRound,
  JourneyNodeType.matchBlitz,
  JourneyNodeType.mistakeSpotter,
  JourneyNodeType.compareContrast,
  JourneyNodeType.timelineBuilder,
  JourneyNodeType.conceptMapper,
  JourneyNodeType.caseStudy,
  JourneyNodeType.teachBot,
];

/// Map exercise type to edge function type string.
String exerciseTypeToString(JourneyNodeType type) => switch (type) {
      JourneyNodeType.fillGaps => 'fillGaps',
      JourneyNodeType.speedRound => 'speedRound',
      JourneyNodeType.mistakeSpotter => 'mistakeSpotter',
      JourneyNodeType.teachBot => 'teachBot',
      JourneyNodeType.compareContrast => 'compareContrast',
      JourneyNodeType.timelineBuilder => 'timeline',
      JourneyNodeType.caseStudy => 'caseStudy',
      JourneyNodeType.matchBlitz => 'matchBlitz',
      JourneyNodeType.conceptMapper => 'conceptMap',
      _ => 'fillGaps',
    };

/// Exercise metadata for building nodes.
({String title, String subtitle}) _exerciseMeta(JourneyNodeType type) =>
    switch (type) {
      JourneyNodeType.fillGaps => (
          title: 'Fill the Gaps',
          subtitle: 'Complete the missing terms',
        ),
      JourneyNodeType.speedRound => (
          title: 'Speed Round',
          subtitle: '10 true/false in 50 seconds',
        ),
      JourneyNodeType.mistakeSpotter => (
          title: 'Mistake Spotter',
          subtitle: 'Find the errors',
        ),
      JourneyNodeType.teachBot => (
          title: 'Teach the Bot',
          subtitle: 'Explain it in your words',
        ),
      JourneyNodeType.compareContrast => (
          title: 'Compare & Contrast',
          subtitle: 'Sort the differences',
        ),
      JourneyNodeType.timelineBuilder => (
          title: 'Timeline Builder',
          subtitle: 'Put steps in order',
        ),
      JourneyNodeType.caseStudy => (
          title: 'Case Study',
          subtitle: 'Apply your knowledge',
        ),
      JourneyNodeType.matchBlitz => (
          title: 'Match Blitz',
          subtitle: 'Pair concepts fast',
        ),
      JourneyNodeType.conceptMapper => (
          title: 'Concept Map',
          subtitle: 'Connect the ideas',
        ),
      _ => (title: 'Exercise', subtitle: ''),
    };

// ═══════════════════════════════════════════════════════════════════════════════
// Journey Node Generation
// ═══════════════════════════════════════════════════════════════════════════════

/// Generates the journey node sequence for a course from existing data.
///
/// Enhanced algorithm:
/// 1. Fetch materials + parent decks for the course
/// 2. Interleave: material → exercise → deck → exercise → checkpoint ...
/// 3. Insert varied exercise types (rotating from pool)
/// 4. Insert branch points (choose your exercise) at key positions
/// 5. Append tail nodes: teachBot → quiz → reward → boss exam
/// 6. Load completion state from SharedPreferences
/// 7. Load scores for difficulty estimation
/// 8. Assign states: completed / active / locked
final journeyNodesProvider = FutureProvider.autoDispose
    .family<List<JourneyNode>, String>((ref, courseId) async {
  // Fetch data in parallel
  final decksFuture = ref.watch(parentDecksProvider(courseId).future);
  final materialsFuture = ref.watch(courseMaterialsProvider(courseId).future);

  final results = await Future.wait([decksFuture, materialsFuture]);
  final decks = results[0] as List;
  final materials = results[1] as List;

  if (decks.isEmpty && materials.isEmpty) return [];

  // Build ordered node list
  final nodes = <JourneyNode>[];
  int pos = 0;
  int contentCount = 0;
  int exerciseIdx = 0;

  /// Pick next exercise type from rotating pool.
  JourneyNodeType nextExercise() {
    final type = _exercisePool[exerciseIdx % _exercisePool.length];
    exerciseIdx++;
    return type;
  }

  // Interleave materials and decks with exercises
  final maxLen =
      materials.length > decks.length ? materials.length : decks.length;

  for (int i = 0; i < maxLen; i++) {
    // Material node
    if (i < materials.length) {
      final m = materials[i];
      nodes.add(JourneyNode(
        id: 'material_${m.id}',
        type: JourneyNodeType.materialReview,
        state: JourneyNodeState.locked,
        title: m.displayTitle,
        subtitle: _materialTypeLabel(m.type),
        xpReward: JourneyNode.defaultXp(JourneyNodeType.materialReview),
        route: Routes.materialViewerPath(courseId, m.id),
        entityId: m.id,
        position: pos++,
      ));
      contentCount++;

      // After every material, add an exercise
      if (contentCount > 0) {
        final exType = nextExercise();
        final meta = _exerciseMeta(exType);
        nodes.add(JourneyNode(
          id: '${exerciseTypeToString(exType)}_${pos}_$courseId',
          type: exType,
          state: JourneyNodeState.locked,
          title: meta.title,
          subtitle: meta.subtitle,
          xpReward: JourneyNode.defaultXp(exType),
          route: Routes.exercisePath(courseId, exerciseTypeToString(exType)),
          position: pos++,
        ));
      }

      // Checkpoint every 3 content nodes
      if (contentCount % 3 == 0) {
        nodes.add(JourneyNode(
          id: 'checkpoint_$pos',
          type: JourneyNodeType.checkpoint,
          state: JourneyNodeState.locked,
          title: 'Checkpoint',
          subtitle: '5 quick questions',
          xpReward: JourneyNode.defaultXp(JourneyNodeType.checkpoint),
          route: '${Routes.practiceExam}?courseId=$courseId',
          position: pos++,
        ));

        // Add a reward after each checkpoint
        nodes.add(JourneyNode(
          id: 'reward_checkpoint_$pos',
          type: JourneyNodeType.reward,
          state: JourneyNodeState.locked,
          title: 'Reward Chest',
          subtitle: '+50 XP',
          xpReward: JourneyNode.defaultXp(JourneyNodeType.reward),
          position: pos++,
        ));
      }
    }

    // Deck node
    if (i < decks.length) {
      final d = decks[i];
      nodes.add(JourneyNode(
        id: 'flashcard_${d.id}',
        type: JourneyNodeType.flashcardReview,
        state: JourneyNodeState.locked,
        title: d.displayTitle,
        subtitle: '${d.cardCount} cards',
        xpReward: JourneyNode.defaultXp(JourneyNodeType.flashcardReview),
        route: Routes.flashcardSessionPath(d.id),
        entityId: d.id,
        position: pos++,
      ));
      contentCount++;

      // Add varied exercise after deck too
      final exType = nextExercise();
      final meta = _exerciseMeta(exType);
      nodes.add(JourneyNode(
        id: '${exerciseTypeToString(exType)}_${pos}_$courseId',
        type: exType,
        state: JourneyNodeState.locked,
        title: meta.title,
        subtitle: meta.subtitle,
        xpReward: JourneyNode.defaultXp(exType),
        route: Routes.exercisePath(courseId, exerciseTypeToString(exType)),
        position: pos++,
      ));

      if (contentCount % 3 == 0) {
        nodes.add(JourneyNode(
          id: 'checkpoint_$pos',
          type: JourneyNodeType.checkpoint,
          state: JourneyNodeState.locked,
          title: 'Checkpoint',
          subtitle: '5 quick questions',
          xpReward: JourneyNode.defaultXp(JourneyNodeType.checkpoint),
          route: '${Routes.practiceExam}?courseId=$courseId',
          position: pos++,
        ));
      }
    }
  }

  // ── Tail nodes: Teach Bot → Quiz → Reward → Boss Exam ──

  // Replace old "Oracle" with "Teach the Bot" (actually useful)
  nodes.add(JourneyNode(
    id: 'teachbot_$courseId',
    type: JourneyNodeType.teachBot,
    state: JourneyNodeState.locked,
    title: 'Teach the Bot',
    subtitle: 'Explain it in your words',
    xpReward: JourneyNode.defaultXp(JourneyNodeType.teachBot),
    route: Routes.exercisePath(courseId, 'teachBot'),
    position: pos++,
  ));

  nodes.add(JourneyNode(
    id: 'quiz_$courseId',
    type: JourneyNodeType.quiz,
    state: JourneyNodeState.locked,
    title: 'Practice Quiz',
    subtitle: 'Test your knowledge',
    xpReward: JourneyNode.defaultXp(JourneyNodeType.quiz),
    route: '${Routes.practiceExam}?courseId=$courseId',
    position: pos++,
  ));

  nodes.add(JourneyNode(
    id: 'reward_$courseId',
    type: JourneyNodeType.reward,
    state: JourneyNodeState.locked,
    title: 'Reward Chest',
    subtitle: '+50 XP',
    xpReward: JourneyNode.defaultXp(JourneyNodeType.reward),
    position: pos++,
  ));

  nodes.add(JourneyNode(
    id: 'boss_$courseId',
    type: JourneyNodeType.bossExam,
    state: JourneyNodeState.locked,
    title: 'Final Exam',
    subtitle: 'Comprehensive test',
    xpReward: JourneyNode.defaultXp(JourneyNodeType.bossExam),
    route: '${Routes.practiceExam}?courseId=$courseId',
    position: pos++,
  ));

  // ── Load completion state ──
  final prefs = await SharedPreferences.getInstance();
  final completedIds = _loadCompleted(prefs, courseId);
  final completedDates = _loadCompletedDates(prefs, courseId);

  // ── Load scores for difficulty estimation ──
  final scores = _loadScores(prefs, courseId);

  // ── Assign states + difficulty + scores ──
  bool foundActive = false;
  final resolved = nodes.map((node) {
    // Determine difficulty from past scores
    final difficulty = _estimateDifficulty(node.id, scores);
    final bestScore = scores[node.id];
    final completedAt = completedDates[node.id];

    if (completedIds.contains(node.id)) {
      return node.copyWith(
        state: JourneyNodeState.completed,
        difficulty: difficulty,
        bestScore: bestScore,
        completedAt: completedAt,
      );
    } else if (!foundActive) {
      foundActive = true;
      return node.copyWith(
        state: JourneyNodeState.active,
        difficulty: difficulty,
      );
    }
    return node.copyWith(difficulty: difficulty);
  }).toList();

  return resolved;
});

// ═══════════════════════════════════════════════════════════════════════════════
// Helper Functions
// ═══════════════════════════════════════════════════════════════════════════════

String _materialTypeLabel(String type) {
  switch (type) {
    case 'pdf':
      return 'PDF Document';
    case 'audio':
      return 'Audio';
    case 'notes':
      return 'Notes';
    case 'paste':
      return 'Pasted Text';
    default:
      return 'Material';
  }
}

Set<String> _loadCompleted(SharedPreferences prefs, String courseId) {
  final raw = prefs.getString('journey_v1_$courseId');
  if (raw == null) return {};
  try {
    final list = (jsonDecode(raw) as List).cast<String>();
    return list.toSet();
  } catch (_) {
    return {};
  }
}

Map<String, DateTime> _loadCompletedDates(
    SharedPreferences prefs, String courseId) {
  final raw = prefs.getString('journey_dates_$courseId');
  if (raw == null) return {};
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, DateTime.parse(v as String)));
  } catch (_) {
    return {};
  }
}

Map<String, int> _loadScores(SharedPreferences prefs, String courseId) {
  final raw = prefs.getString('exercise_scores_$courseId');
  if (raw == null) return {};
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as int));
  } catch (_) {
    return {};
  }
}

/// Estimate difficulty based on average score for related exercises.
NodeDifficulty _estimateDifficulty(String nodeId, Map<String, int> scores) {
  if (scores.isEmpty) return NodeDifficulty.medium;

  // Check if this specific node has a score
  final score = scores[nodeId];
  if (score != null) {
    if (score >= 80) return NodeDifficulty.easy;
    if (score >= 50) return NodeDifficulty.medium;
    return NodeDifficulty.hard;
  }

  // Default to medium
  return NodeDifficulty.medium;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Journey Completion Manager
// ═══════════════════════════════════════════════════════════════════════════════

/// Manages which journey nodes are completed for a course.
///
/// Persists to SharedPreferences (local-only v1 — does not sync across
/// devices or reinstall).
class JourneyCompletionNotifier extends StateNotifier<Set<String>> {
  final String courseId;
  final Ref _ref;

  JourneyCompletionNotifier(this.courseId, this._ref) : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = _loadCompleted(prefs, courseId);
  }

  Future<void> markCompleted(String nodeId, int xpAmount) async {
    if (state.contains(nodeId)) return;

    // Update local state
    state = {...state, nodeId};

    // Persist completion
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'journey_v1_$courseId', jsonEncode(state.toList()));

    // Persist completion date
    final datesRaw = prefs.getString('journey_dates_$courseId');
    Map<String, dynamic> dates = {};
    if (datesRaw != null) {
      try {
        dates = jsonDecode(datesRaw) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Journey: parse completion dates failed: $e');
      }
    }
    dates[nodeId] = DateTime.now().toIso8601String();
    await prefs.setString('journey_dates_$courseId', jsonEncode(dates));

    // Apply streak multiplier
    final multiplier =
        _ref.read(streakMultiplierProvider.notifier).multiplier;
    final finalXp = xpAmount * multiplier;

    // Award XP
    try {
      await _ref.read(xpRepositoryProvider).awardXp(
            action: 'journey_node',
            amount: finalXp,
            metadata: {
              'nodeId': nodeId,
              'multiplier': multiplier,
            },
          );
    } catch (e) {
      debugPrint('Journey: award XP failed: $e');
    }

    // Refresh the nodes
    _ref.invalidate(journeyNodesProvider(courseId));
  }
}

final journeyCompletionProvider = StateNotifierProvider.family<
    JourneyCompletionNotifier, Set<String>, String>(
  (ref, courseId) => JourneyCompletionNotifier(courseId, ref),
);

// ═══════════════════════════════════════════════════════════════════════════════
// Derived Providers
// ═══════════════════════════════════════════════════════════════════════════════

/// Journey completion progress (0.0–1.0) for a course.
final journeyProgressProvider =
    Provider.autoDispose.family<double, String>((ref, courseId) {
  final nodes = ref
      .watch(journeyNodesProvider(courseId))
      .whenOrNull(data: (n) => n);
  if (nodes == null || nodes.isEmpty) return 0.0;
  final completed =
      nodes.where((n) => n.state == JourneyNodeState.completed).length;
  return completed / nodes.length;
});

/// The active (current) node for a course journey, if any.
final activeJourneyNodeProvider =
    Provider.autoDispose.family<JourneyNode?, String>((ref, courseId) {
  final nodes = ref
      .watch(journeyNodesProvider(courseId))
      .whenOrNull(data: (n) => n);
  if (nodes == null || nodes.isEmpty) return null;
  try {
    return nodes.firstWhere((n) => n.state == JourneyNodeState.active);
  } catch (_) {
    return null;
  }
});

/// Picks the most relevant course for the Home journey banner.
///
/// Priority: nearest exam date → lowest progress → first.
final activeJourneyCourseProvider = Provider<String?>((ref) {
  final courses = ref
      .watch(coursesProvider)
      .whenOrNull(data: (c) => c);
  if (courses == null || courses.isEmpty) return null;

  // Prefer course with nearest exam
  final withExam = courses.where((c) => c.examDate != null).toList()
    ..sort((a, b) => a.examDate!.compareTo(b.examDate!));
  if (withExam.isNotEmpty) return withExam.first.id;

  // Then lowest progress
  final byProgress = [...courses]
    ..sort((a, b) => a.progress.compareTo(b.progress));
  return byProgress.first.id;
});

/// Index of the first checkpoint node (used for paywall gating).
///
/// Free users can play up to and including the first checkpoint.
/// Returns null if no checkpoint exists (gate at position 3 fallback).
final firstCheckpointIndexProvider =
    Provider.autoDispose.family<int?, String>((ref, courseId) {
  final nodes = ref
      .watch(journeyNodesProvider(courseId))
      .whenOrNull(data: (n) => n);
  if (nodes == null) return null;
  for (int i = 0; i < nodes.length; i++) {
    if (nodes[i].type == JourneyNodeType.checkpoint) return i;
  }
  return null;
});

/// Nodes that need review (completed but with low scores).
final weakNodesProvider =
    Provider.autoDispose.family<List<JourneyNode>, String>((ref, courseId) {
  final nodes = ref
      .watch(journeyNodesProvider(courseId))
      .whenOrNull(data: (n) => n);
  if (nodes == null) return [];
  return nodes
      .where((n) =>
          n.state == JourneyNodeState.completed &&
          n.bestScore != null &&
          n.bestScore! < 70)
      .toList();
});

/// Boss exam topic confidence data.
final bossExamTopicsProvider = Provider.autoDispose
    .family<List<({String topic, double confidence})>, String>(
        (ref, courseId) {
  final nodes = ref
      .watch(journeyNodesProvider(courseId))
      .whenOrNull(data: (n) => n);
  if (nodes == null) return [];

  // Group exercises by type and compute average scores
  final topics = <String, List<int>>{};
  for (final node in nodes) {
    if (node.state == JourneyNodeState.completed && node.bestScore != null) {
      final topic = node.title;
      topics.putIfAbsent(topic, () => []).add(node.bestScore!);
    }
  }

  return topics.entries.map((e) {
    final avg = e.value.fold<int>(0, (s, v) => s + v) / e.value.length;
    return (topic: e.key, confidence: avg / 100.0);
  }).toList()
    ..sort((a, b) => a.confidence.compareTo(b.confidence));
});
