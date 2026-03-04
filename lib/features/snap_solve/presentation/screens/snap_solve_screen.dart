import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_limits.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../data/models/snap_solution_model.dart';
import '../providers/snap_solve_provider.dart';
import '../widgets/solution_view.dart';

/// Full-screen Snap & Solve experience.
///
/// Camera -> Upload -> AI Solve -> Step-by-step solution.
/// The actual solve runs in a global [SnapSolveJobNotifier] so it
/// survives navigation. This screen just reflects that state reactively.
class SnapSolveScreen extends ConsumerStatefulWidget {
  /// Optional: pre-load an existing solution from history.
  final String? solutionId;

  const SnapSolveScreen({super.key, this.solutionId});

  @override
  ConsumerState<SnapSolveScreen> createState() => _SnapSolveScreenState();
}

class _SnapSolveScreenState extends ConsumerState<SnapSolveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  /// When non-null, the user is viewing an existing solution from history
  /// (independent of the global background job).
  SnapSolutionModel? _historySolution;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // If we have a solutionId, load it from history
    if (widget.solutionId != null) {
      _loadExistingSolution();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSolution() async {
    try {
      final solution = await ref
          .read(snapSolveRepositoryProvider)
          .getSolution(widget.solutionId!);
      if (solution != null && mounted) {
        setState(() {
          _historySolution = solution;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorHandler.friendlyMessage(e))),
        );
      }
    }
  }

  Future<void> _captureAndSolve(ImageSource source) async {
    // Check feature access (needs BuildContext — stays in the screen)
    final canUse = await checkFeatureAccess(
      ref: ref,
      feature: 'snap_solve',
      context: context,
    );
    if (!canUse) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 75,
    );
    if (image == null) return;

    // Check file size
    final fileLength = await image.length();
    if (fileLength > AppLimits.maxFileSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File too large. Maximum size is ${AppLimits.maxFileSizeMB} MB.',
            ),
          ),
        );
      }
      return;
    }

    final imageBytes = await image.readAsBytes();
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Fire-and-forget: start the solve in the global notifier
    ref.read(snapSolveJobProvider.notifier).startSolve(imageBytes, user.id);

    // Go back to home immediately — the SnapSolveBanner will show progress
    if (mounted) context.pop();
  }

  void _resetToInitial() {
    setState(() => _historySolution = null);
    ref.read(snapSolveJobProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(brightness, isDark),

              // Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _buildContent(brightness, isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Brightness brightness, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
      ),
      child: Row(
        children: [
          // Close button — pops without stopping the background job
          GestureDetector(
            onTap: () => context.pop(),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.45),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Title
          Text(
            'Snap & Solve',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimaryFor(brightness),
              fontWeight: FontWeight.w700,
            ),
          ),

          const Spacer(),

          // History button
          GestureDetector(
            onTap: _showHistory,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.45),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Icon(
                    Icons.history,
                    size: 20,
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Brightness brightness, bool isDark) {
    // If viewing a history solution, show it directly
    // (independent of the global background job).
    if (_historySolution != null) {
      return SolutionView(
        key: const ValueKey('history-result'),
        solution: _historySolution!,
        onSolveAnother: _resetToInitial,
      );
    }

    // Otherwise, derive the view from the global job state.
    final jobState = ref.watch(snapSolveJobProvider);

    switch (jobState.status) {
      case SnapSolveJobStatus.idle:
        return _InitialView(
          key: const ValueKey('initial'),
          onCamera: () => _captureAndSolve(ImageSource.camera),
          onGallery: () => _captureAndSolve(ImageSource.gallery),
        );
      case SnapSolveJobStatus.uploading:
        return _ProcessingView(
          key: const ValueKey('processing'),
          status: 'Uploading image...',
          step: 0,
          pulseAnimation: _pulseController,
        );
      case SnapSolveJobStatus.solving:
        return _ProcessingView(
          key: const ValueKey('processing'),
          status: 'AI is solving...',
          step: 1,
          pulseAnimation: _pulseController,
        );
      case SnapSolveJobStatus.completed:
        return SolutionView(
          key: const ValueKey('result'),
          solution: jobState.solution!,
          onSolveAnother: _resetToInitial,
        );
      case SnapSolveJobStatus.error:
        return _ErrorView(
          key: const ValueKey('error'),
          message: jobState.errorMessage ?? 'Something went wrong',
          rawError: jobState.rawError,
          onRetry: _resetToInitial,
        );
    }
  }

  void _showHistory() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      'Solution History',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (_, ref, __) {
                        final historyAsync =
                            ref.watch(snapSolveHistoryProvider);
                        return historyAsync.when(
                          loading: () => const Center(
                              child: CircularProgressIndicator()),
                          error: (e, _) => Center(
                            child: Text(AppErrorHandler.friendlyMessage(e)),
                          ),
                          data: (solutions) {
                            if (solutions.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 48,
                                      color: AppColors.textMutedFor(brightness)
                                          .withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'No solutions yet',
                                      style:
                                          AppTypography.bodyMedium.copyWith(
                                        color:
                                            AppColors.textMutedFor(brightness),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                              ),
                              itemCount: solutions.length,
                              itemBuilder: (_, i) {
                                final sol = solutions[i];
                                return EntranceAnimation(
                                  index: i,
                                  child: _HistoryItem(
                                    solution: sol,
                                    onTap: () {
                                      Navigator.of(ctx).pop();
                                      setState(() {
                                        _historySolution = sol;
                                      });
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Initial View — Camera & Gallery buttons
// ═══════════════════════════════════════════

class _InitialView extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _InitialView({
    super.key,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primaryLight.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Take a photo of any problem',
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimaryFor(brightness),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Math, physics, chemistry — our AI will solve it step by step',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMutedFor(brightness),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // Camera button (primary)
          TapScale(
            onTap: onCamera,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Take Photo',
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

          const SizedBox(height: AppSpacing.md),

          // Gallery button (secondary)
          TapScale(
            onTap: onGallery,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_rounded,
                      color: AppColors.textSecondaryFor(brightness), size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Choose from Gallery',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimaryFor(brightness),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Processing View
// ═══════════════════════════════════════════

class _ProcessingView extends StatelessWidget {
  final String status;
  final int step;
  final AnimationController pulseAnimation;

  const _ProcessingView({
    super.key,
    required this.status,
    required this.step,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated orb
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, __) {
                final scale = 1.0 + (pulseAnimation.value * 0.12);
                final glowOpacity = 0.2 + (pulseAnimation.value * 0.15);
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.primary.withValues(alpha: glowOpacity),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight,
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        ),
                      ),
                      child: Icon(
                        step == 0
                            ? Icons.cloud_upload_rounded
                            : Icons.psychology_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xxl),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                status,
                key: ValueKey(status),
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(brightness),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                step == 0
                    ? 'Sending your photo to the cloud...'
                    : 'Our AI is working through the problem...',
                key: ValueKey(step),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedFor(brightness),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Hint: user can go back
            Text(
              'You can go back — we\'ll notify you when it\'s ready',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMutedFor(brightness).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Step indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepDot(
                  label: 'Upload',
                  icon: Icons.cloud_upload_outlined,
                  isActive: step == 0,
                  isComplete: step > 0,
                ),
                _StepConnector(isComplete: step > 0),
                _StepDot(
                  label: 'Solve',
                  icon: Icons.psychology_outlined,
                  isActive: step == 1,
                  isComplete: step > 1,
                ),
                _StepConnector(isComplete: step > 1),
                _StepDot(
                  label: 'Done',
                  icon: Icons.check_circle_outline,
                  isActive: false,
                  isComplete: step > 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isComplete;

  const _StepDot({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = isComplete
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : AppColors.textMutedFor(brightness).withValues(alpha: 0.4);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          width: isActive ? 44 : 36,
          height: isActive ? 44 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isActive ? 0.15 : 0.08),
            border: Border.all(
              color: color.withValues(alpha: isActive ? 0.5 : 0.2),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Icon(
            isComplete ? Icons.check_rounded : icon,
            size: isActive ? 22 : 18,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isActive
                ? AppColors.primary
                : AppColors.textMutedFor(brightness),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool isComplete;

  const _StepConnector({required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 40,
        height: 2,
        decoration: BoxDecoration(
          color: isComplete
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.textMutedFor(Theme.of(context).brightness)
                  .withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Error View
// ═══════════════════════════════════════════

class _ErrorView extends StatefulWidget {
  final String message;
  final String? rawError;
  final VoidCallback onRetry;

  const _ErrorView({
    super.key,
    required this.message,
    this.rawError,
    required this.onRetry,
  });

  @override
  State<_ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<_ErrorView> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Oops!',
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimaryFor(brightness),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMutedFor(brightness),
            ),
            textAlign: TextAlign.center,
          ),
          // Technical details — tap to expand
          if (widget.rawError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => setState(() => _showDetails = !_showDetails),
              child: Text(
                _showDetails ? 'Hide details \u25B2' : 'Show details \u25BC',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMutedFor(brightness).withValues(alpha: 0.5),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            if (_showDetails) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.15),
                  ),
                ),
                child: SelectableText(
                  widget.rawError!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedFor(brightness),
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.xxl),
          TapScale(
            onTap: widget.onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Try Again',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// History Item
// ═══════════════════════════════════════════

class _HistoryItem extends StatelessWidget {
  final SnapSolutionModel solution;
  final VoidCallback onTap;

  const _HistoryItem({required this.solution, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TapScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              // Subject icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      solution.solution.problem.isNotEmpty
                          ? solution.solution.problem
                          : 'Problem',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${solution.subject ?? 'Other'} \u2022 ${_formatDate(solution.createdAt)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedFor(brightness),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMutedFor(brightness),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }
}
