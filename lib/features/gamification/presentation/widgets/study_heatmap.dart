import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/heatmap_provider.dart';

/// GitHub-style study activity heatmap showing XP per day for 13 weeks.
class StudyHeatmap extends ConsumerWidget {
  const StudyHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(heatmapDataProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.6),
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
                  color: AppColors.textPrimaryFor(brightness),
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
                    color: AppColors.textMutedFor(brightness),
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
                    color: AppColors.textMutedFor(brightness),
                  ),
                ),
              ),
            ),
            data: (dailyXp) => _HeatmapGrid(
              dailyXp: dailyXp,
              isDark: isDark,
              brightness: brightness,
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
                  color: AppColors.textMutedFor(brightness),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              ..._legendColors(isDark).map((c) => Container(
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
                  color: AppColors.textMutedFor(brightness),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _legendColors(bool isDark) {
    if (isDark) {
      return [
        Colors.white.withValues(alpha: 0.12),
        const Color(0xFF6467F2).withValues(alpha: 0.30),
        const Color(0xFF6467F2).withValues(alpha: 0.50),
        const Color(0xFF6467F2).withValues(alpha: 0.75),
        const Color(0xFF6467F2),
      ];
    }
    return [
      Colors.black.withValues(alpha: 0.05),
      const Color(0xFF6467F2).withValues(alpha: 0.25),
      const Color(0xFF6467F2).withValues(alpha: 0.40),
      const Color(0xFF6467F2).withValues(alpha: 0.65),
      const Color(0xFF6467F2),
    ];
  }
}

class _HeatmapGrid extends StatelessWidget {
  final Map<String, int> dailyXp;
  final bool isDark;
  final Brightness brightness;

  const _HeatmapGrid({
    required this.dailyXp,
    required this.isDark,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    // Build 13 weeks × 7 days grid
    final now = DateTime.now();
    // Start from the beginning of the week 12 weeks ago
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    final startDate = startOfWeek.subtract(const Duration(days: 12 * 7));

    // Find max XP for intensity scaling
    final maxXp = dailyXp.values.fold<int>(0, (a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final cellSize = (totalWidth - 12 * 2) / 13; // 13 cols, 2px spacing
        final cellGap = 2.0;

        return SizedBox(
          height: cellSize * 7 + cellGap * 6,
          child: CustomPaint(
            size: Size(totalWidth, cellSize * 7 + cellGap * 6),
            painter: _HeatmapPainter(
              startDate: startDate,
              dailyXp: dailyXp,
              maxXp: maxXp,
              cellSize: cellSize,
              cellGap: cellGap,
              isDark: isDark,
            ),
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
  final bool isDark;

  _HeatmapPainter({
    required this.startDate,
    required this.dailyXp,
    required this.maxXp,
    required this.cellSize,
    required this.cellGap,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final radius = Radius.circular(cellSize * 0.2);

    for (int week = 0; week < 13; week++) {
      for (int day = 0; day < 7; day++) {
        final date = startDate.add(Duration(days: week * 7 + day));
        if (date.isAfter(today)) continue;

        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final xp = dailyXp[key] ?? 0;

        final x = week * (cellSize + cellGap);
        final y = day * (cellSize + cellGap);

        final paint = Paint()..color = _colorForIntensity(xp);

        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          radius,
        );
        canvas.drawRRect(rrect, paint);

        // Subtle border on empty cells in dark mode for grid visibility
        if (xp == 0 && isDark) {
          final borderPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          canvas.drawRRect(rrect, borderPaint);
        }
      }
    }
  }

  Color _colorForIntensity(int xp) {
    if (xp == 0) {
      return isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.05);
    }

    final effective = maxXp > 0 ? xp / maxXp : 0.0;

    if (effective < 0.25) {
      return isDark
          ? const Color(0xFF6467F2).withValues(alpha: 0.30)
          : const Color(0xFF6467F2).withValues(alpha: 0.25);
    }
    if (effective < 0.50) {
      return isDark
          ? const Color(0xFF6467F2).withValues(alpha: 0.50)
          : const Color(0xFF6467F2).withValues(alpha: 0.40);
    }
    if (effective < 0.75) {
      return isDark
          ? const Color(0xFF6467F2).withValues(alpha: 0.75)
          : const Color(0xFF6467F2).withValues(alpha: 0.65);
    }
    return const Color(0xFF6467F2);
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) {
    return old.dailyXp != dailyXp || old.isDark != isDark;
  }
}
