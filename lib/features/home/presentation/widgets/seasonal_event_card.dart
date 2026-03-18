import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Seasonal Event Card — themed promotional banner based on current month
// ═══════════════════════════════════════════════════════════════════════════════
//
// Displays a seasonally-themed challenge card on the home screen.
// - Themed by month with unique emoji, message, and gradient
// - Dismissible via SharedPreferences with a week-based key
// - "Join" button placeholder for future feature
// - Slide + fade entrance animation
// ═══════════════════════════════════════════════════════════════════════════════

/// Definition of a seasonal theme.
class _SeasonalTheme {
  final String emoji;
  final String title;
  final List<Color> gradientColors;

  const _SeasonalTheme({
    required this.emoji,
    required this.title,
    required this.gradientColors,
  });
}

/// Returns the seasonal theme based on the current month.
_SeasonalTheme _getSeasonalTheme() {
  final month = DateTime.now().month;

  switch (month) {
    case 3: // March
      return const _SeasonalTheme(
        emoji: '\u{1F338}', // cherry blossom
        title: 'Spring Study Sprint \u2014 Complete 5 quizzes this week!',
        gradientColors: [Color(0xFFF472B6), Color(0xFFA78BFA)], // pink to violet
      );
    case 6: // June
    case 7: // July
      return const _SeasonalTheme(
        emoji: '\u2600\uFE0F', // sun
        title: 'Summer Brain Boost \u2014 Review 100 cards!',
        gradientColors: [Color(0xFFFBBF24), Color(0xFFF97316)], // amber to orange
      );
    case 10: // October
      return const _SeasonalTheme(
        emoji: '\u{1F383}', // jack-o-lantern
        title: 'Halloween Challenge \u2014 Master 3 decks!',
        gradientColors: [Color(0xFFF97316), Color(0xFF7C3AED)], // orange to purple
      );
    case 12: // December
      return const _SeasonalTheme(
        emoji: '\u{1F384}', // christmas tree
        title: 'Year-End Review \u2014 Revisit your weakest topics!',
        gradientColors: [Color(0xFF34D399), Color(0xFF059669)], // emerald gradient
      );
    default:
      return const _SeasonalTheme(
        emoji: '\u{1F4DA}', // books
        title: 'Weekly Challenge \u2014 Study every day for 7 days!',
        gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // indigo to violet
      );
  }
}

/// Week-based dismiss key: "seasonal_card_dismissed_2026_W12"
String _weekDismissKey() {
  final now = DateTime.now();
  // ISO week number calculation
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
  final weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
  return 'seasonal_card_dismissed_${now.year}_W$weekNumber';
}

/// Week-based "joined" key
String _weekJoinedKey() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
  final weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
  return 'seasonal_card_joined_${now.year}_W$weekNumber';
}

/// Seasonal event card with themed banner and gradient background.
///
/// Features:
/// - Month-based themed content (Spring, Summer, Halloween, Year-End, default)
/// - Gradient background matching the season
/// - Dismissible via X button (week-based SharedPreferences key)
/// - "Join" button that marks the challenge as joined
/// - SlideTransition + FadeTransition entrance animation
class SeasonalEventCard extends ConsumerStatefulWidget {
  const SeasonalEventCard({super.key});

  @override
  ConsumerState<SeasonalEventCard> createState() => _SeasonalEventCardState();
}

class _SeasonalEventCardState extends ConsumerState<SeasonalEventCard>
    with SingleTickerProviderStateMixin {
  bool _loaded = false;
  bool _dismissed = false;
  bool _joined = false;

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
    final prefs = await SharedPreferences.getInstance();
    final dismissKey = _weekDismissKey();
    final joinKey = _weekJoinedKey();

    final dismissed = prefs.getBool(dismissKey) ?? false;
    final joined = prefs.getBool(joinKey) ?? false;

    if (mounted) {
      setState(() {
        _dismissed = dismissed;
        _joined = joined;
        _loaded = true;
      });
      if (!dismissed) {
        _animController.forward();
      }
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weekDismissKey(), true);

    await _animController.reverse();
    if (mounted) {
      setState(() => _dismissed = true);
    }
  }

  Future<void> _join() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weekJoinedKey(), true);

    if (mounted) {
      setState(() => _joined = true);
    }

    // Auto-dismiss after a short delay to acknowledge join
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted && !_dismissed) {
      _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed) return const SizedBox.shrink();

    final theme = _getSeasonalTheme();

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: theme.gradientColors.first.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: emoji + title + dismiss button ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji
                    Text(
                      theme.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Title
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          theme.title,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
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

                // ── Join button ──
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _joined ? null : _join,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _joined
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _joined ? 'Joined!' : 'Join',
                        style: AppTypography.labelSmall.copyWith(
                          color: _joined
                              ? Colors.white
                              : theme.gradientColors.first,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
