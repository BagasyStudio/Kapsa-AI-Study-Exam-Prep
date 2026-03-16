import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// A single suggestion item with an icon and a text label.
class SuggestionItem {
  final IconData icon;
  final String label;

  const SuggestionItem({required this.icon, required this.label});
}

/// Suggestion chips that can render as a 2-column grid (empty state)
/// or as a horizontally scrollable row (inline with messages).
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

  /// When true, renders a 2-column grid suitable for the empty state.
  /// When false (default), renders an inline horizontal scroll row.
  final bool showAsGrid;

  const SuggestionChipsRow({
    super.key,
    this.items,
    this.suggestions,
    this.onTap,
    this.showAsGrid = false,
  }) : assert(items != null || suggestions != null,
            'Either items or suggestions must be provided');

  List<SuggestionItem> get _effectiveItems =>
      items ??
      suggestions!
          .map((s) => SuggestionItem(icon: Icons.chat_bubble_outline, label: s))
          .toList();

  @override
  Widget build(BuildContext context) {
    return showAsGrid ? _buildGrid(context) : _buildInlineRow(context);
  }

  // ── Grid mode (empty state) ──────────────────────────────────────────

  Widget _buildGrid(BuildContext context) {
    final effectiveItems = _effectiveItems;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 10) / 2;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: effectiveItems.map((item) {
              return _GridChip(
                icon: item.icon,
                label: item.label,
                width: cardWidth,
                onTap: () => onTap?.call(item.label),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ── Inline mode (with messages) ──────────────────────────────────────

  Widget _buildInlineRow(BuildContext context) {
    final effectiveItems = _effectiveItems;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: effectiveItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final item = effectiveItems[index];
          return _InlineChip(
            icon: item.icon,
            label: item.label,
            onTap: () => onTap?.call(item.label),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Grid chip — larger card for the empty state
// ═══════════════════════════════════════════════════════════════════════════

class _GridChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double width;
  final VoidCallback? onTap;

  const _GridChip({
    required this.icon,
    required this.label,
    required this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: width,
        height: 72,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: AppColors.primary.withValues(alpha: 0.60),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Inline chip — compact pill for the horizontal scroll row
// ═══════════════════════════════════════════════════════════════════════════

class _InlineChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _InlineChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.immersiveBorder),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.primary.withValues(alpha: 0.70),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
