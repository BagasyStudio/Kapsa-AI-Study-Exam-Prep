import 'package:flutter/material.dart';

/// Types of nodes on the per-course learning journey.
enum JourneyNodeType {
  flashcardReview,
  quiz,
  materialReview,
  summary,
  oracle,
  checkpoint,
  reward,
  bossExam,
}

/// State of a journey node in the sequential path.
enum JourneyNodeState {
  completed,
  active,
  locked,
}

/// Result returned by destination screens when popped back to the journey.
enum JourneyResult { completed, cancelled }

/// A single node on the per-course learning journey path.
class JourneyNode {
  final String id;
  final JourneyNodeType type;
  final JourneyNodeState state;
  final String title;
  final String subtitle;
  final int xpReward;
  final String? route;
  final String? entityId;
  final int position;

  const JourneyNode({
    required this.id,
    required this.type,
    required this.state,
    required this.title,
    required this.subtitle,
    required this.xpReward,
    this.route,
    this.entityId,
    required this.position,
  });

  JourneyNode copyWithState(JourneyNodeState newState) => JourneyNode(
        id: id,
        type: type,
        state: newState,
        title: title,
        subtitle: subtitle,
        xpReward: xpReward,
        route: route,
        entityId: entityId,
        position: position,
      );

  /// Whether this node is always rendered centered (not zigzag).
  bool get isCentered =>
      type == JourneyNodeType.reward || type == JourneyNodeType.bossExam;

  /// Icon for this node type (fallback for non-journey contexts).
  IconData get icon => _iconMap[type]!;

  /// Asset image path for this node type.
  String get assetPath => _assetMap[type]!;

  /// Accent color for this node type.
  Color get accentColor => _colorMap[type]!;

  static const _iconMap = <JourneyNodeType, IconData>{
    JourneyNodeType.flashcardReview: Icons.style_rounded,
    JourneyNodeType.quiz: Icons.quiz_rounded,
    JourneyNodeType.materialReview: Icons.description_rounded,
    JourneyNodeType.summary: Icons.auto_stories_rounded,
    JourneyNodeType.oracle: Icons.psychology_alt,
    JourneyNodeType.checkpoint: Icons.flag_rounded,
    JourneyNodeType.reward: Icons.card_giftcard_rounded,
    JourneyNodeType.bossExam: Icons.workspace_premium_rounded,
  };

  static const _assetMap = <JourneyNodeType, String>{
    JourneyNodeType.flashcardReview: 'assets/images/journey/flashcard.png',
    JourneyNodeType.quiz: 'assets/images/journey/quiz.png',
    JourneyNodeType.materialReview: 'assets/images/journey/book.png',
    JourneyNodeType.summary: 'assets/images/journey/scroll.png',
    JourneyNodeType.oracle: 'assets/images/journey/crystal_ball.png',
    JourneyNodeType.checkpoint: 'assets/images/journey/flag.png',
    JourneyNodeType.reward: 'assets/images/journey/chest_open.png',
    JourneyNodeType.bossExam: 'assets/images/journey/shield_boss.png',
  };

  static const _colorMap = <JourneyNodeType, Color>{
    JourneyNodeType.flashcardReview: Color(0xFFF59E0B),
    JourneyNodeType.quiz: Color(0xFF3B82F6),
    JourneyNodeType.materialReview: Color(0xFF8B5CF6),
    JourneyNodeType.summary: Color(0xFF06B6D4),
    JourneyNodeType.oracle: Color(0xFF6467F2),
    JourneyNodeType.checkpoint: Color(0xFF10B981),
    JourneyNodeType.reward: Color(0xFFF59E0B),
    JourneyNodeType.bossExam: Color(0xFFEF4444),
  };

  static const _xpMap = <JourneyNodeType, int>{
    JourneyNodeType.flashcardReview: 15,
    JourneyNodeType.quiz: 25,
    JourneyNodeType.materialReview: 10,
    JourneyNodeType.summary: 10,
    JourneyNodeType.oracle: 20,
    JourneyNodeType.checkpoint: 30,
    JourneyNodeType.reward: 50,
    JourneyNodeType.bossExam: 100,
  };

  /// Default XP for a given node type.
  static int defaultXp(JourneyNodeType type) => _xpMap[type] ?? 10;
}
