import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../data/models/journey_node_model.dart';
import '../providers/journey_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Journey Hero Widget — Premium carousel of per-course journey cards
// ═══════════════════════════════════════════════════════════════════════════════

/// Primary study continuation surface on Home.
///
/// Shows a horizontal snap carousel of premium journey cards — one per course.
/// Each card displays course title, metadata badges, daily challenge tasks,
/// a mini journey preview, and a prominent CTA.
///
/// Hides when there are no courses with content.
class JourneyHeroWidget extends ConsumerWidget {
  const JourneyHeroWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses =
        ref.watch(coursesProvider).whenOrNull(data: (c) => c) ?? [];
    if (courses.isEmpty) return const SizedBox.shrink();

    // Sort: nearest exam → lowest progress → first
    final sorted = [...courses]..sort((a, b) {
        if (a.examDate != null && b.examDate != null) {
          return a.examDate!.compareTo(b.examDate!);
        }
        if (a.examDate != null) return -1;
        if (b.examDate != null) return 1;
        return a.progress.compareTo(b.progress);
      });

    if (sorted.length == 1) {
      // Single course — no carousel, full-width card
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: _JourneyCard(courseId: sorted.first.id),
      );
    }

    // Multiple courses — horizontal snap carousel with side peek
    return SizedBox(
      height: 340,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _JourneyCard(courseId: sorted[index].id),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Individual Journey Card — per-course premium surface
// ═══════════════════════════════════════════════════════════════════════════════

class _JourneyCard extends ConsumerWidget {
  final String courseId;

  const _JourneyCard({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course =
        ref.watch(courseProvider(courseId)).whenOrNull(data: (c) => c);
    final nodesAsync = ref.watch(journeyNodesProvider(courseId));
    final progress = ref.watch(journeyProgressProvider(courseId));
    final activeNode = ref.watch(activeJourneyNodeProvider(courseId));

    return nodesAsync.when(
      loading: () => _LoadingCard(courseName: course?.displayTitle),
      error: (_, __) => const SizedBox.shrink(),
      data: (nodes) {
        if (nodes.isEmpty) return const SizedBox.shrink();

        final allCompleted =
            nodes.every((n) => n.state == JourneyNodeState.completed);

        if (allCompleted) {
          return _CompletedCard(
            courseId: courseId,
            courseName: course?.displayTitle ?? 'Course',
            progress: progress,
          );
        }

        return _ActiveCard(
          courseId: courseId,
          courseName: course?.displayTitle ?? 'Course',
          examDate: course?.examDate,
          progress: progress,
          activeNode: activeNode,
          nodes: nodes,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Active Journey Card
// ═══════════════════════════════════════════════════════════════════════════════

class _ActiveCard extends ConsumerWidget {
  final String courseId;
  final String courseName;
  final DateTime? examDate;
  final double progress;
  final JourneyNode? activeNode;
  final List<JourneyNode> nodes;

  const _ActiveCard({
    required this.courseId,
    required this.courseName,
    this.examDate,
    required this.progress,
    this.activeNode,
    required this.nodes,
  });

  static String _ctaText(JourneyNode? node) {
    if (node == null) return 'Continue Journey';
    return switch (node.type) {
      JourneyNodeType.flashcardReview => 'Review Flashcards',
      JourneyNodeType.quiz => 'Take Quiz',
      JourneyNodeType.materialReview => 'Review Material',
      JourneyNodeType.summary => 'Read Summary',
      JourneyNodeType.oracle => 'Ask the Oracle',
      JourneyNodeType.checkpoint => 'Take Checkpoint',
      JourneyNodeType.reward => 'Claim Reward',
      JourneyNodeType.bossExam => 'Start Final Exam',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakDays = ref.watch(profileProvider.select(
          (async) => async.whenOrNull(data: (p) => p?.streakDays),
        )) ??
        0;
    final level = ref.watch(xpLevelProvider);
    final isPro =
        ref.watch(isProProvider).whenOrNull(data: (v) => v) ?? false;

    // Daily challenge: next 2-3 incomplete nodes
    final challenges = nodes
        .where((n) => n.state != JourneyNodeState.completed)
        .take(3)
        .toList();
    final totalChallengeXp =
        challenges.fold<int>(0, (sum, n) => sum + n.xpReward);

    // Mini path preview: 2 completed + active + 2 locked
    final activeIdx = nodes.indexWhere((n) => n.state == JourneyNodeState.active);
    final previewStart = math.max(0, activeIdx - 2);
    final previewEnd = math.min(nodes.length, activeIdx + 3);
    final previewNodes =
        activeIdx >= 0 ? nodes.sublist(previewStart, previewEnd) : <JourneyNode>[];

    return TapScale(
      onTap: () => context.push(Routes.journeyPath(courseId)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.immersiveBorder.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Atmospheric gradient blobs
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6467F2).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF06B6D4).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Title Row ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              courseName,
                              style: AppTypography.h4.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Learning Journey',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white38,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Progress ring
                      _MiniProgressRing(progress: progress),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Metadata Badges ──
                  Row(
                    children: [
                      if (streakDays > 0)
                        _Badge(
                          label: '$streakDays🔥',
                        ),
                      if (streakDays > 0) const SizedBox(width: 6),
                      _Badge(label: 'Lvl $level'),
                      if (examDate != null) ...[
                        const SizedBox(width: 6),
                        _ExamBadge(examDate: examDate!),
                      ],
                      if (!isPro) ...[
                        const SizedBox(width: 6),
                        _Badge(
                          label: 'Free',
                          color: Colors.white24,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Daily Challenge ──
                  if (challenges.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TODAY'S CHALLENGE",
                          style: AppTypography.caption.copyWith(
                            color: Colors.white30,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.ctaLime.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '+$totalChallengeXp XP',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.ctaLime,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...challenges.map((node) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Image.asset(
                                node.assetPath,
                                width: 22,
                                height: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  node.title,
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '+${node.xpReward}',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white24,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 4),
                  ],

                  // ── Mini Journey Preview ──
                  if (previewNodes.isNotEmpty) ...[
                    SizedBox(
                      height: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < previewNodes.length; i++) ...[
                            if (i > 0) _MiniConnector(
                              isCompleted:
                                  previewNodes[i - 1].state ==
                                          JourneyNodeState.completed &&
                                      previewNodes[i].state !=
                                          JourneyNodeState.locked,
                            ),
                            _MiniNode(node: previewNodes[i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // ── CTA Button ──
                  Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.ctaLime,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ctaLime.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _ctaText(activeNode),
                        textAlign: TextAlign.center,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.ctaLimeText,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
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
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Loading / Generating Card
// ═══════════════════════════════════════════════════════════════════════════════

class _LoadingCard extends StatefulWidget {
  final String? courseName;

  const _LoadingCard({this.courseName});

  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shimmer = Colors.white.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.immersiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          if (widget.courseName != null)
            Text(
              widget.courseName!,
              style: AppTypography.h4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Container(
              width: 160,
              height: 20,
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          const SizedBox(height: 4),
          Container(
            width: 100,
            height: 12,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: BorderRadius.circular(6),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Shimmer path nodes
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Row(
                  children: [
                    if (i > 0)
                      Container(
                        width: 20,
                        height: 2,
                        color: shimmer,
                      ),
                    Container(
                      width: i == 2 ? 40 : 28,
                      height: i == 2 ? 40 : 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: shimmer,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Loading text
          Center(
            child: FadeTransition(
              opacity: _pulseAnimation,
              child: Text(
                'Generating your learning journey...',
                style: AppTypography.caption.copyWith(
                  color: AppColors.ctaLime,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Shimmer CTA
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Completed / Caught-Up Card
// ═══════════════════════════════════════════════════════════════════════════════

class _CompletedCard extends StatelessWidget {
  final String courseId;
  final String courseName;
  final double progress;

  const _CompletedCard({
    required this.courseId,
    required this.courseName,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () => context.push(Routes.journeyPath(courseId)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/journey/star_check.png',
              width: 48,
              height: 48,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Journey Complete!',
              style: AppTypography.h4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              courseName,
              style: AppTypography.caption.copyWith(
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'Review Journey',
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
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
// Mini Components
// ═══════════════════════════════════════════════════════════════════════════════

/// Compact progress ring for the card header.
class _MiniProgressRing extends StatelessWidget {
  final double progress;

  const _MiniProgressRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _ProgressRingPainter(progress: progress),
        child: Center(
          child: Text(
            '$percent%',
            style: AppTypography.caption.copyWith(
              color: AppColors.ctaLime,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

/// Metadata badge pill.
class _Badge extends StatelessWidget {
  final String label;
  final Color? color;

  const _Badge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Exam countdown badge with amber accent.
class _ExamBadge extends StatelessWidget {
  final DateTime examDate;

  const _ExamBadge({required this.examDate});

  @override
  Widget build(BuildContext context) {
    final daysLeft = examDate.difference(DateTime.now()).inDays;
    final text = daysLeft <= 0 ? 'Today!' : '${daysLeft}d';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        '📅 $text',
        style: AppTypography.caption.copyWith(
          color: const Color(0xFFFBBF24),
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Mini node circle for the journey preview strip.
class _MiniNode extends StatelessWidget {
  final JourneyNode node;

  const _MiniNode({required this.node});

  @override
  Widget build(BuildContext context) {
    final isActive = node.state == JourneyNodeState.active;
    final isCompleted = node.state == JourneyNodeState.completed;
    final accent = node.accentColor;
    final size = isActive ? 44.0 : 28.0;

    if (isActive) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Image.asset(node.assetPath),
        ),
      );
    }

    if (isCompleted) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Image.asset(node.assetPath),
        ),
      );
    }

    // Locked
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Opacity(
        opacity: 0.30,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Image.asset(node.assetPath),
        ),
      ),
    );
  }
}

/// Mini connector line between preview nodes.
class _MiniConnector extends StatelessWidget {
  final bool isCompleted;

  const _MiniConnector({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 2.5,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.ctaLime.withValues(alpha: 0.50)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Circular progress ring painter.
class _ProgressRingPainter extends CustomPainter {
  final double progress;

  _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = AppColors.ctaLime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      progress != old.progress;
}
