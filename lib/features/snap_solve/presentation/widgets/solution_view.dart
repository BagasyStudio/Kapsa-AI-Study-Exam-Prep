import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/math_text.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/snap_solution_model.dart';

/// Displays a step-by-step AI solution with expandable steps.
class SolutionView extends StatelessWidget {
  final SnapSolutionModel solution;
  final VoidCallback? onSolveAnother;

  const SolutionView({
    super.key,
    required this.solution,
    this.onSolveAnother,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final data = solution.solution;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),

          // Subject tag
          _SubjectTag(subject: data.subject),

          const SizedBox(height: AppSpacing.lg),

          // Problem text
          if (data.problem.isNotEmpty) ...[
            Text(
              'Problem',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMutedFor(brightness),
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: MathText(
                text: data.problem,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimaryFor(brightness),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Steps header
          Text(
            'SOLUTION',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMutedFor(brightness),
              letterSpacing: 1.5,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Steps
          ...data.steps.map((step) => _StepCard(step: step)),

          const SizedBox(height: AppSpacing.xl),

          // Final answer
          _FinalAnswerCard(answer: data.finalAnswer),

          // Explanation
          if (data.explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: const Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: MathText(
                      text: data.explanation,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),

          // Solve another button
          if (onSolveAnother != null)
            TapScale(
              onTap: onSolveAnother,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Solve Another',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Subject Tag
// ═══════════════════════════════════════════

class _SubjectTag extends StatelessWidget {
  final String subject;

  const _SubjectTag({required this.subject});

  Color get _color {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return const Color(0xFF3B82F6);
      case 'physics':
        return const Color(0xFF8B5CF6);
      case 'chemistry':
        return const Color(0xFF22C55E);
      case 'biology':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFF97316);
    }
  }

  IconData get _icon {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Icons.functions;
      case 'physics':
        return Icons.science;
      case 'chemistry':
        return Icons.biotech;
      case 'biology':
        return Icons.eco;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 6),
          Text(
            subject,
            style: AppTypography.labelMedium.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Step Card
// ═══════════════════════════════════════════

class _StepCard extends StatelessWidget {
  final SolutionStep step;

  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                '${step.step}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Step content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                MathText(
                  text: step.content,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                    height: 1.6,
                  ),
                ),

                // Formula (if present)
                if (step.formula != null && step.formula!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: MathText(
                      text: step.formula!.contains('\$')
                          ? step.formula!
                          : '\$${step.formula!}\$',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Final Answer Card
// ═══════════════════════════════════════════

class _FinalAnswerCard extends StatelessWidget {
  final String answer;

  const _FinalAnswerCard({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primaryLight.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Final Answer',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          MathText(
            text: answer,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimaryFor(Theme.of(context).brightness),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
