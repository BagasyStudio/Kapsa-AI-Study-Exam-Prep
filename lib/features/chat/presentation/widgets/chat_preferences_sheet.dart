import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/chat_preferences_provider.dart';

/// Shows the chat preferences bottom sheet.
void showChatPreferencesSheet(BuildContext context) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.immersiveCard,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.borderRadiusSheet,
    ),
    isScrollControlled: true,
    builder: (ctx) => const _ChatPreferencesSheetContent(),
  );
}

class _ChatPreferencesSheetContent extends ConsumerWidget {
  const _ChatPreferencesSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final prefs = ref.watch(chatPreferencesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title row
            Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l.chatPreferencesTitle,
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Response Style section
            Text(
              l.chatResponseStyle,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Style options
            _StyleOption(
              label: l.chatStyleBrief,
              description: l.chatStyleBriefDesc,
              icon: Icons.short_text_rounded,
              isSelected: prefs.responseStyle == ChatResponseStyle.brief,
              onTap: () {
                HapticFeedback.lightImpact();
                ref
                    .read(chatPreferencesProvider.notifier)
                    .setResponseStyle(ChatResponseStyle.brief);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _StyleOption(
              label: l.chatStyleDetailed,
              description: l.chatStyleDetailedDesc,
              icon: Icons.subject_rounded,
              isSelected: prefs.responseStyle == ChatResponseStyle.detailed,
              onTap: () {
                HapticFeedback.lightImpact();
                ref
                    .read(chatPreferencesProvider.notifier)
                    .setResponseStyle(ChatResponseStyle.detailed);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _StyleOption(
              label: l.chatStyleEli5,
              description: l.chatStyleEli5Desc,
              icon: Icons.child_care_rounded,
              isSelected: prefs.responseStyle == ChatResponseStyle.eli5,
              onTap: () {
                HapticFeedback.lightImpact();
                ref
                    .read(chatPreferencesProvider.notifier)
                    .setResponseStyle(ChatResponseStyle.eli5);
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Divider
            Container(
              height: 1,
              color: AppColors.immersiveBorder,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Include Examples toggle
            _ToggleRow(
              label: l.chatIncludeExamples,
              description: l.chatIncludeExamplesDesc,
              icon: Icons.lightbulb_outline_rounded,
              value: prefs.includeExamples,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                ref
                    .read(chatPreferencesProvider.notifier)
                    .setIncludeExamples(value);
              },
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

/// A selectable style option card.
class _StyleOption extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StyleOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.immersiveSurface,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.immersiveBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: isSelected ? Colors.white54 : Colors.white30,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// A toggle row with label, description, and switch.
class _ToggleRow extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: value ? AppColors.primary : Colors.white38,
          size: 22,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
          activeThumbColor: AppColors.primary,
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: AppColors.immersiveSurface,
        ),
      ],
    );
  }
}
