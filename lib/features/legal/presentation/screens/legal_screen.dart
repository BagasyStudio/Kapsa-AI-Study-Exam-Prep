import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Legal screen that shows Terms of Service or Privacy Policy.
///
/// Opens the URL in an external browser. Shows a placeholder
/// with the link if the URL cannot be launched.
class LegalScreen extends StatelessWidget {
  final String title;
  final String url;

  const LegalScreen({
    super.key,
    required this.title,
    required this.url,
  });

  Future<void> _launchUrl() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: AppTypography.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  title.contains('Privacy')
                      ? Icons.privacy_tip_outlined
                      : Icons.description_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                title,
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                title.contains('Privacy')
                    ? 'Your privacy is important to us. Read our full privacy policy to understand how we collect, use, and protect your data.'
                    : 'By using Kapsa, you agree to our terms of service. Read the full terms below.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Open in browser button
              TapScale(
                onTap: _launchUrl,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Read Full $title',
                        style: AppTypography.button,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // URL display
              Center(
                child: Text(
                  url,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
