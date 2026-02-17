import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_gradients.dart';
import '../widgets/week_calendar_strip.dart';
import '../widgets/timeline_view.dart';
import '../widgets/exam_event_card.dart';
import '../widgets/task_item.dart';
import '../providers/calendar_provider.dart';
import '../../data/models/calendar_event_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../assistant/presentation/providers/assistant_provider.dart';
import '../../../../core/utils/error_handler.dart';

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
        // Refresh events
        ref.invalidate(calendarEventsProvider(_selectedDate));
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

  int get _selectedDayIndex {
    // Get the weekday (1=Mon, 7=Sun) and convert to 0-based index for the strip
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    return _selectedDate.difference(startOfWeek).inDays.clamp(0, 6);
  }

  void _onDayTap(int index) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    setState(() {
      _selectedDate = startOfWeek.add(Duration(days: index));
    });
  }

  String get _dayLabel {
    const weekdays = [
      'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY',
      'FRIDAY', 'SATURDAY', 'SUNDAY'
    ];
    return weekdays[_selectedDate.weekday - 1];
  }

  String get _monthYearLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider(_selectedDate));
    final user = ref.watch(currentUserProvider);
    final fullName = user?.userMetadata?['full_name'];
    final userInitial = (fullName is String && fullName.isNotEmpty)
        ? fullName.substring(0, 1).toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton.extended(
          onPressed: _isGeneratingSuggestions ? null : _generateAISuggestions,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: _isGeneratingSuggestions
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(
            _isGeneratingSuggestions ? 'Generating...' : 'AI Suggest',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Ethereal mesh background radial gradients
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                gradient: RadialGradient(
                  center: const Alignment(-1.0, -1.0),
                  radius: 1.2,
                  colors: [
                    const Color(0xFFE4E0ED).withValues(alpha: 0.8),
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
                    const Color(0xFFCED6EA).withValues(alpha: 0.6),
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
                    const Color(0xFFEDD6DD).withValues(alpha: 0.5),
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
                // Header: day label + month/year + profile avatar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dayLabel,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Month picker coming soon')),
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  _monthYearLabel,
                                  style: AppTypography.h2.copyWith(
                                    color: const Color(0xFF0F172A),
                                    fontSize: 24,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.expand_more,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Profile avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          gradient: AppGradients.primaryToIndigo,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            userInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
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
                    selectedDayIndex: _selectedDayIndex,
                    onDayTap: _onDayTap,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Timeline
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      ref.invalidate(calendarEventsProvider(_selectedDate));
                    },
                    child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      120,
                    ),
                    child: eventsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: CircularProgressIndicator()),
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
                          return Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    size: 48,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'No events for this day',
                                    style: AppTypography.h3.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Your schedule is clear!',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
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

  Widget _buildTimeline(List<CalendarEventModel> events) {
    // Sort events by start time
    final sorted = [...events]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final entries = sorted.map((event) {
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
            iconBgColor: const Color(0xFFE0E7FF),
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

    return TimelineView(entries: entries);
  }
}
