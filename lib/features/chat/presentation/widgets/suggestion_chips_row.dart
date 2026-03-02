import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// A single suggestion item with an icon and a text label.
class SuggestionItem {
  final IconData icon;
  final String label;

  const SuggestionItem({required this.icon, required this.label});
}

/// A horizontally scrollable row of suggestion chips (light mode).
///
/// Shown below the conversation as quick-reply options the user
/// can tap to send a predefined question.
/// Matches mockup: bg-white/40, border-white/40, text-gray-700, rounded-xl.
///
/// Accepts either [items] (icon+label pairs) or legacy [suggestions]
/// (plain strings without icons). If both are provided, [items] takes
/// precedence.
class SuggestionChipsRow extends StatelessWidget {
  /// Preferred: suggestion items with icon + label.
  final List<SuggestionItem>? items;

  /// Legacy: plain string suggestions (no icons).
  final List<String>? suggestions;

  final ValueChanged<String>? onTap;

  const SuggestionChipsRow({
    super.key,
    this.items,
    this.suggestions,
    this.onTap,
  }) : assert(items != null || suggestions != null,
            'Either items or suggestions must be provided');

  @override
  Widget build(BuildContext context) {
    // Resolve the effective list of items.
    final effectiveItems = items ??
        suggestions!
            .map((s) => SuggestionItem(icon: Icons.chat_bubble_outline, label: s))
            .toList();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: effectiveItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final item = effectiveItems[index];
          return _SuggestionChip(
            icon: item.icon,
            label: item.label,
            onTap: () => onTap?.call(item.label),
          );
        },
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SuggestionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  static const _gray700 = Color(0xFF374151);

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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: _gray700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: _gray700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
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
