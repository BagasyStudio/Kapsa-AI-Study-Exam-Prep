import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/journey_node_model.dart';

/// Vertical zigzag path of connected journey nodes.
///
/// Renders completed, active, and locked nodes with curved
/// bezier connectors and unlock micro-interactions.
class JourneyPath extends StatefulWidget {
  final List<JourneyNode> nodes;
  final String courseId;
  final void Function(JourneyNode) onNodeTap;

  const JourneyPath({
    super.key,
    required this.nodes,
    required this.courseId,
    required this.onNodeTap,
  });

  @override
  State<JourneyPath> createState() => _JourneyPathState();
}

class _JourneyPathState extends State<JourneyPath>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void didUpdateWidget(covariant JourneyPath oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodes.length != widget.nodes.length) {
      _staggerController.dispose();
      _fadeAnimations.clear();
      _slideAnimations.clear();
      _setupAnimations();
    }
  }

  void _setupAnimations() {
    final count = math.min(widget.nodes.length, AppAnimations.maxStaggerItems);
    if (count == 0) {
      _staggerController = AnimationController(
        vsync: this,
        duration: Duration.zero,
      );
      return;
    }

    final totalMs = AppAnimations.durationEntrance.inMilliseconds +
        (count - 1) * AppAnimations.staggerInterval.inMilliseconds;
    _staggerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    for (int i = 0; i < widget.nodes.length; i++) {
      final staggerIdx = math.min(i, count - 1);
      final startMs = staggerIdx * AppAnimations.staggerInterval.inMilliseconds;
      final endMs = startMs + AppAnimations.durationEntrance.inMilliseconds;
      final begin = startMs / totalMs;
      final end = math.min(endMs / totalMs, 1.0);

      final curved = CurvedAnimation(
        parent: _staggerController,
        curve: Interval(begin, end, curve: AppAnimations.curveEntrance),
      );

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(curved),
      );
      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(curved),
      );
    }

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          for (int i = 0; i < widget.nodes.length; i++) ...[
            // Connector (skip before first node)
            if (i > 0)
              _ConnectorLine(
                fromNode: widget.nodes[i - 1],
                toNode: widget.nodes[i],
                fromIndex: i - 1,
                toIndex: i,
              ),

            // Node with stagger animation
            if (i < _fadeAnimations.length)
              FadeTransition(
                opacity: _fadeAnimations[i],
                child: SlideTransition(
                  position: _slideAnimations[i],
                  child: _PositionedNode(
                    node: widget.nodes[i],
                    index: i,
                    onTap: () => widget.onNodeTap(widget.nodes[i]),
                  ),
                ),
              )
            else
              _PositionedNode(
                node: widget.nodes[i],
                index: i,
                onTap: () => widget.onNodeTap(widget.nodes[i]),
              ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Positioned Node (zigzag layout)
// ═══════════════════════════════════════════════════════════════════════════════

class _PositionedNode extends StatelessWidget {
  final JourneyNode node;
  final int index;
  final VoidCallback onTap;

  const _PositionedNode({
    required this.node,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Active, reward, boss → centered; otherwise zigzag
    final Alignment alignment;
    if (node.state == JourneyNodeState.active || node.isCentered) {
      alignment = Alignment.center;
    } else {
      alignment = index % 2 == 0
          ? const Alignment(-0.45, 0)
          : const Alignment(0.45, 0);
    }

    return Align(
      alignment: alignment,
      child: _buildNodeWidget(),
    );
  }

  Widget _buildNodeWidget() {
    switch (node.state) {
      case JourneyNodeState.completed:
        return _CompletedNode(node: node, onTap: onTap);
      case JourneyNodeState.active:
        if (node.type == JourneyNodeType.reward) {
          return _RewardNode(node: node, onTap: onTap);
        }
        if (node.type == JourneyNodeType.bossExam) {
          return _BossExamNode(node: node, onTap: onTap, isActive: true);
        }
        return _ActiveNode(node: node, onTap: onTap);
      case JourneyNodeState.locked:
        if (node.type == JourneyNodeType.bossExam) {
          return _BossExamNode(node: node, onTap: onTap, isActive: false);
        }
        return _LockedNode(node: node, onTap: onTap);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Completed Node — solid fill, 72px, drop shadow, star badge
// ═══════════════════════════════════════════════════════════════════════════════

class _CompletedNode extends StatelessWidget {
  final JourneyNode node;
  final VoidCallback onTap;

  const _CompletedNode({required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = node.accentColor;

    return TapScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main circle — solid gradient fill + shadow
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          accent,
                          accent.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: accent.withValues(alpha: 0.15),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        node.assetPath,
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                ),
                // Star check badge (bottom-right)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: AppAnimations.durationMedium,
                    curve: AppAnimations.curveBounce,
                    builder: (_, value, child) => Transform.scale(
                      scale: value,
                      child: child,
                    ),
                    child: Image.asset(
                      'assets/images/journey/star_check.png',
                      width: 28,
                      height: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 100,
            child: Text(
              node.title,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: Colors.white54,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Active Node — expanded card, breathing glow + bounce, UP NEXT badge
// ═══════════════════════════════════════════════════════════════════════════════

class _ActiveNode extends StatefulWidget {
  final JourneyNode node;
  final VoidCallback onTap;

  const _ActiveNode({required this.node, required this.onTap});

  @override
  State<_ActiveNode> createState() => _ActiveNodeState();
}

class _ActiveNodeState extends State<_ActiveNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: AppAnimations.durationBreathing,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.10, end: 0.30).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.node.accentColor;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: TapScale(
            onTap: widget.onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // UP NEXT pill
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ctaLime,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ctaLime.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'UP NEXT',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.ctaLimeText,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                // Card
                Container(
                  width: 220,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.immersiveCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.45),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: _glowAnimation.value),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: accent.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Asset image circle
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              accent,
                              accent.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.40),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            widget.node.assetPath,
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Title
                      Text(
                        widget.node.title,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        widget.node.subtitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // CTA button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ctaLime,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ctaLime.withValues(alpha: 0.30),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'CONTINUE',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.ctaLimeText,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // XP pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ctaLime.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '+${widget.node.xpReward} XP',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.ctaLime,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Locked Node — 68px, drop shadow, dimmed asset, locked chest badge
// ═══════════════════════════════════════════════════════════════════════════════

class _LockedNode extends StatelessWidget {
  final JourneyNode node;
  final VoidCallback onTap;

  const _LockedNode({required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = node.accentColor;

    return TapScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main circle — subtle fill + shadow
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.08),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.18),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Opacity(
                      opacity: 0.40,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          node.assetPath,
                          width: 40,
                          height: 40,
                          color: Colors.white,
                          colorBlendMode: BlendMode.saturation,
                        ),
                      ),
                    ),
                  ),
                ),
                // Locked chest badge (bottom-right)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    'assets/images/journey/chest_locked.png',
                    width: 28,
                    height: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Title
          SizedBox(
            width: 100,
            child: Text(
              node.title,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: Colors.white30,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // XP label
          const SizedBox(height: 2),
          Text(
            '+${node.xpReward} XP',
            style: AppTypography.caption.copyWith(
              color: accent.withValues(alpha: 0.30),
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Reward Node (active — floating chest with gold CTA)
// ═══════════════════════════════════════════════════════════════════════════════

class _RewardNode extends StatefulWidget {
  final JourneyNode node;
  final VoidCallback onTap;

  const _RewardNode({required this.node, required this.onTap});

  @override
  State<_RewardNode> createState() => _RewardNodeState();
}

class _RewardNodeState extends State<_RewardNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.20),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating chest
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: child,
              ),
              child: Image.asset(
                'assets/images/journey/chest_open.png',
                width: 72,
                height: 72,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reward Chest',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '+${widget.node.xpReward} XP',
              style: AppTypography.caption.copyWith(
                color: const Color(0xFFFBBF24),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'OPEN',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Boss Exam Node (larger shield with drop shadow)
// ═══════════════════════════════════════════════════════════════════════════════

class _BossExamNode extends StatelessWidget {
  final JourneyNode node;
  final VoidCallback onTap;
  final bool isActive;

  const _BossExamNode({
    required this.node,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      // Locked boss exam
      return TapScale(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Boss shield (dimmed) with shadow
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity: 0.40,
                        child: Image.asset(
                          'assets/images/journey/shield_boss.png',
                          width: 64,
                          height: 64,
                        ),
                      ),
                    ),
                  ),
                  // Locked chest badge
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Image.asset(
                      'assets/images/journey/chest_locked.png',
                      width: 28,
                      height: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'FINAL EXAM',
              style: AppTypography.caption.copyWith(
                color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '+${node.xpReward} XP',
              style: AppTypography.caption.copyWith(
                color: const Color(0xFFEF4444).withValues(alpha: 0.30),
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
            ),
          ],
        ),
      );
    }

    // Active boss exam
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.45),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.20),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/journey/shield_boss.png',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Final Exam',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Comprehensive test',
              style: AppTypography.caption.copyWith(
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '+${node.xpReward} XP',
              style: AppTypography.caption.copyWith(
                color: const Color(0xFFFCA5A5),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'START EXAM',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Connector Line — thicker bezier curves, brighter completed gradient
// ═══════════════════════════════════════════════════════════════════════════════

class _ConnectorLine extends StatelessWidget {
  final JourneyNode fromNode;
  final JourneyNode toNode;
  final int fromIndex;
  final int toIndex;

  const _ConnectorLine({
    required this.fromNode,
    required this.toNode,
    required this.fromIndex,
    required this.toIndex,
  });

  double _alignmentX(JourneyNode node, int index) {
    if (node.state == JourneyNodeState.active || node.isCentered) return 0.0;
    return index % 2 == 0 ? -0.45 : 0.45;
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = fromNode.state == JourneyNodeState.completed &&
        toNode.state == JourneyNodeState.completed;
    final isNextActive = fromNode.state == JourneyNodeState.completed &&
        toNode.state == JourneyNodeState.active;

    const height = 56.0;
    final Color lineColor;
    final double strokeWidth;
    final bool isDashed;

    if (isCompleted || isNextActive) {
      lineColor = AppColors.ctaLime.withValues(alpha: 0.65);
      strokeWidth = 3.5;
      isDashed = false;
    } else {
      lineColor = AppColors.immersiveBorder.withValues(alpha: 0.6);
      strokeWidth = 2.5;
      isDashed = true;
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ConnectorPainter(
          color: lineColor,
          strokeWidth: strokeWidth,
          isDashed: isDashed,
          fromAlignX: _alignmentX(fromNode, fromIndex),
          toAlignX: _alignmentX(toNode, toIndex),
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool isDashed;
  final double fromAlignX;
  final double toAlignX;

  _ConnectorPainter({
    required this.color,
    required this.strokeWidth,
    required this.isDashed,
    required this.fromAlignX,
    required this.toAlignX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final startX = centerX + (fromAlignX * centerX);
    final endX = centerX + (toAlignX * centerX);
    final midY = size.height / 2;

    final path = Path();
    path.moveTo(startX, 0);
    path.cubicTo(
      startX, midY,
      endX, midY,
      endX, size.height,
    );

    if (isDashed) {
      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        const dashLength = 7.0;
        const dashGap = 5.0;
        while (distance < metric.length) {
          final nextDash = math.min(distance + dashLength, metric.length);
          final extractedPath = metric.extractPath(distance, nextDash);
          canvas.drawPath(extractedPath, paint);
          distance = nextDash + dashGap;
        }
      }
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      isDashed != oldDelegate.isDashed ||
      fromAlignX != oldDelegate.fromAlignX ||
      toAlignX != oldDelegate.toAlignX;
}
