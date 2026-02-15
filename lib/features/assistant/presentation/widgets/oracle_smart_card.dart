import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../providers/assistant_provider.dart';

/// AI insight card shown on the home screen.
///
/// Displays a personalized study tip from The Oracle,
/// with a gradient border and tap to open the global chat.
class OracleSmartCard extends ConsumerWidget {
  const OracleSmartCard({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'exam_prep':
        return Icons.school;
      case 'weak_area':
        return Icons.trending_up;
      case 'streak':
        return Icons.local_fire_department;
      case 'review':
        return Icons.refresh;
      case 'progress':
      default:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightAsync = ref.watch(assistantInsightProvider);

    return insightAsync.when(
      loading: () => _buildShimmer(),
      error: (_, __) => const SizedBox.shrink(), // Hide on error
      data: (insight) {
        if (insight == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: TapScale(
            onTap: () => context.push(Routes.oracle),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6467F2),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(1.5), // gradient border thickness
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.5),
                  color: const Color(0xFF1A1B3A),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.3),
                            const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                      child: Icon(
                        _iconForType(insight.type),
                        color: const Color(0xFFA5A7FA),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: Color(0xFFA5A7FA),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'THE ORACLE',
                                style: AppTypography.caption.copyWith(
                                  color: const Color(0xFFA5A7FA),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            insight.title,
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            insight.body,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Arrow
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1A1B3A).withValues(alpha: 0.5),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'The Oracle is thinking...',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
