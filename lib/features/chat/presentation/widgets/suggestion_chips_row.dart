import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// A horizontally scrollable row of suggestion chips (light mode).
///
/// Shown below the conversation as quick-reply options the user
/// can tap to send a predefined question.
/// Matches mockup: bg-white/40, border-white/40, text-gray-700, rounded-xl.
class SuggestionChipsRow extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String>? onTap;

  const SuggestionChipsRow({
    super.key,
    required this.suggestions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          return _SuggestionChip(
            label: suggestions[index],
            onTap: () => onTap?.call(suggestions[index]),
          );
        },
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SuggestionChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: const Color(0xFF374151), // gray-700
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
