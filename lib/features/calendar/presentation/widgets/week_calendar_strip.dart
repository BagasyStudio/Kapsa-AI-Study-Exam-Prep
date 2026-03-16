import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A two-week calendar strip with dynamic dates.
///
/// Shows the week of [focusedDate] plus the following week.
/// Days from a different month appear muted. Event dots are driven
/// by [eventDates]. The selected day is highlighted with a primary circle.
class WeekCalendarStrip extends StatelessWidget {
  /// The date whose week defines row 1. Row 2 is the next week.
  final DateTime focusedDate;

  /// The currently selected date (highlighted).
  final DateTime selectedDate;

  /// Dates that have at least one event (local date-only, no time).
  final Set<DateTime> eventDates;

  /// Called with the tapped date (local date-only).
  final ValueChanged<DateTime>? onDayTap;

  const WeekCalendarStrip({
    super.key,
    required this.focusedDate,
    required this.selectedDate,
    this.eventDates = const {},
    this.onDayTap,
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// Monday of the week that contains [focusedDate].
  DateTime get _weekStart {
    final d = DateTime(focusedDate.year, focusedDate.month, focusedDate.day);
    return d.subtract(Duration(days: d.weekday - 1)); // weekday 1=Mon
  }

  /// Normalize a DateTime to local date-only for comparison.
  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Whether two DateTimes represent the same calendar day.
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    // Row 1 = Mon..Sun of focusedDate's week
    // Row 2 = Mon..Sun of the following week
    final week1Start = _weekStart;
    final week2Start = week1Start.add(const Duration(days: 7));
    final focusedMonth = focusedDate.month;
    final today = _dateOnly(DateTime.now());
    final sel = _dateOnly(selectedDate);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.immersiveBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Day-of-week headers
          _buildDayHeaders(sel, week1Start, week2Start),

          const SizedBox(height: AppSpacing.md),

          // Row 1
          _buildDateRow(
            week1Start,
            focusedMonth,
            today,
            sel,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Row 2
          _buildDateRow(
            week2Start,
            focusedMonth,
            today,
            sel,
          ),

          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }

  /// Header row — M T W T F S S. The column of the selected day is primary.
  Widget _buildDayHeaders(
    DateTime sel,
    DateTime week1Start,
    DateTime week2Start,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final d1 = week1Start.add(Duration(days: i));
        final d2 = week2Start.add(Duration(days: i));
        final isSelectedColumn = _sameDay(d1, sel) || _sameDay(d2, sel);

        return SizedBox(
          width: 32,
          child: Center(
            child: Text(
              _dayLabels[i],
              style: AppTypography.caption.copyWith(
                color: isSelectedColumn
                    ? AppColors.primary
                    : Colors.white38,
                fontWeight: isSelectedColumn ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// A single row of 7 dates starting at [rowStart].
  Widget _buildDateRow(
    DateTime rowStart,
    int focusedMonth,
    DateTime today,
    DateTime sel,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final date = rowStart.add(Duration(days: i));
        final dateOnly = _dateOnly(date);
        final isOtherMonth = date.month != focusedMonth;
        final isSelected = _sameDay(dateOnly, sel);
        final isToday = _sameDay(dateOnly, today);
        final hasEvent = eventDates.contains(dateOnly);

        return GestureDetector(
          onTap: () => onDayTap?.call(dateOnly),
          child: SizedBox(
            width: 32,
            height: 36,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Date circle / number
                Container(
                  width: 28,
                  height: 28,
                  decoration: isSelected
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                      : isToday
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            )
                          : null,
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : isOtherMonth
                                ? Colors.white.withValues(alpha: 0.2)
                                : isToday
                                    ? AppColors.primary
                                    : Colors.white60,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                // Event dot
                if (hasEvent && !isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _dot(const Color(0xFFFDA4AF)), // pink-300
                  )
                else if (isSelected && hasEvent)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _dot(Colors.white.withValues(alpha: 0.8)),
                  )
                else
                  const SizedBox(height: 6),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
