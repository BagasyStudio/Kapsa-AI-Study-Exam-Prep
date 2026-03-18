import 'package:flutter/material.dart';

/// Types of nodes on the per-course learning journey.
enum JourneyNodeType {
  flashcardReview,
  quiz,
  materialReview,
  summary,
  oracle, // Legacy — replaced by teachBot
  checkpoint,
  reward,
  bossExam,
  // ── New exercise types ──
  fillGaps,
  speedRound,
  mistakeSpotter,
  teachBot,
  compareContrast,
  timelineBuilder,
  caseStudy,
  matchBlitz,
  conceptMapper,
  dailyChallenge,
}

/// State of a journey node in the sequential path.
enum JourneyNodeState {
  completed,
  active,
  locked,
}

/// Result returned by destination screens when popped back to the journey.
enum JourneyResult { completed, cancelled }

/// Difficulty tier for a node (based on student performance).
enum NodeDifficulty {
  easy,
  medium,
  hard,
}

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
  final NodeDifficulty difficulty;
  final int? bestScore;
  final DateTime? completedAt;
  final bool isBranch;
  final String? branchPairId;

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
    this.difficulty = NodeDifficulty.medium,
    this.bestScore,
    this.completedAt,
    this.isBranch = false,
    this.branchPairId,
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
        difficulty: difficulty,
        bestScore: bestScore,
        completedAt: completedAt,
        isBranch: isBranch,
        branchPairId: branchPairId,
      );

  JourneyNode copyWith({
    String? id,
    JourneyNodeType? type,
    JourneyNodeState? state,
    String? title,
    String? subtitle,
    int? xpReward,
    String? route,
    String? entityId,
    int? position,
    NodeDifficulty? difficulty,
    int? bestScore,
    DateTime? completedAt,
    bool? isBranch,
    String? branchPairId,
  }) =>
      JourneyNode(
        id: id ?? this.id,
        type: type ?? this.type,
        state: state ?? this.state,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        xpReward: xpReward ?? this.xpReward,
        route: route ?? this.route,
        entityId: entityId ?? this.entityId,
        position: position ?? this.position,
        difficulty: difficulty ?? this.difficulty,
        bestScore: bestScore ?? this.bestScore,
        completedAt: completedAt ?? this.completedAt,
        isBranch: isBranch ?? this.isBranch,
        branchPairId: branchPairId ?? this.branchPairId,
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

  /// XP multiplier based on difficulty.
  double get difficultyMultiplier => switch (difficulty) {
        NodeDifficulty.easy => 1.0,
        NodeDifficulty.medium => 1.0,
        NodeDifficulty.hard => 1.5,
      };

  /// Effective XP with difficulty multiplier.
  int get effectiveXp => (xpReward * difficultyMultiplier).round();

  static const _iconMap = <JourneyNodeType, IconData>{
    JourneyNodeType.flashcardReview: Icons.style_rounded,
    JourneyNodeType.quiz: Icons.quiz_rounded,
    JourneyNodeType.materialReview: Icons.description_rounded,
    JourneyNodeType.summary: Icons.auto_stories_rounded,
    JourneyNodeType.oracle: Icons.psychology_alt,
    JourneyNodeType.checkpoint: Icons.flag_rounded,
    JourneyNodeType.reward: Icons.card_giftcard_rounded,
    JourneyNodeType.bossExam: Icons.workspace_premium_rounded,
    JourneyNodeType.fillGaps: Icons.text_fields_rounded,
    JourneyNodeType.speedRound: Icons.bolt_rounded,
    JourneyNodeType.mistakeSpotter: Icons.search_rounded,
    JourneyNodeType.teachBot: Icons.school_rounded,
    JourneyNodeType.compareContrast: Icons.compare_arrows_rounded,
    JourneyNodeType.timelineBuilder: Icons.timeline_rounded,
    JourneyNodeType.caseStudy: Icons.cases_rounded,
    JourneyNodeType.matchBlitz: Icons.grid_view_rounded,
    JourneyNodeType.conceptMapper: Icons.hub_rounded,
    JourneyNodeType.dailyChallenge: Icons.local_fire_department_rounded,
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
    // New types reuse existing assets with icon fallback
    JourneyNodeType.fillGaps: 'assets/images/journey/scroll.png',
    JourneyNodeType.speedRound: 'assets/images/journey/quiz.png',
    JourneyNodeType.mistakeSpotter: 'assets/images/journey/book.png',
    JourneyNodeType.teachBot: 'assets/images/journey/crystal_ball.png',
    JourneyNodeType.compareContrast: 'assets/images/journey/book.png',
    JourneyNodeType.timelineBuilder: 'assets/images/journey/scroll.png',
    JourneyNodeType.caseStudy: 'assets/images/journey/book.png',
    JourneyNodeType.matchBlitz: 'assets/images/journey/flashcard.png',
    JourneyNodeType.conceptMapper: 'assets/images/journey/scroll.png',
    JourneyNodeType.dailyChallenge: 'assets/images/journey/xp_burst.png',
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
    JourneyNodeType.fillGaps: Color(0xFF14B8A6),
    JourneyNodeType.speedRound: Color(0xFFF97316),
    JourneyNodeType.mistakeSpotter: Color(0xFFEC4899),
    JourneyNodeType.teachBot: Color(0xFF8B5CF6),
    JourneyNodeType.compareContrast: Color(0xFF6366F1),
    JourneyNodeType.timelineBuilder: Color(0xFF0EA5E9),
    JourneyNodeType.caseStudy: Color(0xFF059669),
    JourneyNodeType.matchBlitz: Color(0xFFE11D48),
    JourneyNodeType.conceptMapper: Color(0xFF7C3AED),
    JourneyNodeType.dailyChallenge: Color(0xFFF59E0B),
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
    JourneyNodeType.fillGaps: 20,
    JourneyNodeType.speedRound: 20,
    JourneyNodeType.mistakeSpotter: 25,
    JourneyNodeType.teachBot: 30,
    JourneyNodeType.compareContrast: 20,
    JourneyNodeType.timelineBuilder: 20,
    JourneyNodeType.caseStudy: 30,
    JourneyNodeType.matchBlitz: 20,
    JourneyNodeType.conceptMapper: 25,
    JourneyNodeType.dailyChallenge: 35,
  };

  /// Default XP for a given node type.
  static int defaultXp(JourneyNodeType type) => _xpMap[type] ?? 10;
}
