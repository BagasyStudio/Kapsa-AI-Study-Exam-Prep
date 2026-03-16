import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pulse_glow.dart';
import '../../../../core/widgets/shimmer_button.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/widgets/tap_scale.dart';
// CreateCourseSheet is defined in courses_list_screen.dart (made public)
import '../../../courses/presentation/screens/courses_list_screen.dart';

/// Beautiful empty state shown when the user has zero courses/decks.
///
/// Communicates the app's value proposition and drives users toward
/// creating their first deck through the wizard flow.
class HomeEmptyState extends ConsumerWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: StaggeredColumn(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.huge),

            // ── Glowing icon ──
            PulseGlow(
              glowColor: AppColors.primary,
              maxBlurRadius: 32,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 48,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Title ──
            Text(
              'Your library is empty',
              textAlign: TextAlign.center,
              style: AppTypography.h2.copyWith(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Subtitle ──
            Text(
              'Upload a document and we\'ll create\nflashcards for you automatically',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white60,
                height: 1.5,
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // ── Primary CTA ──
            SizedBox(
              width: double.infinity,
              child: ShimmerButton(
                label: '+ Create your first deck',
                icon: Icons.add_rounded,
                onPressed: () => context.push(Routes.firstDeckWizard),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Secondary link ──
            TapScale(
              onTap: () => _showManualCreation(context),
              child: Text(
                'or create an empty deck',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white38,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }

  void _showManualCreation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => const CreateCourseSheet(),
    );
  }
}
