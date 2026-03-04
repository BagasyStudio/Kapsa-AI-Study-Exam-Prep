import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/utils/error_handler.dart';
import '../providers/summary_provider.dart';

class SummaryScreen extends ConsumerWidget {
  final String summaryId;

  const SummaryScreen({super.key, required this.summaryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final summaryAsync = ref.watch(summaryProvider(summaryId));

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      appBar: AppBar(
        title: const Text('Summary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: summaryAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: ShimmerList(count: 5, itemHeight: 60),
        ),
        error: (e, _) => Center(
          child: Text(
            AppErrorHandler.friendlyMessage(e),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryFor(brightness),
            ),
          ),
        ),
        data: (summary) {
          if (summary == null) {
            return const Center(child: Text('Summary not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.huge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  summary.title,
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${summary.wordCount} words',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedFor(brightness),
                  ),
                ),

                // Bullet Points
                if (summary.bulletPoints.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Key Takeaways',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassPanel(
                    tier: GlassTier.medium,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: summary.bulletPoints.map((point) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xxs,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  point,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textPrimaryFor(brightness),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Full Summary
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Full Summary',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                GlassPanel(
                  tier: GlassTier.subtle,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SelectableText(
                    summary.content,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimaryFor(brightness),
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
