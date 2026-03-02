import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/course_stats_provider.dart';

/// Dynamic course stats banner replacing the static AiInsightBanner.
///
/// Shows material count, flashcard count, quiz count, and a CTA.
class CourseStatsBanner extends ConsumerWidget {
  final String courseId;
  final VoidCallback? onGenerateTap;

  const CourseStatsBanner({
    super.key,
    required this.courseId,
    this.onGenerateTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(courseStatsProvider(courseId));
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: AppRadius.borderRadiusLg,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.82),
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative glow
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: isDark ? 0.06 : 0.1),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'COURSE OVERVIEW',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Stats row
                  statsAsync.when(
                    loading: () => SizedBox(
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textMutedFor(brightness),
                          ),
                        ),
                      ),
                    ),
                    error: (_, __) => Text(
                      'Upload materials to see course stats',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMutedFor(brightness),
                      ),
                    ),
                    data: (stats) => Row(
                      children: [
                        _StatChip(
                          icon: Icons.description_outlined,
                          value: '${stats.materialCount}',
                          label: 'Materials',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _StatChip(
                          icon: Icons.style_outlined,
                          value: '${stats.deckCount}',
                          label: 'Decks',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _StatChip(
                          icon: Icons.layers_outlined,
                          value: '${stats.totalCards}',
                          label: 'Cards',
                          isDark: isDark,
                        ),
                        if (stats.dueCards > 0) ...[
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.schedule,
                            value: '${stats.dueCards}',
                            label: 'Due',
                            isDark: isDark,
                            isHighlighted: true,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // CTA
                  GestureDetector(
                    onTap: onGenerateTap,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.white.withValues(alpha: 0.82),
                        borderRadius: AppRadius.borderRadiusMd,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Generate Flashcards',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;
  final bool isHighlighted;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHighlighted
        ? const Color(0xFFF59E0B)
        : AppColors.textSecondaryFor(Theme.of(context).brightness);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.labelLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
