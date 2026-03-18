import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A single daily quest definition.
class _DailyQuest {
  final String id;
  final String title;
  final int xpReward;
  final IconData icon;

  const _DailyQuest({
    required this.id,
    required this.title,
    required this.xpReward,
    required this.icon,
  });
}

const _kQuests = [
  _DailyQuest(
    id: 'review_flashcards',
    title: 'Review 10 flashcards',
    xpReward: 50,
    icon: Icons.style,
  ),
  _DailyQuest(
    id: 'complete_quiz',
    title: 'Complete 1 quiz',
    xpReward: 75,
    icon: Icons.quiz_rounded,
  ),
  _DailyQuest(
    id: 'study_15min',
    title: 'Study for 15 minutes',
    xpReward: 100,
    icon: Icons.timer_rounded,
  ),
];

const int _kBonusXp = 50;

/// Daily quests card showing 3 daily missions that refresh each day.
///
/// Tracks completion via SharedPreferences with a date-based key.
/// Forced immersive dark styling to match the home screen.
class DailyQuestCard extends ConsumerStatefulWidget {
  const DailyQuestCard({super.key});

  @override
  ConsumerState<DailyQuestCard> createState() => _DailyQuestCardState();
}

class _DailyQuestCardState extends ConsumerState<DailyQuestCard>
    with SingleTickerProviderStateMixin {
  final Map<String, bool> _completions = {};
  bool _loaded = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String get _todayKey {
    final now = DateTime.now();
    return 'daily_quests_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

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

    _loadCompletions();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadCompletions() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey;

    for (final quest in _kQuests) {
      _completions[quest.id] = prefs.getBool('${key}_${quest.id}') ?? false;
    }

    if (mounted) {
      setState(() => _loaded = true);
      _animController.forward();
    }
  }

  Future<void> _toggleQuest(String questId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey;
    final current = _completions[questId] ?? false;
    final newValue = !current;

    await prefs.setBool('${key}_$questId', newValue);

    if (mounted) {
      setState(() => _completions[questId] = newValue);
    }
  }

  int get _completedCount =>
      _completions.values.where((v) => v).length;

  bool get _allComplete => _completedCount == _kQuests.length;

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

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
              border: Border.all(color: AppColors.immersiveBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.3),
                            AppColors.primary.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Daily Quests',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Completed count pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _allComplete
                            ? AppColors.success.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$_completedCount/${_kQuests.length}',
                        style: AppTypography.caption.copyWith(
                          color: _allComplete
                              ? AppColors.success
                              : Colors.white38,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _kQuests.isEmpty
                        ? 0
                        : _completedCount / _kQuests.length,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _allComplete ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Quest list
                ...List.generate(_kQuests.length, (index) {
                  final quest = _kQuests[index];
                  final isCompleted = _completions[quest.id] ?? false;
                  return _QuestRow(
                    quest: quest,
                    isCompleted: isCompleted,
                    onToggle: () => _toggleQuest(quest.id),
                  );
                }),

                // All complete bonus
                if (_allComplete) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success.withValues(alpha: 0.12),
                          AppColors.primary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '\u{1F389}',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'All quests done! +$_kBonusXp bonus XP',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single quest row with checkbox, icon, title, and XP reward.
class _QuestRow extends StatelessWidget {
  final _DailyQuest quest;
  final bool isCompleted;
  final VoidCallback onToggle;

  const _QuestRow({
    required this.quest,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success
                    : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),

            // Quest icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.06),
              ),
              child: Icon(
                quest.icon,
                size: 16,
                color: isCompleted
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Title
            Expanded(
              child: Text(
                quest.title,
                style: AppTypography.bodySmall.copyWith(
                  color: isCompleted
                      ? Colors.white.withValues(alpha: 0.35)
                      : AppColors.textPrimaryDark,
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: Colors.white.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // XP reward
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.xpGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '+${quest.xpReward} XP',
                style: AppTypography.caption.copyWith(
                  color: isCompleted
                      ? AppColors.success.withValues(alpha: 0.6)
                      : AppColors.xpGold,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
