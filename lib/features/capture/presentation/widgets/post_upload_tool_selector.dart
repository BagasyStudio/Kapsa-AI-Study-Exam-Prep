import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/generation_provider.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../data/models/capture_result.dart';

/// Shows tool options after a successful material upload.
Future<void> showPostUploadToolSelector(
  BuildContext context,
  WidgetRef ref,
  CaptureResult result,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _PostUploadToolSelector(result: result, parentRef: ref),
  );
}

class _PostUploadToolSelector extends ConsumerStatefulWidget {
  final CaptureResult result;
  final WidgetRef parentRef;

  const _PostUploadToolSelector({
    required this.result,
    required this.parentRef,
  });

  @override
  ConsumerState<_PostUploadToolSelector> createState() =>
      _PostUploadToolSelectorState();
}

class _PostUploadToolSelectorState
    extends ConsumerState<_PostUploadToolSelector> {

  Future<void> _onGenerateTool(String tool) async {
    final result = widget.result;
    final courseAsync = ref.read(courseProvider(result.courseId));
    final courseName = courseAsync.whenOrNull(data: (c) => c?.title) ?? '';

    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: tool,
      context: context,
    );
    if (!canUse) return;

    if (tool == 'flashcards') {
      if (!mounted) return;
      final isPro = await ref.read(isProProvider.future).catchError((_) => false);
      if (!mounted) return;
      final count = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _FlashcardCountSelector(isPro: isPro),
      );
      if (count == null || !mounted) return;

      ref.read(generationProvider.notifier).generateFlashcards(
        result.courseId,
        courseName,
        materialId: result.materialId,
        count: count,
      );
    } else if (tool == 'quiz') {
      ref.read(generationProvider.notifier).generateQuiz(
        result.courseId,
        courseName,
        materialId: result.materialId,
      );
    } else if (tool == 'summary') {
      ref.read(generationProvider.notifier).generateSummary(
        result.courseId,
        courseName,
        materialId: result.materialId,
      );
    } else if (tool == 'glossary') {
      ref.read(generationProvider.notifier).generateGlossary(
        result.courseId,
        courseName,
        materialId: result.materialId,
      );
    }

    if (mounted) {
      final l = AppLocalizations.of(context)!;
      SoundService.playProcessingComplete();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.postUploadGeneratingInBackground(tool)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onNavigationTool(String route) {
    Navigator.of(context).pop();
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Success header
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.postUploadMaterialUploaded,
            style: AppTypography.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.displayTitle,
            style: AppTypography.caption.copyWith(
              color: Colors.white38,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Section: Generate
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l.postUploadWhatToCreate,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2x2 grid of generation tools
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              _GenerateCard(
                icon: Icons.style,
                label: l.postUploadFlashcards,
                subtitle: l.postUploadCreateCards,
                color: const Color(0xFF3B82F6),
                onTap: () => _onGenerateTool('flashcards'),
              ),
              _GenerateCard(
                icon: Icons.quiz,
                label: l.postUploadQuiz,
                subtitle: l.postUploadTestKnowledge,
                color: const Color(0xFF10B981),
                onTap: () => _onGenerateTool('quiz'),
              ),
              _GenerateCard(
                icon: Icons.auto_stories,
                label: l.postUploadSummary,
                subtitle: l.postUploadKeyPoints,
                color: const Color(0xFF06B6D4),
                onTap: () => _onGenerateTool('summary'),
              ),
              _GenerateCard(
                icon: Icons.menu_book,
                label: l.postUploadGlossary,
                subtitle: l.postUploadKeyTerms,
                color: const Color(0xFF8B5CF6),
                onTap: () => _onGenerateTool('glossary'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Section: More tools
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l.postUploadMoreTools,
              style: AppTypography.caption.copyWith(
                color: Colors.white24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Compact horizontal row of secondary tools
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CompactToolChip(
                  icon: Icons.replay_rounded,
                  label: l.postUploadSrsReview,
                  onTap: () => _onNavigationTool(
                    Routes.srsReviewPath(result.courseId),
                  ),
                ),
                _CompactToolChip(
                  icon: Icons.timer,
                  label: l.postUploadPracticeExam,
                  onTap: () => _onNavigationTool(Routes.practiceExam),
                ),
                _CompactToolChip(
                  icon: Icons.headphones,
                  label: l.postUploadAudioSummary,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(Routes.audioPlayerPath(
                      result.materialId,
                      result.courseId,
                      result.displayTitle,
                    ));
                  },
                ),
                _CompactToolChip(
                  icon: Icons.camera_alt_rounded,
                  label: l.postUploadSnapSolve,
                  onTap: () => _onNavigationTool(Routes.snapSolve),
                ),
                _CompactToolChip(
                  icon: Icons.chat_rounded,
                  label: l.postUploadChat,
                  onTap: () => _onNavigationTool(
                    Routes.chatPath(result.courseId),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Skip button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l.postUploadSkip,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Generate Card (primary 2x2 grid item) ─────────────────────────────────

class _GenerateCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GenerateCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact Tool Chip (secondary horizontal scroll) ────────────────────────

class _CompactToolChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CompactToolChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: TapScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white54, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Flashcard Count Selector ───────────────────────────────────────────────

class _FlashcardCountSelector extends StatefulWidget {
  final bool isPro;
  const _FlashcardCountSelector({required this.isPro});

  @override
  State<_FlashcardCountSelector> createState() =>
      _FlashcardCountSelectorState();
}

class _FlashcardCountSelectorState extends State<_FlashcardCountSelector> {
  int _selected = 30;
  static const _options = [20, 30, 50, 80];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.immersiveCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l.postUploadHowManyFlashcards,
            style: AppTypography.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.postUploadChooseCount,
            style: AppTypography.caption.copyWith(color: Colors.white38),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: _options.map((count) {
              final isSelected = _selected == count;
              final isLocked = !widget.isPro && count > 30;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: isLocked
                        ? null
                        : () => setState(() => _selected = count),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.ctaLime.withValues(alpha: 0.12)
                            : isLocked
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.ctaLime.withValues(alpha: 0.50)
                              : isLocked
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white.withValues(alpha: 0.10),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$count',
                            style: AppTypography.h4.copyWith(
                              color: isSelected
                                  ? AppColors.ctaLime
                                  : isLocked
                                      ? Colors.white24
                                      : Colors.white70,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (isLocked) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFF97316),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                l.postUploadPro,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(_selected),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.ctaLime,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ctaLime.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  l.postUploadGenerateFlashcards(_selected),
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.ctaLimeText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
