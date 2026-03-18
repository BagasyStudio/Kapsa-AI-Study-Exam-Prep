import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../gamification/presentation/widgets/xp_popup.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../data/models/journey_node_model.dart';
import '../providers/journey_provider.dart';
import '../providers/exercise_provider.dart';
import '../widgets/journey_path.dart';

/// Full-screen gamified learning journey for a specific course.
///
/// Displays a vertical zigzag path of connected nodes representing
/// study activities (flashcards, quizzes, materials, exercises, checkpoints)
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

  /// Whether a node type is an exercise that navigates to the exercise screen.
  bool _isExerciseType(JourneyNodeType type) => const {
        JourneyNodeType.fillGaps,
        JourneyNodeType.speedRound,
        JourneyNodeType.mistakeSpotter,
        JourneyNodeType.teachBot,
        JourneyNodeType.compareContrast,
        JourneyNodeType.timelineBuilder,
        JourneyNodeType.caseStudy,
        JourneyNodeType.matchBlitz,
        JourneyNodeType.conceptMapper,
        JourneyNodeType.dailyChallenge,
      }.contains(type);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final nodesAsync = ref.watch(journeyNodesProvider(courseId));
    final streakMultiplier =
        ref.watch(streakMultiplierProvider.notifier).multiplier;

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      floatingActionButton: nodesAsync.whenOrNull(
        data: (nodes) => nodes.isNotEmpty ? _buildFab(nodes, l) : null,
      ),
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
              loading: () => _buildLoadingState(l),
              error: (e, _) => _buildErrorState(l),
              data: (nodes) {
                if (nodes.isEmpty) return _buildEmptyState(l);
                return _buildJourney(nodes, streakMultiplier, l);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────────────

  Widget? _buildFab(List<JourneyNode> nodes, AppLocalizations l) {
    final activeNode = nodes.cast<JourneyNode?>().firstWhere(
          (n) => n!.state == JourneyNodeState.active,
          orElse: () => null,
        );
    if (activeNode == null) return null;

    return TapScale(
      onTap: () => _handleNodeTap(activeNode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.ctaLime,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: AppColors.ctaLime.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activeNode.icon,
              size: 18,
              color: AppColors.ctaLimeText,
            ),
            const SizedBox(width: 8),
            Text(
              l.journeyFabContinue,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.ctaLimeText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Journey Body ───────────────────────────────────────────────────────

  Widget _buildJourney(
      List<JourneyNode> nodes, int streakMultiplier, AppLocalizations l) {
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
            onCompletedNodeTap: (node) => _showMicroReview(node, l),
            isPro: ref.watch(isProProvider).whenOrNull(data: (v) => v) ?? false,
            gateIndex: ref.watch(firstCheckpointIndexProvider(courseId)),
            streakMultiplier: streakMultiplier,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ── Node Tap Handling ────────────────────────────────────────────────────

  void _handleNodeTap(JourneyNode node) {
    final l = AppLocalizations.of(context)!;

    // Locked nodes → gated logic
    if (node.state == JourneyNodeState.locked) {
      final isPro =
          ref.read(isProProvider).whenOrNull(data: (v) => v) ?? false;
      if (!isPro) {
        final gateIndex =
            ref.read(firstCheckpointIndexProvider(courseId)) ?? 3;
        if (node.position > gateIndex) {
          context.push(Routes.paywall);
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.journeyCompletePrevious),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Already completed → revisit (micro-review for exercises)
    if (node.state == JourneyNodeState.completed) {
      if (_isExerciseType(node.type)) {
        _showMicroReview(node, l);
      } else if (node.route != null) {
        context.push(node.route!);
      }
      return;
    }

    // ── Active node ──

    // Reward: celebration + immediate completion
    if (node.type == JourneyNodeType.reward) {
      CelebrationOverlay.show(
        context,
        title: l.journeyRewardChest,
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

    // Exercise types → navigate and wait for score result
    if (_isExerciseType(node.type)) {
      context.push<JourneyResult>(node.route!).then((result) {
        if (!mounted) return;
        if (result == JourneyResult.completed) {
          _completeNode(node);
        }
      });
      return;
    }

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
    final multiplier =
        ref.read(streakMultiplierProvider.notifier).multiplier;
    final effectiveXp = node.xpReward * multiplier;
    XpPopup.show(context, xp: effectiveXp, label: node.title);
    ref
        .read(journeyCompletionProvider(courseId).notifier)
        .markCompleted(node.id, node.xpReward);
  }

  // ── Micro-Review ──────────────────────────────────────────────────────

  void _showMicroReview(JourneyNode node, AppLocalizations l) {
    final dateStr = node.completedAt != null
        ? DateFormat.yMMMd().format(node.completedAt!)
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.immersiveCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 20),
            // Icon + Title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: node.accentColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(node.icon, color: node.accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.title,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (dateStr != null)
                        Text(
                          l.journeyMicroReviewCompleted(dateStr),
                          style: AppTypography.caption.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Score
            if (node.bestScore != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (node.bestScore! >= 70
                                ? AppColors.success
                                : AppColors.warning)
                            .withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          '${node.bestScore}%',
                          style: AppTypography.labelLarge.copyWith(
                            color: node.bestScore! >= 70
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.journeyMicroReviewScore(node.bestScore!),
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                l.journeyMicroReviewNoScore,
                style: AppTypography.bodySmall.copyWith(color: Colors.white38),
              ),
            const SizedBox(height: 20),
            // Redo button
            if (node.route != null)
              TapScale(
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push(node.route!);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: node.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: node.accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    l.journeyMicroReviewRedo,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge.copyWith(
                      color: node.accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Loading State ──────────────────────────────────────────────────────

  Widget _buildLoadingState(AppLocalizations l) {
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _shimmerBar(200, 28),
                const SizedBox(height: 8),
                _shimmerBar(140, 14),
                const SizedBox(height: AppSpacing.lg),
                _shimmerBar(double.infinity, 6),
                const SizedBox(height: AppSpacing.xxl),
                _shimmerBar(double.infinity, 140, radius: 20),
                const SizedBox(height: AppSpacing.xxl),
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
                Center(
                  child: FadeTransition(
                    opacity: _pulseAnimation,
                    child: Text(
                      l.journeyGenerating,
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

  // ── Empty State ──────────────────────────────────────────────────────

  Widget _buildEmptyState(AppLocalizations l) {
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
                    l.journeyNoContent,
                    style: AppTypography.h3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l.journeyUploadMaterials,
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
                        l.journeyUploadMaterial,
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

  // ── Error State ──────────────────────────────────────────────────────

  Widget _buildErrorState(AppLocalizations l) {
    return Center(
      child: Text(
        l.journeyCouldNotLoad,
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
    final l = AppLocalizations.of(context)!;
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
                      const Text('\u{1F525}', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
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
                  l.journeyLevel(level),
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            course?.displayTitle ?? 'Course',
            style: AppTypography.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            l.journeyLearningJourney,
            style: AppTypography.caption.copyWith(
              color: Colors.white60,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

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
                      l.journeyProgress(progressPercent),
                      style: AppTypography.sectionHeader.copyWith(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      l.journeyLevel(level),
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
    final l = AppLocalizations.of(context)!;
    final daysLeft = examDate.difference(DateTime.now()).inDays;
    final text = daysLeft <= 0
        ? l.journeyExamToday
        : l.journeyDaysToExam(daysLeft, daysLeft > 1 ? 's' : '');

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
    final l = AppLocalizations.of(context)!;

    // Pick 3 nodes: active + next upcoming
    final challengeNodes = <JourneyNode>[];
    final active = nodes.where((n) => n.state == JourneyNodeState.active);
    final locked = nodes.where((n) => n.state == JourneyNodeState.locked);
    challengeNodes.addAll(active.take(1));
    challengeNodes.addAll(locked.take(3 - challengeNodes.length));

    if (challengeNodes.isEmpty) return const SizedBox.shrink();

    final completedCount = 0;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.journeyTodaysChallenge,
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
            ...challengeNodes.map((node) {
              final isCompleted = node.state == JourneyNodeState.completed;
              final isActive = node.state == JourneyNodeState.active;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
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
                    // Use icon instead of asset to avoid missing images
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: node.accentColor.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        node.icon,
                        size: 16,
                        color: isCompleted
                            ? node.accentColor.withValues(alpha: 0.5)
                            : node.accentColor,
                      ),
                    ),
                    const SizedBox(width: 10),
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
            Text(
              l.journeyCompleteAll(totalXp),
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
