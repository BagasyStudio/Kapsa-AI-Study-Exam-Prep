import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/journey_node_model.dart';
import '../providers/journey_provider.dart';

/// Compact horizontal journey preview for the home screen.
/// Shows a window of 7 nodes centered on the active node, with a Continue CTA.
class HomeJourneyPreview extends ConsumerStatefulWidget {
  final String courseId;
  const HomeJourneyPreview({super.key, required this.courseId});

  @override
  ConsumerState<HomeJourneyPreview> createState() =>
      _HomeJourneyPreviewState();
}

class _HomeJourneyPreviewState extends ConsumerState<HomeJourneyPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  static const _windowSize = 7;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final nodesAsync = ref.watch(journeyNodesProvider(widget.courseId));
    final progress = ref.watch(journeyProgressProvider(widget.courseId));
    final activeNode =
        ref.watch(activeJourneyNodeProvider(widget.courseId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: nodesAsync.when(
        loading: () => const _JourneyShimmer(),
        error: (_, __) => const SizedBox.shrink(),
        data: (nodes) {
          if (nodes.isEmpty) {
            return _EmptyJourney(
              label: l.homeStartJourney,
              onTap: () => context.push(Routes.journeyPath(widget.courseId)),
            );
          }
          return _buildPreview(context, l, nodes, progress, activeNode);
        },
      ),
    );
  }

  Widget _buildPreview(
    BuildContext context,
    AppLocalizations l,
    List<JourneyNode> nodes,
    double progress,
    JourneyNode? activeNode,
  ) {
    // Window of nodes around the active one
    final activeIdx = activeNode != null
        ? nodes.indexWhere((n) => n.id == activeNode.id)
        : 0;
    final clampedIdx = activeIdx.clamp(0, nodes.length - 1);
    final halfWindow = _windowSize ~/ 2;
    var start = (clampedIdx - halfWindow).clamp(0, nodes.length);
    var end = (start + _windowSize).clamp(0, nodes.length);
    if (end - start < _windowSize && start > 0) {
      start = (end - _windowSize).clamp(0, nodes.length);
    }
    final windowNodes = nodes.sublist(start, end);

    final percent = (progress * 100).round();

    return TapScale(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(Routes.journeyPath(widget.courseId));
      },
      child: GlassPanel(
        tier: GlassTier.subtle,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: "Your Journey" + progress pill
              Row(
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.homeYourJourney,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$percent% ${l.homeComplete}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Horizontal node strip
              SizedBox(
                height: 48,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final nodeCount = windowNodes.length;
                    if (nodeCount == 0) return const SizedBox.shrink();
                    final nodeSize = 36.0;
                    final totalNodesWidth = nodeCount * nodeSize;
                    final totalGaps = nodeCount - 1;
                    final connectorWidth = totalGaps > 0
                        ? ((constraints.maxWidth - totalNodesWidth) /
                                totalGaps)
                            .clamp(8.0, 32.0)
                        : 0.0;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < nodeCount; i++) ...[
                          _NodeCircle(
                            node: windowNodes[i],
                            isActive: windowNodes[i].id == activeNode?.id,
                            pulseAnimation: _pulseAnim,
                          ),
                          if (i < nodeCount - 1)
                            _Connector(
                              width: connectorWidth,
                              isCompleted:
                                  windowNodes[i].state ==
                                      JourneyNodeState.completed &&
                                  windowNodes[i + 1].state !=
                                      JourneyNodeState.locked,
                            ),
                        ],
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Continue CTA
              if (activeNode != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4F53C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        activeNode.icon,
                        color: const Color(0xFF101122),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l.homeContinue}: ${activeNode.title}',
                        style: AppTypography.labelLarge.copyWith(
                          color: const Color(0xFF101122),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF101122),
                        size: 18,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single node circle in the journey strip.
class _NodeCircle extends StatelessWidget {
  final JourneyNode node;
  final bool isActive;
  final Animation<double> pulseAnimation;

  const _NodeCircle({
    required this.node,
    required this.isActive,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final color = node.accentColor;
    final isCompleted = node.state == JourneyNodeState.completed;
    final isLocked = node.state == JourneyNodeState.locked;

    if (isActive) {
      return AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
              border: Border.all(
                color: color.withValues(alpha: pulseAnimation.value),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3 * pulseAnimation.value),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(node.icon, color: color, size: 16),
          );
        },
      );
    }

    if (isCompleted) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Color(0xFF10B981),
          size: 16,
        ),
      );
    }

    // Locked
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: Icon(
        isLocked ? Icons.lock_rounded : node.icon,
        color: Colors.white24,
        size: 14,
      ),
    );
  }
}

/// Connector dash between nodes.
class _Connector extends StatelessWidget {
  final double width;
  final bool isCompleted;

  const _Connector({
    required this.width,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF10B981).withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// Empty journey CTA.
class _EmptyJourney extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EmptyJourney({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: GlassPanel(
        tier: GlassTier.subtle,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white38,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading for the journey preview.
class _JourneyShimmer extends StatelessWidget {
  const _JourneyShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
