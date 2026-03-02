import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_counter.dart';
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

class _StatChip extends StatefulWidget {
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
  State<_StatChip> createState() => _StatChipState();
}

class _StatChipState extends State<_StatChip>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.isHighlighted) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
        CurvedAnimation(
          parent: _pulseController!,
          curve: Curves.easeInOut,
        ),
      );
      _pulseController!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isHighlighted
        ? const Color(0xFFF59E0B)
        : AppColors.textSecondaryFor(Theme.of(context).brightness);

    final parsedValue = int.tryParse(widget.value) ?? 0;

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(widget.icon, size: 16, color: color),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: parsedValue,
            style: AppTypography.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          Text(
            widget.label,
            style: AppTypography.caption.copyWith(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    if (widget.isHighlighted && _pulseAnimation != null) {
      chip = ScaleTransition(
        scale: _pulseAnimation!,
        child: chip,
      );
    }

    return Expanded(child: chip);
  }
}
