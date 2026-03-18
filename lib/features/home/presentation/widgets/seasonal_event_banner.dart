import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Seasonal Event Banner — time-limited challenge/event for the home screen
// ═══════════════════════════════════════════════════════════════════════════════
//
// Shows a promotional banner for seasonal events with:
// - Event name, description, and time remaining
// - Progress bar toward a goal
// - Dismissible via X button (persisted with SharedPreferences)
// - Only visible during configured date ranges
//
// Current event: "Exam Season Sprint" (March 1-31, 2026)
// ═══════════════════════════════════════════════════════════════════════════════

/// Configuration for a seasonal event.
class _SeasonalEvent {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final String reward;
  final int goal;
  final DateTime startDate;
  final DateTime endDate;

  const _SeasonalEvent({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.reward,
    required this.goal,
    required this.startDate,
    required this.endDate,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }

  String get timeRemainingLabel {
    final remaining = timeRemaining;
    if (remaining == Duration.zero) return 'Ended';
    final days = remaining.inDays;
    if (days > 1) return '$days days left';
    if (days == 1) return '1 day left';
    final hours = remaining.inHours;
    if (hours > 1) return '$hours hours left';
    if (hours == 1) return '1 hour left';
    return 'Ending soon';
  }
}

// Hardcoded events — add more here for future seasons
final _events = [
  _SeasonalEvent(
    id: 'exam_sprint_mar_2026',
    emoji: '\u{1F393}',
    name: 'Exam Season Sprint',
    description: 'Complete 50 flashcards this week',
    reward: 'Exclusive badge',
    goal: 50,
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 4, 1), // end of March
  ),
];

/// SharedPreferences key prefix for dismissed banners.
const _kDismissPrefix = 'seasonal_event_dismissed_';

/// SharedPreferences key prefix for event progress.
const _kProgressPrefix = 'seasonal_event_progress_';

/// Seasonal event banner that shows time-limited challenges on the home screen.
///
/// Features:
/// - Purple-to-blue gradient background matching app theme
/// - Progress bar showing completion toward goal
/// - Dismiss button persisted via SharedPreferences
/// - Only renders during the event's configured date range
class SeasonalEventBanner extends ConsumerStatefulWidget {
  const SeasonalEventBanner({super.key});

  @override
  ConsumerState<SeasonalEventBanner> createState() =>
      _SeasonalEventBannerState();
}

class _SeasonalEventBannerState extends ConsumerState<SeasonalEventBanner>
    with SingleTickerProviderStateMixin {
  bool _loaded = false;
  bool _dismissed = false;
  int _progress = 0;
  _SeasonalEvent? _activeEvent;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _loadState();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    // Find the first active event
    final event = _events.where((e) => e.isActive).firstOrNull;
    if (event == null) {
      if (mounted) setState(() => _loaded = true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('$_kDismissPrefix${event.id}') ?? false;
    final progress = prefs.getInt('$_kProgressPrefix${event.id}') ?? 32;

    if (mounted) {
      setState(() {
        _activeEvent = event;
        _dismissed = dismissed;
        _progress = progress;
        _loaded = true;
      });
      if (!dismissed) {
        _animController.forward();
      }
    }
  }

  Future<void> _dismiss() async {
    if (_activeEvent == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kDismissPrefix${_activeEvent!.id}', true);

    await _animController.reverse();
    if (mounted) {
      setState(() => _dismissed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render if not loaded, no active event, or dismissed
    if (!_loaded || _activeEvent == null || _dismissed) {
      return const SizedBox.shrink();
    }

    final event = _activeEvent!;
    final progressFraction =
        (_progress / event.goal).clamp(0.0, 1.0);

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.immersiveCard,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: event name + dismiss button ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji
                    Text(
                      event.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Title + time remaining
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.textPrimaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.timeRemainingLabel,
                                style: AppTypography.caption.copyWith(
                                  color:
                                      Colors.white.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Dismiss button
                    GestureDetector(
                      onTap: _dismiss,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Description + reward ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${event.description} \u2192 ${event.reward}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Progress bar ──
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 4,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '$_progress/${event.goal}',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
