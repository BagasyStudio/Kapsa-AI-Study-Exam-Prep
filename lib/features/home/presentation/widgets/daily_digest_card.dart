import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Daily digest card showing yesterday's activity and today's study plan.
///
/// Appears once per day on the home screen. Can be dismissed (persisted
/// via SharedPreferences with the current date as key).
class DailyDigestCard extends ConsumerStatefulWidget {
  const DailyDigestCard({super.key});

  @override
  ConsumerState<DailyDigestCard> createState() => _DailyDigestCardState();
}

class _DailyDigestCardState extends ConsumerState<DailyDigestCard>
    with SingleTickerProviderStateMixin {
  bool _dismissed = true; // Start hidden until we check
  bool _loaded = false;
  bool _hapticTriggered = false;

  int _yesterdayCards = 0;
  int _yesterdayQuizzes = 0;
  double _yesterdayBestScore = 0;
  int _todayDueCards = 0;
  int _streakDays = 0;

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
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _checkAndLoad();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key =
        'daily_digest_dismissed_${today.year}_${today.month}_${today.day}';

    if (prefs.getBool(key) == true) {
      // Already dismissed today
      return;
    }

    // Load stats
    await _loadStats();

    if (mounted) {
      setState(() {
        _dismissed = false;
        _loaded = true;
      });
      _animController.forward();
    }
  }

  Future<void> _loadStats() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    final client = Supabase.instance.client;
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStart =
        DateTime(yesterday.year, yesterday.month, yesterday.day)
            .toUtc()
            .toIso8601String();
    final yesterdayEnd =
        DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59)
            .toUtc()
            .toIso8601String();
    final nowUtc = now.toUtc().toIso8601String();

    try {
      // Yesterday's card reviews
      final reviews = await client
          .from('card_reviews')
          .select('id')
          .eq('user_id', userId)
          .gte('reviewed_at', yesterdayStart)
          .lte('reviewed_at', yesterdayEnd);
      _yesterdayCards = (reviews as List).length;

      // Yesterday's quizzes
      final quizzes = await client
          .from('tests')
          .select('id, score')
          .eq('user_id', userId)
          .gte('created_at', yesterdayStart)
          .lte('created_at', yesterdayEnd);
      _yesterdayQuizzes = (quizzes as List).length;
      if (_yesterdayQuizzes > 0) {
        final scores = (quizzes)
            .map((q) => ((q['score'] as num?) ?? 0).toDouble())
            .toList();
        _yesterdayBestScore = scores.reduce((a, b) => a > b ? a : b) * 100;
      }

      // Today's due cards
      final decks = await client
          .from('flashcard_decks')
          .select('id')
          .eq('user_id', userId);
      if ((decks as List).isNotEmpty) {
        final deckIds = decks.map((d) => d['id'] as String).toList();
        final dueCards = await client
            .from('flashcards')
            .select('id')
            .inFilter('deck_id', deckIds)
            .lte('due', nowUtc);
        _todayDueCards = (dueCards as List).length;
      }

      // Streak
      final profile = await client
          .from('profiles')
          .select('streak_days')
          .eq('id', userId)
          .maybeSingle();
      _streakDays = (profile?['streak_days'] as int?) ?? 0;
    } catch (e) {
      debugPrint('DailyDigest: load digest data failed: $e');
    }
  }

  Future<void> _dismiss() async {
    await _animController.reverse();
    if (!mounted) return;
    await _persistDismissal();
  }

  Future<void> _persistDismissal() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key =
        'daily_digest_dismissed_${today.year}_${today.month}_${today.day}';
    await prefs.setBool(key, true);

    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !_loaded) return const SizedBox.shrink();

    // Don't show if there's zero activity yesterday and zero due today
    if (_yesterdayCards == 0 && _yesterdayQuizzes == 0 && _todayDueCards == 0) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Dismissible(
          key: const ValueKey('daily_digest'),
          direction: DismissDirection.horizontal,
          onUpdate: (details) {
            // Haptic feedback when crossing the dismiss threshold
            if (details.progress >= 0.4 && !_hapticTriggered) {
              _hapticTriggered = true;
              HapticFeedback.mediumImpact();
            } else if (details.progress < 0.4) {
              _hapticTriggered = false;
            }
          },
          onDismissed: (_) => _persistDismissal(),
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: AppSpacing.xl),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 24),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Dismiss',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dismiss',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 24),
              ],
            ),
          ),
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.immersiveCard,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.immersiveBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title + dismiss
                Row(
                  children: [
                    const Text('\u{1F4CA}', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Daily Digest',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Yesterday stats
                if (_yesterdayCards > 0 || _yesterdayQuizzes > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      _buildYesterdayText(),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ),

                // Today plan
                if (_todayDueCards > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'Today: $_todayDueCards cards due for review',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ),

                // Streak
                if (_streakDays > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        const Text('\u{1F525}',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '$_streakDays day streak',
                          style: AppTypography.caption.copyWith(
                            color: const Color(0xFFF97316),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Start button
                if (_todayDueCards > 0)
                  TapScale(
                    onTap: () {
                      _dismiss();
                      context.push(Routes.quickReview);
                    },
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          'Start Reviewing',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  String _buildYesterdayText() {
    final parts = <String>[];
    if (_yesterdayCards > 0) {
      parts.add('$_yesterdayCards cards reviewed');
    }
    if (_yesterdayQuizzes > 0) {
      final scoreText = _yesterdayBestScore > 0
          ? ' (${_yesterdayBestScore.toStringAsFixed(0)}%)'
          : '';
      parts.add(
          '$_yesterdayQuizzes quiz${_yesterdayQuizzes > 1 ? 'zes' : ''}$scoreText');
    }
    return 'Yesterday: ${parts.join(', ')}';
  }
}
