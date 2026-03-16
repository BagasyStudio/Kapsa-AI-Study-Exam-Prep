import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../gamification/presentation/widgets/xp_popup.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../data/models/journey_node_model.dart';
import '../providers/journey_provider.dart';
import '../widgets/journey_path.dart';

/// Full-screen gamified learning journey for a specific course.
///
/// Displays a vertical zigzag path of connected nodes representing
/// study activities (flashcards, quizzes, materials, checkpoints, etc.)
/// with sequential unlock progression and XP rewards.
class JourneyScreen extends ConsumerStatefulWidget {
  final String courseId;

  const JourneyScreen({super.key, required this.courseId});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen>
    with TickerProviderStateMixin {
  String get courseId => widget.courseId;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  late final Animation<double> _pulseAnimation = Tween(begin: 0.3, end: 1.0)
      .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(journeyNodesProvider(courseId));

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: Stack(
        children: [
          // Gradient blobs
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.04),
              ),
            ),
          ),

          SafeArea(
            child: nodesAsync.when(
              loading: () => _buildLoadingState(),
              error: (e, _) => _buildErrorState(),
              data: (nodes) {
                if (nodes.isEmpty) return _buildEmptyState();
                return _buildJourney(nodes);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourney(List<JourneyNode> nodes) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: _JourneyHeader(courseId: courseId),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverToBoxAdapter(
          child: _TodaysChallenge(nodes: nodes),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        SliverToBoxAdapter(
          child: JourneyPath(
            nodes: nodes,
            courseId: courseId,
            onNodeTap: _handleNodeTap,
            isPro: ref.watch(isProProvider).whenOrNull(data: (v) => v) ?? false,
            gateIndex: ref.watch(firstCheckpointIndexProvider(courseId)),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  void _handleNodeTap(JourneyNode node) {
    // Locked nodes → gated logic
    if (node.state == JourneyNodeState.locked) {
      final isPro =
          ref.read(isProProvider).whenOrNull(data: (v) => v) ?? false;
      if (!isPro) {
        final gateIndex =
            ref.read(firstCheckpointIndexProvider(courseId)) ?? 3;
        if (node.position > gateIndex) {
          // Beyond free zone → paywall
          context.push(Routes.paywall);
          return;
        }
      }
      // Within free zone (or pro user) but locked by progression
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the previous step first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Already completed → allow revisiting without re-awarding
    if (node.state == JourneyNodeState.completed) {
      if (node.route != null) context.push(node.route!);
      return;
    }

    // ── Active node ──

    // Reward: celebration + immediate completion
    if (node.type == JourneyNodeType.reward) {
      CelebrationOverlay.show(
        context,
        title: 'Reward Chest!',
        subtitle: '+${node.xpReward} XP',
        icon: Icons.card_giftcard_rounded,
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        _completeNode(node);
      });
      return;
    }

    if (node.route == null) return;

    // Material, Oracle, Summary → complete if user spent ≥ 5s
    if ({JourneyNodeType.materialReview, JourneyNodeType.oracle, JourneyNodeType.summary}
        .contains(node.type)) {
      final startTime = DateTime.now();
      context.push(node.route!).then((_) {
        if (!mounted) return;
        final elapsed = DateTime.now().difference(startTime);
        if (elapsed.inSeconds >= 5) {
          _completeNode(node);
        }
      });
      return;
    }

    // Flashcard, Quiz, Checkpoint, Boss → complete only with explicit result
    context.push<JourneyResult>(node.route!).then((result) {
      if (!mounted) return;
      if (result == JourneyResult.completed) {
        _completeNode(node);
      }
    });
  }

  void _completeNode(JourneyNode node) {
    HapticFeedback.mediumImpact();
    XpPopup.show(context, xp: node.xpReward, label: node.title);
    ref
        .read(journeyCompletionProvider(courseId).notifier)
        .markCompleted(node.id, node.xpReward);
  }

  // ── Loading State ──────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Title shimmer
                _shimmerBar(200, 28),
                const SizedBox(height: 8),
                _shimmerBar(140, 14),
                const SizedBox(height: AppSpacing.lg),
                // Progress bar shimmer
                _shimmerBar(double.infinity, 6),
                const SizedBox(height: AppSpacing.xxl),
                // Challenge card shimmer
                _shimmerBar(double.infinity, 140, radius: 20),
                const SizedBox(height: AppSpacing.xxl),
                // Path node shimmers
                Center(
                  child: Column(
                    children: [
                      _shimmerNode(),
                      _shimmerConnector(),
                      _shimmerNode(),
                      _shimmerConnector(),
                      _shimmerNodeLarge(),
                      _shimmerConnector(),
                      _shimmerNode(),
                      _shimmerConnector(),
                      _shimmerNode(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _shimmerNode() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
        ),
      );

  Widget _shimmerNodeLarge() => Container(
        width: 180,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.05),
        ),
      );

  Widget _shimmerConnector() => Container(
        width: 2,
        height: 40,
        color: Colors.white.withValues(alpha: 0.04),
      );

  Widget _shimmerBar(double width, double height, {double radius = 8}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: Colors.white.withValues(alpha: 0.06),
        ),
      );

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
          ),
          child: Row(
            children: [
              TapScale(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: const Icon(Icons.arrow_back, size: 20,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No content yet',
                    style: AppTypography.h3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Upload materials to generate your learning journey',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TapScale(
                    onTap: () =>
                        context.push(Routes.courseDetailPath(courseId)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ctaLime,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Upload Material',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.ctaLimeText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Text(
        'Could not load journey',
        style: AppTypography.bodyMedium.copyWith(color: Colors.white60),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Journey Header
// ═══════════════════════════════════════════════════════════════════════════════

class _JourneyHeader extends ConsumerWidget {
  final String courseId;

  const _JourneyHeader({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref
        .watch(courseProvider(courseId))
        .whenOrNull(data: (c) => c);
    final streakDays = ref.watch(profileProvider.select(
          (async) => async.whenOrNull(data: (p) => p?.streakDays),
        )) ??
        0;
    final level = ref.watch(xpLevelProvider);
    final progress = ref.watch(journeyProgressProvider(courseId));
    final progressPercent = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: back + badges
          Row(
            children: [
              TapScale(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: const Icon(Icons.arrow_back, size: 20,
                      color: Colors.white),
                ),
              ),
              const Spacer(),
              // Streak badge
              if (streakDays > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$streakDays',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  'Lvl $level',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            course?.displayTitle ?? 'Course',
            style: AppTypography.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Learning Journey',
            style: AppTypography.caption.copyWith(
              color: Colors.white60,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Progress bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.immersiveCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.immersiveBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$progressPercent% JOURNEY',
                      style: AppTypography.sectionHeader.copyWith(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'LEVEL $level',
                      style: AppTypography.sectionHeader.copyWith(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.ctaLime,
                    ),
                  ),
                ),
                // Exam countdown
                if (course?.examDate != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ExamCountdown(examDate: course!.examDate!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamCountdown extends StatelessWidget {
  final DateTime examDate;

  const _ExamCountdown({required this.examDate});

  @override
  Widget build(BuildContext context) {
    final daysLeft = examDate.difference(DateTime.now()).inDays;
    final text = daysLeft <= 0
        ? 'Exam is today!'
        : '$daysLeft day${daysLeft > 1 ? 's' : ''} to exam';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_rounded,
            size: 14,
            color: Color(0xFFFBBF24),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: const Color(0xFFFBBF24),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Today's Challenge
// ═══════════════════════════════════════════════════════════════════════════════

class _TodaysChallenge extends StatelessWidget {
  final List<JourneyNode> nodes;

  const _TodaysChallenge({required this.nodes});

  @override
  Widget build(BuildContext context) {
    // Pick 3 nodes: mix of completed (today's) + next upcoming
    final challengeNodes = <JourneyNode>[];
    final active = nodes.where((n) => n.state == JourneyNodeState.active);
    final locked = nodes.where((n) => n.state == JourneyNodeState.locked);
    // Add active node first
    challengeNodes.addAll(active.take(1));
    // Fill remaining with locked
    challengeNodes.addAll(locked.take(3 - challengeNodes.length));

    if (challengeNodes.isEmpty) return const SizedBox.shrink();

    final completedCount = 0; // Today's completed tracked separately
    final totalXp = challengeNodes.fold<int>(0, (sum, n) => sum + n.xpReward);
    final progress = challengeNodes.isEmpty
        ? 0.0
        : completedCount / challengeNodes.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with counter pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TODAY'S CHALLENGE",
                  style: AppTypography.sectionHeader.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$completedCount/${challengeNodes.length}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Challenge rows with checkbox states
            ...challengeNodes.asMap().entries.map((entry) {
              final node = entry.value;
              final isCompleted = node.state == JourneyNodeState.completed;
              final isActive = node.state == JourneyNodeState.active;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    // Checkbox circle
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.ctaLime
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.ctaLime
                              : isActive
                                  ? AppColors.ctaLime.withValues(alpha: 0.60)
                                  : Colors.white.withValues(alpha: 0.12),
                          width: isActive ? 2 : 1.5,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 14,
                              color: AppColors.ctaLimeText)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    // Asset icon
                    Opacity(
                      opacity: isCompleted ? 0.5 : 1.0,
                      child: Image.asset(
                        node.assetPath,
                        width: 28,
                        height: 28,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Title
                    Expanded(
                      child: Text(
                        node.title,
                        style: AppTypography.bodySmall.copyWith(
                          color: isCompleted
                              ? Colors.white38
                              : Colors.white70,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // XP pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: node.accentColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '+${node.xpReward}',
                        style: AppTypography.caption.copyWith(
                          color: node.accentColor.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.ctaLime,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Footer
            Text(
              'Complete all for +$totalXp XP bonus',
              style: AppTypography.caption.copyWith(
                color: AppColors.ctaLime.withValues(alpha: 0.60),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
