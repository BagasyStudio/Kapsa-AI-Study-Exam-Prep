import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/utils/error_handler.dart';
import '../providers/summary_provider.dart';

class SummaryScreen extends ConsumerWidget {
  final String summaryId;

  const SummaryScreen({super.key, required this.summaryId});

  int _estimateReadMinutes(int wordCount) =>
      (wordCount / 200).ceil().clamp(1, 99);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryProvider(summaryId));

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: summaryAsync.when(
        loading: () => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: ShimmerList(count: 5, itemHeight: 60),
          ),
        ),
        error: (e, _) => SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48,
                      color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppErrorHandler.friendlyMessage(e),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (summary) {
          if (summary == null) {
            return SafeArea(
              child: Center(
                child: Text(
                  'Summary not found',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ),
            );
          }

          final readMin = _estimateReadMinutes(summary.wordCount);

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom header with glass back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0,
                  ),
                  child: Row(
                    children: [
                      TapScale(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Reading time pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_stories_rounded, size: 14,
                                color: Colors.white.withValues(alpha: 0.5)),
                            const SizedBox(width: 5),
                            Text(
                              '~$readMin min read',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.lg,
                      AppSpacing.xl, 120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title area
                        Text(
                          summary.title,
                          style: AppTypography.h2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Word count + reading time
                        Text(
                          '${summary.wordCount} words',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),

                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Container(
                            height: 1,
                            color: AppColors.immersiveBorder,
                          ),
                        ),

                        // Key Takeaways
                        if (summary.bulletPoints.isNotEmpty) ...[
                          Text(
                            'Key Takeaways',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.immersiveCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.immersiveBorder,
                              ),
                            ),
                            child: Column(
                              children: summary.bulletPoints.asMap().entries
                                  .map((entry) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: entry.key <
                                            summary.bulletPoints.length - 1
                                        ? AppSpacing.sm
                                        : 0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 7),
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.7),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style:
                                              AppTypography.bodySmall.copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.85),
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],

                        // Full Summary
                        Text(
                          'Full Summary',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.immersiveCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.immersiveBorder,
                            ),
                          ),
                          child: SelectableText(
                            summary.content,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.8,
                            ),
                          ),
                        ),
                      ],
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
