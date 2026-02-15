import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A calendar grid panel matching the mockup.
///
/// Displays M/T/W/T/F/S/S headers with 2 rows of dates in a glass panel.
/// Selected day is highlighted with primary circle. Event dots shown below dates.
class WeekCalendarStrip extends StatelessWidget {
  final int selectedDayIndex; // index in _dates array
  final ValueChanged<int>? onDayTap;

  const WeekCalendarStrip({
    super.key,
    this.selectedDayIndex = 3, // Default Thursday (day 4)
    this.onDayTap,
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  // Row 1: previous month tail + current month start
  static const _row1Dates = [28, 29, 30, 1, 2, 3, 4];
  static const _row1IsPrevMonth = [true, true, true, false, false, false, false];

  // Row 2: current month continues
  static const _row2Dates = [5, 6, 7, 0, 0, 0, 0]; // 0 = empty

  // Event dots: which dates have events (by date number)
  static const _eventDates = {2, 4, 5};
  // Multi-event dates get multiple dots
  static const _multiEventDates = {5};

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Day headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (i) {
                  final isSelectedColumn = _isSelectedColumn(i);
                  return SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        _dayLabels[i],
                        style: AppTypography.caption.copyWith(
                          color: isSelectedColumn
                              ? AppColors.primary
                              : const Color(0xFF94A3B8), // slate-400
                          fontWeight: isSelectedColumn
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSpacing.md),

              // Row 1 of dates
              _buildDateRow(_row1Dates, _row1IsPrevMonth, 0),

              const SizedBox(height: AppSpacing.sm),

              // Row 2 of dates
              _buildDateRow(_row2Dates, List.filled(7, false), 7),

              const SizedBox(height: AppSpacing.sm),

              // Collapse handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0), // slate-200
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSelectedColumn(int colIndex) {
    // Selected day 4 is at index 6 in row 1 (date 4 is at col 6)
    // The selectedDayIndex maps to a date. Day 4 = index 3 (0-based from 1)
    // In our grid, day 4 is at column 6 of row 1
    final selectedDate = selectedDayIndex + 1; // convert to 1-based date
    final colDate = _row1Dates[colIndex];
    if (!_row1IsPrevMonth[colIndex] && colDate == selectedDate) return true;
    if (colIndex < _row2Dates.length && _row2Dates[colIndex] == selectedDate) {
      return true;
    }
    return false;
  }

  Widget _buildDateRow(
    List<int> dates,
    List<bool> isPrevMonth,
    int baseIndex,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final date = dates[i];
        if (date == 0) {
          return const SizedBox(width: 32, height: 32);
        }

        final isPrev = isPrevMonth[i];
        // Map selectedDayIndex to actual date: selectedDayIndex 3 = day 4
        final selectedDate = selectedDayIndex + 1;
        final isSelected = !isPrev && date == selectedDate;
        final hasEvent = !isPrev && _eventDates.contains(date);
        final hasMultiEvent = !isPrev && _multiEventDates.contains(date);

        return GestureDetector(
          onTap: isPrev ? null : () => onDayTap?.call(date - 1),
          child: SizedBox(
            width: 32,
            height: 36,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Date number
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
                      : null,
                  child: Center(
                    child: Text(
                      '$date',
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : isPrev
                                ? const Color(0xFFCBD5E1) // slate-300
                                : const Color(0xFF475569), // slate-600
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                // Event dots
                if (hasEvent && !isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: hasMultiEvent
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dot(const Color(0xFF7DD3FC)), // sky-300
                              const SizedBox(width: 2),
                              _dot(const Color(0xFFA5B4FC)), // indigo-300
                            ],
                          )
                        : _dot(const Color(0xFFFDA4AF)), // pink-300
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
