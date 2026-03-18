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
///
/// Features:
/// - Pulsing scale + opacity on the hero icon
/// - Gentle bounce loop on the CTA button
/// - Staggered entrance for all elements
class HomeEmptyState extends ConsumerStatefulWidget {
  const HomeEmptyState({super.key});

  @override
  ConsumerState<HomeEmptyState> createState() => _HomeEmptyStateState();
}

class _HomeEmptyStateState extends ConsumerState<HomeEmptyState>
    with TickerProviderStateMixin {
  // ── Icon pulse animation (scale 1.0 → 1.05, opacity 0.6 → 1.0) ──
  late final AnimationController _iconPulseController;
  late final Animation<double> _iconScaleAnim;
  late final Animation<double> _iconOpacityAnim;

  // ── CTA bounce animation (translateY 0 → -4 → 0) ──
  late final AnimationController _ctaBounceController;
  late final Animation<double> _ctaBounceAnim;

  @override
  void initState() {
    super.initState();

    // Icon pulse: scale 1.0 → 1.05, opacity 0.6 → 1.0, looping
    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _iconScaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _iconPulseController, curve: Curves.easeInOut),
    );
    _iconOpacityAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _iconPulseController, curve: Curves.easeInOut),
    );

    // CTA bounce: translateY 0 → -4 → 0, 2s loop
    _ctaBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _ctaBounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -4.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -4.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 50,
      ),
    ]).animate(_ctaBounceController);
  }

  @override
  void dispose() {
    _iconPulseController.dispose();
    _ctaBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: StaggeredColumn(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.huge),

            // ── Glowing + pulsing icon ──
            AnimatedBuilder(
              animation: _iconPulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: _iconOpacityAnim.value,
                  child: Transform.scale(
                    scale: _iconScaleAnim.value,
                    child: child,
                  ),
                );
              },
              child: PulseGlow(
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

            // ── Primary CTA with bounce ──
            AnimatedBuilder(
              animation: _ctaBounceAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _ctaBounceAnim.value),
                  child: child,
                );
              },
              child: SizedBox(
                width: double.infinity,
                child: ShimmerButton(
                  label: '+ Create your first deck',
                  icon: Icons.add_rounded,
                  onPressed: () => context.push(Routes.firstDeckWizard),
                ),
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
