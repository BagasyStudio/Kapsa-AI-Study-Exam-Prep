import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/heatmap_provider.dart';

/// GitHub-style study activity heatmap showing XP per day for 13 weeks.
/// Forced immersive dark styling.
class StudyHeatmap extends ConsumerWidget {
  const StudyHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(heatmapDataProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.immersiveBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(Icons.local_fire_department,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Study Activity',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Heatmap grid
          dataAsync.when(
            loading: () => SizedBox(
              height: 88,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white38,
                  ),
                ),
              ),
            ),
            error: (_, __) => SizedBox(
              height: 88,
              child: Center(
                child: Text(
                  'Could not load activity',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ),
            ),
            data: (dailyXp) => _HeatmapGrid(
              dailyXp: dailyXp,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: AppTypography.caption.copyWith(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              ..._legendColors().map((c) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
              const SizedBox(width: 4),
              Text(
                'More',
                style: AppTypography.caption.copyWith(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _legendColors() {
    return [
      AppColors.immersiveSurface,
      const Color(0xFF6467F2).withValues(alpha: 0.30),
      const Color(0xFF6467F2).withValues(alpha: 0.50),
      const Color(0xFF6467F2).withValues(alpha: 0.75),
      const Color(0xFF6467F2),
    ];
  }
}

class _HeatmapGrid extends StatefulWidget {
  final Map<String, int> dailyXp;

  const _HeatmapGrid({
    required this.dailyXp,
  });

  @override
  State<_HeatmapGrid> createState() => _HeatmapGridState();
}

class _HeatmapGridState extends State<_HeatmapGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasAnimated = false;

  /// Total number of cells in the grid (13 weeks x 7 days).
  static const _totalCells = 13 * 7;

  /// Stagger delay per cell in milliseconds.
  static const _staggerMs = 15;

  /// Duration for each individual cell's scale animation.
  static const _cellAnimMs = 350;

  /// Total animation duration covers the last cell's stagger + its animation.
  static final _totalDuration = Duration(
    milliseconds: (_totalCells - 1) * _staggerMs + _cellAnimMs,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );
    // Start the entrance animation on first build
    _controller.forward().then((_) {
      _hasAnimated = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build 13 weeks x 7 days grid
    final now = DateTime.now();
    // Start from the beginning of the week 12 weeks ago
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    final startDate = startOfWeek.subtract(const Duration(days: 12 * 7));

    // Find max XP for intensity scaling
    final maxXp =
        widget.dailyXp.values.fold<int>(0, (a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final cellSize = (totalWidth - 12 * 2) / 13; // 13 cols, 2px spacing
        final cellGap = 2.0;

        return SizedBox(
          height: cellSize * 7 + cellGap * 6,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size(totalWidth, cellSize * 7 + cellGap * 6),
                painter: _HeatmapPainter(
                  startDate: startDate,
                  dailyXp: widget.dailyXp,
                  maxXp: maxXp,
                  cellSize: cellSize,
                  cellGap: cellGap,
                  animationProgress: _controller.value,
                  totalDurationMs: _totalDuration.inMilliseconds,
                  staggerMs: _staggerMs,
                  cellAnimMs: _cellAnimMs,
                  hasAnimated: _hasAnimated,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final DateTime startDate;
  final Map<String, int> dailyXp;
  final int maxXp;
  final double cellSize;
  final double cellGap;
  final double animationProgress;
  final int totalDurationMs;
  final int staggerMs;
  final int cellAnimMs;
  final bool hasAnimated;

  _HeatmapPainter({
    required this.startDate,
    required this.dailyXp,
    required this.maxXp,
    required this.cellSize,
    required this.cellGap,
    required this.animationProgress,
    required this.totalDurationMs,
    required this.staggerMs,
    required this.cellAnimMs,
    required this.hasAnimated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final radius = Radius.circular(cellSize * 0.2);

    int cellIndex = 0;

    for (int week = 0; week < 13; week++) {
      for (int day = 0; day < 7; day++) {
        final date = startDate.add(Duration(days: week * 7 + day));
        if (date.isAfter(today)) continue;

        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final xp = dailyXp[key] ?? 0;

        final cx = week * (cellSize + cellGap) + cellSize / 2;
        final cy = day * (cellSize + cellGap) + cellSize / 2;

        // Calculate per-cell scale based on stagger
        final double scale;
        if (hasAnimated) {
          scale = 1.0;
        } else {
          final cellStartMs = cellIndex * staggerMs;
          final cellEndMs = cellStartMs + cellAnimMs;
          final currentMs = animationProgress * totalDurationMs;

          if (currentMs <= cellStartMs) {
            scale = 0.0;
          } else if (currentMs >= cellEndMs) {
            scale = 1.0;
          } else {
            // Normalize to 0..1 for this cell's animation window
            final t = (currentMs - cellStartMs) / cellAnimMs;
            // Apply easeOutBack curve manually for slight bounce
            scale = _easeOutBack(t);
          }
        }

        cellIndex++;

        if (scale <= 0.0) continue;

        canvas.save();
        canvas.translate(cx, cy);
        canvas.scale(scale);
        canvas.translate(-cx, -cy);

        final x = week * (cellSize + cellGap);
        final y = day * (cellSize + cellGap);

        final paint = Paint()..color = _colorForIntensity(xp);

        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          radius,
        );
        canvas.drawRRect(rrect, paint);

        // Subtle border on empty cells for grid visibility
        if (xp == 0) {
          final borderPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          canvas.drawRRect(rrect, borderPaint);
        }

        canvas.restore();
      }
    }
  }

  /// Manual easeOutBack curve: slight overshoot then settle.
  /// Matches Curves.easeOutBack behaviour.
  double _easeOutBack(double t) {
    const s = 1.70158;
    final t1 = t - 1.0;
    return t1 * t1 * ((s + 1) * t1 + s) + 1.0;
  }

  Color _colorForIntensity(int xp) {
    if (xp == 0) {
      return AppColors.immersiveSurface;
    }

    final effective = maxXp > 0 ? xp / maxXp : 0.0;

    if (effective < 0.25) {
      return const Color(0xFF6467F2).withValues(alpha: 0.30);
    }
    if (effective < 0.50) {
      return const Color(0xFF6467F2).withValues(alpha: 0.50);
    }
    if (effective < 0.75) {
      return const Color(0xFF6467F2).withValues(alpha: 0.75);
    }
    return const Color(0xFF6467F2);
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) {
    return old.dailyXp != dailyXp ||
        old.animationProgress != animationProgress;
  }
}
