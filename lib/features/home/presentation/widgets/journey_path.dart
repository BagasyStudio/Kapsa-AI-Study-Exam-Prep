import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/journey_node_model.dart';

/// Duolingo-style vertical path of connected journey nodes.
///
/// Renders nodes along a sinusoidal wave: completed = check circles,
/// active = bouncing hero circle, locked = dim numbered circles.
class JourneyPath extends StatefulWidget {
  final List<JourneyNode> nodes;
  final String courseId;
  final void Function(JourneyNode) onNodeTap;
  final bool isPro;
  final int? gateIndex;

  const JourneyPath({
    super.key,
    required this.nodes,
    required this.courseId,
    required this.onNodeTap,
    this.isPro = true,
    this.gateIndex,
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
      final startMs =
          staggerIdx * AppAnimations.staggerInterval.inMilliseconds;
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

  /// Sinusoidal horizontal offset for node at [index].
  /// Returns value in [-1, 1] range for alignment.
  double _waveOffset(int index, JourneyNode node) {
    if (node.isCentered) return 0.0;
    // Gentle sine wave with period of 4 nodes
    return math.sin(index * math.pi / 2) * 0.50;
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
              _ConnectorSegment(
                fromNode: widget.nodes[i - 1],
                toNode: widget.nodes[i],
                fromOffset: _waveOffset(i - 1, widget.nodes[i - 1]),
                toOffset: _waveOffset(i, widget.nodes[i]),
              ),

            // Node with stagger animation
            if (i < _fadeAnimations.length)
              FadeTransition(
                opacity: _fadeAnimations[i],
                child: SlideTransition(
                  position: _slideAnimations[i],
                  child: _buildNode(i),
                ),
              )
            else
              _buildNode(i),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildNode(int i) {
    final node = widget.nodes[i];
    final alignment = Alignment(_waveOffset(i, node), 0);
    final premiumGated =
        !widget.isPro && node.position > (widget.gateIndex ?? 3);

    return Align(
      alignment: alignment,
      child: _NodeRenderer(
        node: node,
        index: i,
        levelNumber: i + 1,
        onTap: () => widget.onNodeTap(node),
        isPremiumGated: premiumGated,
      ),
    );
  }
}

// =============================================================================
// Node Renderer — dispatches to the correct visual based on state/type
// =============================================================================

class _NodeRenderer extends StatelessWidget {
  final JourneyNode node;
  final int index;
  final int levelNumber;
  final VoidCallback onTap;
  final bool isPremiumGated;

  const _NodeRenderer({
    required this.node,
    required this.index,
    required this.levelNumber,
    required this.onTap,
    this.isPremiumGated = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (node.state) {
      case JourneyNodeState.completed:
        return _CompletedCircle(node: node, onTap: onTap);
      case JourneyNodeState.active:
        if (node.type == JourneyNodeType.reward) {
          return _RewardNode(node: node, onTap: onTap);
        }
        if (node.type == JourneyNodeType.bossExam) {
          return _BossNode(node: node, onTap: onTap, isActive: true);
        }
        return _ActiveCircle(node: node, onTap: onTap);
      case JourneyNodeState.locked:
        if (node.type == JourneyNodeType.reward) {
          return _LockedRewardCircle(
              node: node, onTap: onTap, isPremiumGated: isPremiumGated);
        }
        if (node.type == JourneyNodeType.bossExam) {
          return _BossNode(
              node: node,
              onTap: onTap,
              isActive: false,
              isPremiumGated: isPremiumGated);
        }
        return _LockedCircle(
          node: node,
          levelNumber: levelNumber,
          onTap: onTap,
          isPremiumGated: isPremiumGated,
        );
    }
  }
}

// =============================================================================
// Completed Circle — solid accent + white check
// =============================================================================

class _CompletedCircle extends StatelessWidget {
  final JourneyNode node;
  final VoidCallback onTap;

  const _CompletedCircle({required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = node.accentColor;

    return TapScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  accent,
                  Color.lerp(accent, Colors.white, 0.18)!,
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
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 30,
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
                height: 1.2,
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

// =============================================================================
// Active Circle — hero node with breathing glow, asset icon, START CTA
// =============================================================================

class _ActiveCircle extends StatefulWidget {
  final JourneyNode node;
  final VoidCallback onTap;

  const _ActiveCircle({required this.node, required this.onTap});

  @override
  State<_ActiveCircle> createState() => _ActiveCircleState();
}

class _ActiveCircleState extends State<_ActiveCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _glowAlpha;
  late Animation<double> _scale;
  late Animation<double> _ringSize;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: AppAnimations.durationBreathing,
    )..repeat(reverse: true);

    _glowAlpha = Tween<double>(begin: 0.15, end: 0.40).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _ringSize = Tween<double>(begin: 94.0, end: 100.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _bounce = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.node.accentColor;

    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, _) {
        return Transform.scale(
          scale: _scale.value,
          child: TapScale(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "UP NEXT" pill
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.ctaLime,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ctaLime
                            .withValues(alpha: 0.3 + _glowAlpha.value * 0.3),
                        blurRadius: 14,
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

                // Circle with breathing ring
                Transform.translate(
                  offset: Offset(0, _bounce.value),
                  child: SizedBox(
                    width: 108,
                    height: 108,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsing ring
                        Container(
                          width: _ringSize.value,
                          height: _ringSize.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withValues(alpha: 0.40),
                              width: 2.5,
                            ),
                          ),
                        ),
                        // Main circle
                        Container(
                          width: 82,
                          height: 82,
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
                                color:
                                    accent.withValues(alpha: _glowAlpha.value),
                                blurRadius: 32,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: accent.withValues(alpha: 0.20),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 3,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Image.asset(
                              widget.node.assetPath,
                              width: 44,
                              height: 44,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Title
                SizedBox(
                  width: 160,
                  child: Text(
                    widget.node.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.node.subtitle,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 12),

                // START button
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.ctaLime,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ctaLime.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'START',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.ctaLimeText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // XP pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
        );
      },
    );
  }
}

// =============================================================================
// Locked Circle — dim numbered circle with lock badge
// =============================================================================

class _LockedCircle extends StatelessWidget {
  final JourneyNode node;
  final int levelNumber;
  final VoidCallback onTap;
  final bool isPremiumGated;

  const _LockedCircle({
    required this.node,
    required this.levelNumber,
    required this.onTap,
    this.isPremiumGated = false,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main circle — grey with subtle accent tint
                Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.immersiveCard,
                      border: Border.all(
                        color: AppColors.immersiveBorder,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: 0.18,
                        child: Image.asset(
                          node.assetPath,
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                // Lock badge or PRO pill
                Positioned(
                  right: isPremiumGated ? -4 : 4,
                  bottom: 0,
                  child: isPremiumGated ? _proPill() : _lockBadge(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 90,
            child: Text(
              node.title,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: Colors.white24,
                fontSize: 9,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockBadge() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.immersiveCard,
        border: Border.all(
          color: AppColors.immersiveBorder,
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.lock_rounded,
        size: 11,
        color: Colors.white.withValues(alpha: 0.30),
      ),
    );
  }

  Widget _proPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.30),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        'PRO',
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// =============================================================================
// Locked Reward Circle — small locked chest
// =============================================================================

class _LockedRewardCircle extends StatelessWidget {
  final JourneyNode node;
  final VoidCallback onTap;
  final bool isPremiumGated;

  const _LockedRewardCircle({
    required this.node,
    required this.onTap,
    this.isPremiumGated = false,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Opacity(
                    opacity: 0.30,
                    child: Image.asset(
                      'assets/images/journey/chest_locked.png',
                      width: 56,
                      height: 56,
                    ),
                  ),
                ),
                if (isPremiumGated)
                  Positioned(
                    right: -4,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.30),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        'PRO',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 8,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+${node.xpReward} XP',
            style: AppTypography.caption.copyWith(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.25),
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Reward Node (active — floating chest with gold shimmer)
// =============================================================================

class _RewardNode extends StatefulWidget {
  final JourneyNode node;
  final VoidCallback onTap;

  const _RewardNode({required this.node, required this.onTap});

  @override
  State<_RewardNode> createState() => _RewardNodeState();
}

class _RewardNodeState extends State<_RewardNode>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Floating chest with gold glow
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.30),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/journey/chest_open.png',
                    width: 72,
                    height: 72,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reward Chest',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
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
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 14,
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
          );
        },
      ),
    );
  }
}

// =============================================================================
// Boss Node — shield with red glow (active) or dimmed (locked)
// =============================================================================

class _BossNode extends StatelessWidget {
  final JourneyNode node;
  final VoidCallback onTap;
  final bool isActive;
  final bool isPremiumGated;

  const _BossNode({
    required this.node,
    required this.onTap,
    required this.isActive,
    this.isPremiumGated = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
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
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity: 0.28,
                        child: Image.asset(
                          'assets/images/journey/shield_boss.png',
                          width: 64,
                          height: 64,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: isPremiumGated ? -4 : 4,
                    bottom: 0,
                    child: isPremiumGated
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF59E0B),
                                  Color(0xFFF97316)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              'PRO',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 8,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        : Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.immersiveCard,
                              border: Border.all(
                                color: AppColors.immersiveBorder,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 11,
                              color: Colors.white.withValues(alpha: 0.30),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'FINAL EXAM',
              style: AppTypography.caption.copyWith(
                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    // Active boss
    return TapScale(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shield with red glow
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.30),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/journey/shield_boss.png',
              width: 88,
              height: 88,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Final Exam',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Comprehensive test',
            style: AppTypography.caption.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 4),
          Text(
            '+${node.xpReward} XP',
            style: AppTypography.caption.copyWith(
              color: const Color(0xFFFCA5A5),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                  blurRadius: 14,
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
    );
  }
}

// =============================================================================
// Connector Segment — smooth bezier curves between nodes
// =============================================================================

class _ConnectorSegment extends StatelessWidget {
  final JourneyNode fromNode;
  final JourneyNode toNode;
  final double fromOffset;
  final double toOffset;

  const _ConnectorSegment({
    required this.fromNode,
    required this.toNode,
    required this.fromOffset,
    required this.toOffset,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = fromNode.state == JourneyNodeState.completed &&
        (toNode.state == JourneyNodeState.completed ||
            toNode.state == JourneyNodeState.active);

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: CustomPaint(
        painter: _ConnectorPainter(
          isCompleted: isCompleted,
          fromAlignX: fromOffset,
          toAlignX: toOffset,
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final bool isCompleted;
  final double fromAlignX;
  final double toAlignX;

  _ConnectorPainter({
    required this.isCompleted,
    required this.fromAlignX,
    required this.toAlignX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final startX = centerX + (fromAlignX * centerX);
    final endX = centerX + (toAlignX * centerX);
    final midY = size.height / 2;

    final path = Path();
    path.moveTo(startX, 0);
    path.cubicTo(
      startX,
      midY,
      endX,
      midY,
      endX,
      size.height,
    );

    if (isCompleted) {
      // Solid gradient stroke
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.ctaLime.withValues(alpha: 0.65),
            AppColors.ctaLime.withValues(alpha: 0.30),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, paint);
    } else {
      // Dashed locked connector
      final paint = Paint()
        ..color = AppColors.immersiveBorder.withValues(alpha: 0.40)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        const dashLength = 4.0;
        const dashGap = 6.0;
        while (distance < metric.length) {
          final nextDash = math.min(distance + dashLength, metric.length);
          canvas.drawPath(metric.extractPath(distance, nextDash), paint);
          distance = nextDash + dashGap;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      isCompleted != old.isCompleted ||
      fromAlignX != old.fromAlignX ||
      toAlignX != old.toAlignX;
}
