import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/week_calendar_strip.dart';
import '../widgets/timeline_view.dart';
import '../widgets/exam_event_card.dart';
import '../widgets/task_item.dart';
import '../providers/calendar_provider.dart';
import '../../data/models/calendar_event_model.dart';
import '../../../assistant/presentation/providers/assistant_provider.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/shimmer_loading.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  bool _isGeneratingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _generateAISuggestions() async {
    setState(() => _isGeneratingSuggestions = true);
    try {
      final count = await ref
          .read(assistantRepositoryProvider)
          .generateCalendarSuggestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $count AI study suggestions!'),
            backgroundColor: AppColors.primary,
          ),
        );
        // Refresh events and event dots
        ref.invalidate(calendarEventsProvider(_selectedDate));
        ref.invalidate(calendarEventDatesProvider(_twoWeekRange));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.friendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingSuggestions = false);
    }
  }

  void _onDayTap(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  // ── Date label helpers ──

  static const _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Primary header: "Sunday, March 15"
  String get _fullDateLabel {
    final weekday = _weekdayNames[_selectedDate.weekday - 1];
    final month = _monthNames[_selectedDate.month - 1];
    return '$weekday, $month ${_selectedDate.day}';
  }

  /// Secondary: "March 2026"
  String get _monthYearLabel =>
      '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';

  /// Whether selectedDate is today (date-only comparison).
  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  /// Short reference for empty state: "Sunday, March 15"
  String get _emptyStateDateRef => _fullDateLabel;

  /// Compute the 2-week range for event dot lookup.
  (DateTime, DateTime) get _twoWeekRange {
    final d = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final weekStart = d.subtract(Duration(days: d.weekday - 1));
    final rangeEnd = weekStart.add(const Duration(days: 13)); // 2 weeks
    return (weekStart, rangeEnd);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider(_selectedDate));
    final range = _twoWeekRange;
    final eventDatesAsync = ref.watch(calendarEventDatesProvider(range));

    // Determine if we have events for conditional FAB
    final hasEvents = eventsAsync.whenOrNull(
          data: (events) => events.isNotEmpty,
        ) ??
        false;

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      // FAB only when there ARE events (to add more suggestions to a busy day)
      floatingActionButton: hasEvents
          ? Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: FloatingActionButton.small(
                onPressed:
                    _isGeneratingSuggestions ? null : _generateAISuggestions,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: _isGeneratingSuggestions
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
              ),
            )
          : null,
      body: Stack(
        children: [
          // Ethereal mesh background radial gradients
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.immersiveBg,
                gradient: RadialGradient(
                  center: const Alignment(-1.0, -1.0),
                  radius: 1.2,
                  colors: [
                    const Color(0xFF1A1533).withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -1.0),
                  radius: 1.0,
                  colors: [
                    const Color(0xFF131A2B).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.0, -1.0),
                  radius: 1.0,
                  colors: [
                    const Color(0xFF1A1228).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primary: full date
                      Text(
                        _fullDateLabel,
                        style: AppTypography.h2.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Secondary: month year + "Today" pill
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Month picker coming soon')),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _monthYearLabel,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.white38,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.expand_more,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                          // "Today" pill — only visible when navigated away
                          if (!_isToday) ...[
                            const SizedBox(width: AppSpacing.sm),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = DateTime.now();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  'Today',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Calendar grid
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: WeekCalendarStrip(
                    focusedDate: _selectedDate,
                    selectedDate: _selectedDate,
                    eventDates: eventDatesAsync.valueOrNull ?? {},
                    onDayTap: _onDayTap,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Timeline
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      ref.invalidate(
                          calendarEventsProvider(_selectedDate));
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        0,
                        AppSpacing.xl,
                        120,
                      ),
                      child: eventsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child:
                              ShimmerList(count: 3, itemHeight: 72),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Center(
                            child: Text(
                              AppErrorHandler.friendlyMessage(e),
                              style: AppTypography.bodySmall,
                            ),
                          ),
                        ),
                        data: (events) {
                          if (events.isEmpty) {
                            return _buildEmptyState();
                          }
                          return _buildTimeline(events);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state with contextual copy and inline AI Suggest CTA.
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No sessions for $_emptyStateDateRef',
              style: AppTypography.h3.copyWith(
                color: Colors.white60,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your schedule is clear',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 12),
            // Inline AI Suggest CTA
            GestureDetector(
              onTap:
                  _isGeneratingSuggestions ? null : _generateAISuggestions,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isGeneratingSuggestions
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome,
                            size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _isGeneratingSuggestions
                          ? 'Generating...'
                          : 'AI Suggest',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<CalendarEventModel> events) {
    // Sort events by start time
    final sorted = [...events]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final entries = <Widget>[
      // Schedule label
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
        child: Text(
          'SCHEDULE',
          style: AppTypography.caption.copyWith(
            color: Colors.white38,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ),
      ),
    ];

    final timelineEntries = sorted.map((event) {
      if (event.isExam) {
        return TimelineEntry(
          time: event.timeLabel,
          dotColor: const Color(0xFFF472B6),
          content: ExamEventCard(
            title: event.title,
            time: event.timeRange,
            courseLabel: event.description ?? '',
          ),
        );
      } else if (event.isSuggestion) {
        return TimelineEntry(
          time: event.timeLabel,
          dotColor: AppColors.primary,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        event.aiSuggestion ?? event.title,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        // Task
        return TimelineEntry(
          time: event.timeLabel,
          dotColor: AppColors.primary,
          content: TaskItem(
            title: event.title,
            time: event.description ?? '',
            subtitle: '',
            icon: Icons.assignment,
            iconBgColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
            iconColor: const Color(0xFF6366F1),
            trailingText: event.endTime != null
                ? '${event.endTime!.difference(event.startTime).inMinutes}m'
                : null,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening ${event.title}...')),
              );
            },
          ),
        );
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...entries,
        TimelineView(entries: timelineEntries),
      ],
    );
  }
}
