import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/groups_provider.dart';

/// Screen for joining a study group via invite code.
class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      await ref.read(groupRepositoryProvider).joinByCode(code);
      ref.invalidate(myGroupsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined group successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close,
              color: AppColors.textPrimaryFor(brightness)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Join Group',
          style: AppTypography.h3.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.login,
                    size: 36,
                    color: AppColors.primary.withValues(alpha: 0.6)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'Enter Invite Code',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimaryFor(brightness),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                'Ask your group admin for the 8-character code',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedFor(brightness),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            TextField(
              controller: _codeController,
              autofocus: true,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.none,
              style: AppTypography.h2.copyWith(
                color: AppColors.textPrimaryFor(brightness),
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'abcd1234',
                hintStyle: AppTypography.h2.copyWith(
                  color: AppColors.textMutedFor(brightness).withValues(alpha: 0.3),
                  letterSpacing: 4,
                ),
                filled: true,
                fillColor: context.isDark ? AppColors.cardDark : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
            const Spacer(),
            TapScale(
              onTap: _isJoining ? null : _join,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: _isJoining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Join Group',
                          style: AppTypography.button.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(
                height:
                    MediaQuery.of(context).padding.bottom + AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
