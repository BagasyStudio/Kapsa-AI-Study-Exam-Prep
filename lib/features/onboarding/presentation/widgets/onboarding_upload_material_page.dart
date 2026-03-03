import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Screen 5: Upload your first study material.
///
/// Two big action buttons (Scan pages / Upload PDF) + a subtle skip link.
/// Saves file locally for post-login processing.
class OnboardingUploadMaterialPage extends StatefulWidget {
  final bool isActive;
  final void Function(String path, String type, int fileSize) onMaterialPicked;
  final VoidCallback onSkip;

  const OnboardingUploadMaterialPage({
    super.key,
    required this.isActive,
    required this.onMaterialPicked,
    required this.onSkip,
  });

  @override
  State<OnboardingUploadMaterialPage> createState() =>
      _OnboardingUploadMaterialPageState();
}

class _OnboardingUploadMaterialPageState
    extends State<OnboardingUploadMaterialPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasAnimated = false;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isActive) _animate();
  }

  @override
  void didUpdateWidget(OnboardingUploadMaterialPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_hasAnimated) _animate();
  }

  void _animate() {
    _hasAnimated = true;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scanPages() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 75,
      );
      if (photo != null) {
        final file = File(photo.path);
        final size = await file.length();
        widget.onMaterialPicked(photo.path, 'camera', size);
        return;
      }
    } catch (_) {
      // User cancelled or camera unavailable
    }
    if (mounted) setState(() => _isPicking = false);
  }

  Future<void> _uploadPdf() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String? path = file.path;
        int size = file.size;
        if (path != null) {
          widget.onMaterialPicked(path, 'pdf', size);
          return;
        }
      }
    } catch (_) {
      // User cancelled
    }
    if (mounted) setState(() => _isPicking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final headerOpacity = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.3, curve: Curves.easeOut),
        ).value;
        final headerSlide = (1 - headerOpacity) * 20;

        final buttonsProgress = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
        ).value;

        final skipProgress = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
        ).value;

        final screenH = MediaQuery.of(context).size.height;
        final imgSize = (screenH * 0.15).clamp(90.0, 140.0);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),

                // Mascot
                Opacity(
                  opacity: headerOpacity,
                  child: Image.asset(
                    'assets/images/onboarding/onboarding_capture.png',
                    width: imgSize,
                    height: imgSize,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Title
                Opacity(
                  opacity: headerOpacity,
                  child: Transform.translate(
                    offset: Offset(0, headerSlide),
                    child: Text(
                      l.uploadTitle,
                      style: AppTypography.h1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimaryFor(brightness),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // Subtitle
                Opacity(
                  opacity: headerOpacity,
                  child: Text(
                    l.uploadSubtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                      height: 1.55,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: screenH * 0.04),

                // Action buttons
                Opacity(
                  opacity: buttonsProgress,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - buttonsProgress)),
                    child: Column(
                      children: [
                        // Scan pages
                        _ActionButton(
                          emoji: '\u{1F4F8}',
                          title: l.uploadScanPages,
                          subtitle: l.uploadScanSub,
                          isPrimary: true,
                          isDark: isDark,
                          brightness: brightness,
                          isLoading: _isPicking,
                          onTap: _scanPages,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Upload PDF
                        _ActionButton(
                          emoji: '\u{1F4C4}',
                          title: l.uploadPdf,
                          subtitle: l.uploadPdfSub,
                          isPrimary: false,
                          isDark: isDark,
                          brightness: brightness,
                          isLoading: _isPicking,
                          onTap: _uploadPdf,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenH * 0.05),

                // Skip link (subtle)
                Opacity(
                  opacity: skipProgress,
                  child: TapScale(
                    onTap: widget.onSkip,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        l.commonSkip,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMutedFor(brightness),
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textMutedFor(brightness),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Large action button
// ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final bool isDark;
  final Brightness brightness;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.isDark,
    required this.brightness,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
              : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrimary
                ? AppColors.primary.withValues(alpha: 0.3)
                : isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
            width: isPrimary ? 1.5 : 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h3.copyWith(
                      color: isPrimary
                          ? AppColors.primary
                          : AppColors.textPrimaryFor(brightness),
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(brightness),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isPrimary
                  ? AppColors.primary
                  : AppColors.textMutedFor(brightness),
            ),
          ],
        ),
      ),
    );
  }
}
