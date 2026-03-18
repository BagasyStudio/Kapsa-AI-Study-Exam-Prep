import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/shimmer_button.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/models/audio_summary_model.dart';
import '../providers/audio_summary_provider.dart';

/// Full-screen audio player for audio summaries.
///
/// Displays summary text with a generate button if no summary exists yet.
/// When audio is available, shows playback controls.
class AudioPlayerScreen extends ConsumerStatefulWidget {
  final String materialId;
  final String courseId;
  final String materialTitle;

  const AudioPlayerScreen({
    super.key,
    required this.materialId,
    required this.courseId,
    required this.materialTitle,
  });

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  bool _isGenerating = false;
  AudioSummaryModel? _summary;
  String? _errorMessage;

  // Step-by-step progress state
  int _generatingStep = 0;
  Timer? _generatingTimer;

  // Speed control state
  double _selectedSpeed = 1.0;

  static const _generatingSteps = [
    'Analyzing your material...',
    'Generating script...',
    'Converting to audio...',
    'Almost ready!',
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _generatingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final summaries = await ref
          .read(audioSummaryRepositoryProvider)
          .getSummariesForMaterial(widget.materialId);
      if (summaries.isNotEmpty && mounted) {
        setState(() => _summary = summaries.first);
      }
    } catch (e) {
      // No existing summary
      debugPrint('AudioPlayerScreen: loadExisting failed: $e');
    }
  }

  void _startGeneratingSteps() {
    _generatingStep = 0;
    _generatingTimer?.cancel();
    _generatingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_generatingStep < _generatingSteps.length - 1) {
          _generatingStep++;
        }
      });
    });
  }

  void _stopGeneratingSteps() {
    _generatingTimer?.cancel();
    _generatingTimer = null;
  }

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });
    _startGeneratingSteps();
    HapticFeedback.mediumImpact();

    try {
      final summary = await ref
          .read(audioSummaryRepositoryProvider)
          .generateSummary(
            materialId: widget.materialId,
            courseId: widget.courseId,
          );
      if (!mounted) return;
      _stopGeneratingSteps();
      setState(() {
        _isGenerating = false;
        _summary = summary;
      });
      ref.invalidate(audioSummariesProvider(widget.courseId));
    } catch (e) {
      if (!mounted) return;
      _stopGeneratingSteps();
      setState(() {
        _isGenerating = false;
        _errorMessage = AppErrorHandler.friendlyMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.darkImmersive),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.xl, 0,
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
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: Icon(Icons.arrow_back,
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Audio Summary',
                        style: AppTypography.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Material title
                      Text(
                        widget.materialTitle,
                        style: AppTypography.h3.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      if (_summary != null) ...[
                        // Audio player UI
                        _buildPlayer(),

                        const SizedBox(height: AppSpacing.xxl),

                        // Summary text
                        if (_summary!.summaryText != null) ...[
                          Text(
                            'SUMMARY',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.4),
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              _summary!.summaryText!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ] else if (_isGenerating) ...[
                        _buildGenerating(),
                      ] else ...[
                        _buildGeneratePrompt(),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    final hasAudio = _summary?.hasAudio ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6467F2).withValues(alpha: 0.15),
            const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Album art
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.headphones, color: Colors.white, size: 36),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            _summary?.title ?? 'Audio Summary',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Text(
            hasAudio
                ? _summary!.formattedDuration
                : 'Text summary available',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Play button (placeholder - needs audio plugin)
          if (hasAudio) ...[
            TapScale(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Audio playback requires the just_audio package. Add it to pubspec.yaml.',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 36),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Speed controls
            _buildSpeedControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeedControls() {
    const speeds = [1.0, 1.25, 1.5, 2.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: speeds.map((speed) {
        final isSelected = _selectedSpeed == speed;
        final label = speed == 1.0
            ? '1x'
            : speed == 1.25
                ? '1.25x'
                : speed == 1.5
                    ? '1.5x'
                    : '2x';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TapScale(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedSpeed = speed);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenerating() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _generatingSteps[_generatingStep],
              key: ValueKey<int>(_generatingStep),
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This may take a couple of minutes',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Step indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_generatingSteps.length, (index) {
              final isActive = index <= _generatingStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.15),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratePrompt() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.record_voice_over,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Turn your notes into a podcast',
            style: AppTypography.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'AI creates a 5-10 min audio summary you can listen to while commuting or exercising',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          ShimmerButton(
            label: 'Generate Summary (~2 min)',
            icon: Icons.auto_awesome,
            onPressed: _generate,
            expanded: false,
          ),
        ],
      ),
    );
  }
}
