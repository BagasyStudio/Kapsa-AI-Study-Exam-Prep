import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/xp_config.dart';
import '../../../../core/widgets/floating_orbs.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../data/models/knowledge_score_model.dart';
import '../providers/knowledge_score_provider.dart';
import '../widgets/knowledge_score_share_card.dart';
import '../widgets/share_preview_sheet.dart';

class KnowledgeScoreScreen extends ConsumerStatefulWidget {
  const KnowledgeScoreScreen({super.key});

  @override
  ConsumerState<KnowledgeScoreScreen> createState() =>
      _KnowledgeScoreScreenState();
}

class _KnowledgeScoreScreenState extends ConsumerState<KnowledgeScoreScreen> {
  String? _aiAnalysis;
  bool _aiAnalysisRequested = false;

  /// Fetches AI analysis from the edge function in the background.
  /// On success, updates [_aiAnalysis] so the Oracle section re-renders.
  Future<void> _fetchAiAnalysis(KnowledgeScoreModel score) async {
    if (_aiAnalysisRequested) return;
    _aiAnalysisRequested = true;

    try {
      final functions = ref.read(supabaseFunctionsProvider);
      final response = await functions.invoke(
        'ai-assistant',
        body: {
          'mode': 'knowledge_analysis',
          'metrics': {
            'overall': score.overallScore.round(),
            'retention': score.retention.round(),
            'accuracy': score.accuracy.round(),
            'consistency': score.consistency.round(),
            'speed': score.speed.round(),
            'depth': score.depth.round(),
            'mastery': score.mastery.round(),
            'examReadiness': score.examReadiness.round(),
            'dedication': score.dedication.round(),
            'rank': score.rank,
          },
        },
      );

      final data = response.data as Map<String, dynamic>?;
      final analysis = data?['analysis'] as String?;
      if (analysis != null && analysis.isNotEmpty && mounted) {
        setState(() {
          _aiAnalysis = analysis;
        });
      }
    } catch (_) {
      // Edge function failed — keep showing local analysis.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreAsync = ref.watch(knowledgeScoreProvider);

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingOrbs()),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GlassBackButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'KNOWLEDGE SCORE',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          fontSize: 13,
                        ),
                      ),
                      scoreAsync.whenOrNull(
                            data: (score) => _GlassShareButton(
                              onTap: () => _showShare(context, ref, score),
                            ),
                          ) ??
                          const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: scoreAsync.when(
                    loading: () => _buildLoading(),
                    error: (e, _) => Center(
                      child: Text('Error calculating score',
                          style: AppTypography.bodyMedium),
                    ),
                    data: (score) {
                      // Kick off AI analysis fetch in the background
                      _fetchAiAnalysis(score);
                      return _buildContent(context, score);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const ShimmerCard(width: 200, height: 200, borderRadius: null),
          const SizedBox(height: 30),
          const ShimmerCard(width: 150, height: 24),
          const SizedBox(height: 40),
          Row(
            children: const [
              Expanded(child: ShimmerCard(height: 80)),
              SizedBox(width: 12),
              Expanded(child: ShimmerCard(height: 80)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, KnowledgeScoreModel score) {
    final rankColor = Color(KnowledgeScoreModel.rankColorValue(score.rank));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        MediaQuery.of(context).padding.bottom + 100,
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Main score ring
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _ScoreRingPainter(
                score: score.overallScore,
                metrics: score.metricsMap,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${score.overallScore.round()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Knowledge Score',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Rank badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: rankColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.military_tech, color: rankColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  score.rank,
                  style: TextStyle(
                    color: rankColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Metrics grid 2x4
          _buildMetricsGrid(context, score),

          const SizedBox(height: 28),

          // Oracle analysis placeholder
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'THE ORACLE',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _aiAnalysis ??
                      score.oracleAnalysis ??
                      _generateLocalAnalysis(score),
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white60,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, KnowledgeScoreModel score) {
    final metrics = score.metricsMap.entries.toList();
    final infoMap = KnowledgeScoreModel.metricInfoMap;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final entry = metrics[index];
        final info = infoMap[entry.key];
        final color = Color(info?.colorValue ?? 0xFF6467F2);
        final value = entry.value;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    info?.label ?? entry.key,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${value.round()}',
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: value / 100,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _generateLocalAnalysis(KnowledgeScoreModel score) {
    final strongest = score.metricsMap.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    final weakest = score.metricsMap.entries
        .reduce((a, b) => a.value < b.value ? a : b);
    final strongInfo = KnowledgeScoreModel.metricInfoMap[strongest.key];
    final weakInfo = KnowledgeScoreModel.metricInfoMap[weakest.key];

    return 'Your strongest area is ${strongInfo?.label ?? strongest.key} '
        '(${strongest.value.round()}). '
        'Focus on improving ${weakInfo?.label ?? weakest.key} '
        '(${weakest.value.round()}) to boost your overall score.';
  }

  void _showShare(
      BuildContext context, WidgetRef ref, KnowledgeScoreModel score) {
    final profile = ref.read(profileProvider).valueOrNull;
    final xpTotal = ref.read(xpTotalProvider).valueOrNull ?? 0;

    SharePreviewSheet.show(
      context,
      shareCard: KnowledgeScoreShareCard(
        score: score,
        userName: profile?.fullName ?? 'Student',
        xpLevel: XpConfig.levelFromXp(xpTotal),
      ),
      shareType: 'knowledge_score',
    );
  }
}

// Score ring with multi-color segments for each metric
class _ScoreRingPainter extends CustomPainter {
  final double score;
  final Map<String, double> metrics;

  _ScoreRingPainter({required this.score, required this.metrics});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Colored segments
    final colors = [
      const Color(0xFF10B981), // retention
      const Color(0xFFF59E0B), // accuracy
      const Color(0xFF10B981), // consistency
      const Color(0xFFF97316), // speed
      const Color(0xFF3B82F6), // depth
      const Color(0xFFF59E0B), // mastery
      const Color(0xFF10B981), // exam readiness
      const Color(0xFF3B82F6), // dedication
    ];

    final total = score / 100;
    final sweepAngle = total * 2 * math.pi;
    final segmentAngle = sweepAngle / colors.length;

    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.butt;

      final startAngle = -math.pi / 2 + (i * segmentAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle * 0.9, // Small gap between segments
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      score != oldDelegate.score;
}

class _GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      scaleDown: 0.90,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(Icons.chevron_left,
            color: Colors.white60, size: 22),
      ),
    );
  }
}

class _GlassShareButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      scaleDown: 0.90,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(Icons.ios_share,
            color: Colors.white60, size: 18),
      ),
    );
  }
}
