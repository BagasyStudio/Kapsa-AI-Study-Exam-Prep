import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/utils/error_handler.dart';
import '../providers/test_provider.dart';

/// Bottom sheet that shows a consolidated AI explanation of all mistakes.
class ExplainMistakesSheet extends ConsumerStatefulWidget {
  final String testId;

  const ExplainMistakesSheet({super.key, required this.testId});

  @override
  ConsumerState<ExplainMistakesSheet> createState() =>
      _ExplainMistakesSheetState();
}

class _ExplainMistakesSheetState extends ConsumerState<ExplainMistakesSheet> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(testRepositoryProvider)
        .explainMistakes(testId: widget.testId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: AppRadius.borderRadiusSheet,
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildLoading(brightness);
          }

          if (snapshot.hasError) {
            return _buildError(
              AppErrorHandler.friendlyMessage(snapshot.error!),
              brightness,
            );
          }

          final data = snapshot.data!;
          return _buildContent(
            explanation: data['explanation'] as String? ?? '',
            weakTopics: (data['weakTopics'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            studyTips: (data['studyTips'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            brightness: brightness,
          );
        },
      ),
    );
  }

  Widget _buildLoading(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          const SizedBox(height: AppSpacing.xl),
          Icon(
            Icons.auto_awesome,
            size: 40,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Analizando tus errores...',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'La IA esta revisando tus respuestas',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const ShimmerCard(height: 80),
          const SizedBox(height: AppSpacing.md),
          const ShimmerCard(height: 120),
          const SizedBox(height: AppSpacing.md),
          const ShimmerCard(height: 80),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildError(String message, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          const SizedBox(height: AppSpacing.xxl),
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No se pudo analizar',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(brightness),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildContent({
    required String explanation,
    required List<String> weakTopics,
    required List<String> studyTips,
    required Brightness brightness,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          const SizedBox(height: AppSpacing.lg),

          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primaryLight.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: const Icon(
                  Icons.psychology,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Entendiendo tus errores',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                  ),
                ),
              ),
            ],
          ),

          // ── Weak Topics Chips ──
          if (weakTopics.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Temas a reforzar',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondaryFor(brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: weakTopics.map((topic) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: AppRadius.borderRadiusSm,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    topic,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // ── AI Explanation ──
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            GlassPanel(
              tier: GlassTier.subtle,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SelectableText(
                explanation,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimaryFor(brightness),
                  height: 1.6,
                ),
              ),
            ),
          ],

          // ── Study Tips ──
          if (studyTips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Tips de estudio',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondaryFor(brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...studyTips.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: GlassPanel(
                  tier: GlassTier.medium,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${entry.key + 1}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimaryFor(brightness),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Close button ──
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'Entendido',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}
