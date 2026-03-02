import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/share_card_service.dart';
import '../../../../core/constants/xp_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../../gamification/presentation/widgets/xp_popup.dart';

/// Bottom sheet that previews a share card and handles sharing + XP reward.
class SharePreviewSheet extends ConsumerStatefulWidget {
  final Widget shareCard;
  final String shareType; // 'quiz', 'srs_review', 'flashcard_review', 'practice_exam'
  final String? referenceId;

  const SharePreviewSheet({
    super.key,
    required this.shareCard,
    required this.shareType,
    this.referenceId,
  });

  /// Show the share preview as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Widget shareCard,
    required String shareType,
    String? referenceId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePreviewSheet(
        shareCard: shareCard,
        shareType: shareType,
        referenceId: referenceId,
      ),
    );
  }

  @override
  ConsumerState<SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends ConsumerState<SharePreviewSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    HapticFeedback.mediumImpact();

    final success = await ShareCardService.captureAndShare(
      _cardKey,
      shareText: 'Study smarter with Kapsa ✨ kapsa.app',
    );

    if (success && mounted) {
      // Award XP
      try {
        await ref.read(xpRepositoryProvider).awardXp(
          action: 'share_result',
          amount: XpConfig.shareResult,
          metadata: {
            'type': widget.shareType,
            if (widget.referenceId != null) 'reference_id': widget.referenceId,
          },
        );
        ref.invalidate(xpTotalProvider);
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pop();
        XpPopup.show(context, xp: XpConfig.shareResult, label: 'Shared! 🎉');
      }
    } else if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1B2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        MediaQuery.of(context).padding.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'Share Your Results',
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimaryFor(brightness),
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '+${XpConfig.shareResult} XP bonus for sharing!',
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFFF59E0B),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Card preview (scaled down)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 340,
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(
                  key: _cardKey,
                  child: widget.shareCard,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Share button
          TapScale(
            onTap: _isSharing ? null : _share,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6467F2).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSharing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else ...[
                    const Icon(Icons.ios_share, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Share to Stories',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
