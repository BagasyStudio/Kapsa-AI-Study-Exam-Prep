import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/utils/error_handler.dart';
import '../providers/flashcard_provider.dart';

/// Screen for importing a shared flashcard deck using a 6-character code.
class ImportDeckScreen extends ConsumerStatefulWidget {
  final String courseId;

  const ImportDeckScreen({super.key, required this.courseId});

  @override
  ConsumerState<ImportDeckScreen> createState() => _ImportDeckScreenState();
}

class _ImportDeckScreenState extends ConsumerState<ImportDeckScreen> {
  final _codeController = TextEditingController();
  bool _isLooking = false;
  bool _isImporting = false;
  String? _previewTitle;
  int? _previewCardCount;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookupCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Code must be 6 characters');
      return;
    }

    setState(() {
      _isLooking = true;
      _errorMessage = null;
      _previewTitle = null;
      _previewCardCount = null;
    });

    try {
      final result = await ref
          .read(flashcardRepositoryProvider)
          .lookupShareCode(code);
      if (!mounted) return;
      setState(() {
        _isLooking = false;
        _previewTitle = result['title'] as String?;
        _previewCardCount = result['cardCount'] as int?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLooking = false;
        _errorMessage = AppErrorHandler.friendlyMessage(e);
      });
    }
  }

  Future<void> _importDeck() async {
    final code = _codeController.text.trim().toUpperCase();
    setState(() => _isImporting = true);
    HapticFeedback.mediumImpact();

    try {
      final deck = await ref
          .read(flashcardRepositoryProvider)
          .importDeck(code, widget.courseId);
      if (!mounted) return;

      // Invalidate deck list
      ref.invalidate(flashcardDecksProvider(widget.courseId));

      // Navigate to the new deck
      context.pushReplacement(Routes.flashcardSessionPath(deck.id));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
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
                    Text(
                      'Import Deck',
                      style: AppTypography.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

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
                      // Instruction
                      Text(
                        'Enter the 6-character share code to import a flashcard deck.',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Code input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _errorMessage != null
                                ? const Color(0xFFEF4444)
                                    .withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: TextField(
                          controller: _codeController,
                          style: AppTypography.h2.copyWith(
                            color: Colors.white,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w700,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            hintText: 'ABC123',
                            hintStyle: AppTypography.h2.copyWith(
                              color: Colors.white.withValues(alpha: 0.2),
                              letterSpacing: 6,
                              fontWeight: FontWeight.w700,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.lg,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _errorMessage = null;
                              _previewTitle = null;
                              _previewCardCount = null;
                            });
                            if (value.trim().length == 6) {
                              _lookupCode();
                            }
                          },
                        ),
                      ),

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _errorMessage!,
                          style: AppTypography.caption.copyWith(
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],

                      // Loading indicator
                      if (_isLooking) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],

                      // Preview card
                      if (_previewTitle != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6467F2),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.style,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _previewTitle!,
                                style: AppTypography.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${_previewCardCount ?? 0} cards',
                                style: AppTypography.bodySmall.copyWith(
                                  color:
                                      Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Import button
              if (_previewTitle != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    MediaQuery.of(context).padding.bottom + AppSpacing.md,
                  ),
                  child: _isImporting
                      ? Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6467F2),
                                Color(0xFF8B5CF6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : TapScale(
                          onTap: _importDeck,
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6467F2),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.download_rounded,
                                      color: Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Import Deck',
                                    style:
                                        AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
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
