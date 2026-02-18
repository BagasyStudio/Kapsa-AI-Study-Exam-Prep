import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

/// Dialog that discloses AI data processing and asks for user consent.
///
/// Required by Apple App Store Guideline 5.1.1/5.1.2:
/// - Explains what data is sent
/// - Identifies who the data is sent to
/// - Asks for explicit permission before sharing
///
/// Returns `true` if the user accepts, `false` if they decline.
class AiConsentDialog extends StatelessWidget {
  const AiConsentDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AiConsentDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header icon
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Title
              Center(
                child: Text(
                  'AI-Powered Study Tools',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Description
              Text(
                'Kapsa uses AI to help you study smarter. When you use features '
                'like flashcard generation, quizzes, document scanning, or the '
                'AI tutor, your study materials are processed by our AI partners.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // What data is sent
              _InfoSection(
                icon: Icons.upload_outlined,
                title: 'What data is sent',
                description:
                    'Text from your study materials, images of scanned pages, '
                    'and audio recordings for transcription.',
              ),

              const SizedBox(height: AppSpacing.md),

              // Who receives it
              _InfoSection(
                icon: Icons.cloud_outlined,
                title: 'Who processes it',
                description:
                    'Replicate, Inc. — running Meta Llama, Google Gemma, '
                    'and Whisper AI models.',
              ),

              const SizedBox(height: AppSpacing.md),

              // Data retention
              _InfoSection(
                icon: Icons.shield_outlined,
                title: 'How your data is protected',
                description:
                    'Your data is only used to generate your study content. '
                    'It is not stored permanently by the AI provider and is '
                    'not used to train AI models.',
              ),

              const SizedBox(height: AppSpacing.lg),

              // Privacy Policy link
              Center(
                child: GestureDetector(
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://sites.google.com/view/kapsaaistudyexamprep/privacy-policy',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    'Read our Privacy Policy',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Accept button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  child: Text('I Agree', style: AppTypography.button),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Decline button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Decline',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
