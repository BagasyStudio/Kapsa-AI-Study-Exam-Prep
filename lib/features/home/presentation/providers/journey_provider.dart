import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/navigation/routes.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../data/models/journey_node_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Journey Node Generation
// ═══════════════════════════════════════════════════════════════════════════════

/// Generates the journey node sequence for a course from existing data.
///
/// Algorithm:
/// 1. Fetch materials + parent decks for the course
/// 2. Interleave: material → deck → material → deck → checkpoint ...
/// 3. Append tail nodes: oracle → quiz → reward → boss exam
/// 4. Load completion state from SharedPreferences
/// 5. Assign states: completed / active / locked
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

  // Interleave materials and decks
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
        title: 'Review: ${m.displayTitle}',
        subtitle: _materialTypeLabel(m.type),
        xpReward: JourneyNode.defaultXp(JourneyNodeType.materialReview),
        route: Routes.materialViewerPath(courseId, m.id),
        entityId: m.id,
        position: pos++,
      ));
      contentCount++;

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
      }
    }

    // Deck node
    if (i < decks.length) {
      final d = decks[i];
      nodes.add(JourneyNode(
        id: 'flashcard_${d.id}',
        type: JourneyNodeType.flashcardReview,
        state: JourneyNodeState.locked,
        title: 'Flashcards: ${d.displayTitle}',
        subtitle: '${d.cardCount} cards',
        xpReward: JourneyNode.defaultXp(JourneyNodeType.flashcardReview),
        route: Routes.deckDetailPath(d.id),
        entityId: d.id,
        position: pos++,
      ));
      contentCount++;

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

  // Tail nodes: oracle → quiz → reward → boss exam
  nodes.add(JourneyNode(
    id: 'oracle_$courseId',
    type: JourneyNodeType.oracle,
    state: JourneyNodeState.locked,
    title: 'Ask the Oracle',
    subtitle: 'AI-powered Q&A',
    xpReward: JourneyNode.defaultXp(JourneyNodeType.oracle),
    route: Routes.chatPath(courseId),
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

  // Load completion state
  final prefs = await SharedPreferences.getInstance();
  final completedIds = _loadCompleted(prefs, courseId);

  // Assign states
  bool foundActive = false;
  final resolved = nodes.map((node) {
    if (completedIds.contains(node.id)) {
      return node.copyWithState(JourneyNodeState.completed);
    } else if (!foundActive) {
      foundActive = true;
      return node.copyWithState(JourneyNodeState.active);
    }
    return node; // stays locked
  }).toList();

  return resolved;
});

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

    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'journey_v1_$courseId', jsonEncode(state.toList()));

    // Award XP
    try {
      await _ref
          .read(xpRepositoryProvider)
          .awardXp(action: 'journey_node', amount: xpAmount, metadata: {'nodeId': nodeId});
    } catch (_) {}

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
