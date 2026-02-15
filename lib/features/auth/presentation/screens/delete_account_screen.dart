import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../providers/auth_provider.dart';

/// Delete account confirmation screen.
///
/// User must type "DELETE" to enable the delete button.
/// Calls the delete-user-data Edge Function to permanently
/// remove all user data and auth account.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _controller = TextEditingController();
  bool _isDeleting = false;
  String? _error;

  bool get _canDelete => _controller.text.trim().toUpperCase() == 'DELETE';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (!_canDelete || _isDeleting) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      // Auth state change will trigger router redirect to /login
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _error = 'Failed to delete account. Please try again.';
      });
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
          'Delete Account',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
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
              // Warning icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'This action is permanent',
                style: AppTypography.h2.copyWith(
                  color: const Color(0xFFEF4444),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Deleting your account will permanently remove:',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              _BulletPoint('All your courses and study materials'),
              _BulletPoint('Chat history and AI conversations'),
              _BulletPoint('Flashcard decks and progress'),
              _BulletPoint('Test results and analytics'),
              _BulletPoint('Calendar events and study plans'),
              _BulletPoint('Your profile and account data'),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'This cannot be undone. Type DELETE to confirm.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Confirmation text field
              TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Type DELETE to confirm',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _canDelete
                          ? const Color(0xFFEF4444)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _canDelete
                          ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
                textCapitalization: TextCapitalization.characters,
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],

              const Spacer(),

              // Delete button
              _isDeleting
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEF4444),
                        strokeWidth: 2.5,
                      ),
                    )
                  : TapScale(
                      onTap: _canDelete ? _handleDelete : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _canDelete
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFEF4444).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            'Delete My Account Permanently',
                            style: AppTypography.button.copyWith(
                              color: _canDelete
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 10),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
