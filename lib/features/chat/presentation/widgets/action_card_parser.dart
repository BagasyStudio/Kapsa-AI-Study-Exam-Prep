import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Detects actionable patterns in AI chat messages and renders them as tappable cards.
class ActionCardParser {
  static final List<_ActionPattern> _patterns = [
    _ActionPattern(
      regex: RegExp(
        r'(\d+)\s*(flashcards?|cards?)\s*(pending|due|to review|for review)',
        caseSensitive: false,
      ),
      icon: Icons.style,
      label: 'Review Flashcards',
      actionType: ActionType.flashcards,
    ),
    _ActionPattern(
      regex: RegExp(
        r'(take|try|start|practice|do)\s*(a\s*)?(quiz|practice\s*exam|exam|test)',
        caseSensitive: false,
      ),
      icon: Icons.quiz,
      label: 'Start Practice',
      actionType: ActionType.practice,
    ),
    _ActionPattern(
      regex: RegExp(
        r'upload\s*(your\s*)?(materials?|notes?|files?|documents?)',
        caseSensitive: false,
      ),
      icon: Icons.upload_file,
      label: 'Upload Materials',
      actionType: ActionType.upload,
    ),
    _ActionPattern(
      regex: RegExp(
        r'(review|check)\s*(your\s*)?(scores?|results?|performance)',
        caseSensitive: false,
      ),
      icon: Icons.bar_chart,
      label: 'View Results',
      actionType: ActionType.results,
    ),
  ];

  /// Check if text contains actionable patterns and return matching actions.
  static List<ActionCardData> parseActions(String text) {
    final actions = <ActionCardData>[];
    for (final pattern in _patterns) {
      if (pattern.regex.hasMatch(text)) {
        final match = pattern.regex.firstMatch(text);
        actions.add(ActionCardData(
          icon: pattern.icon,
          label: pattern.label,
          actionType: pattern.actionType,
          matchedText: match?.group(0) ?? '',
        ));
      }
    }
    return actions;
  }
}

/// Types of actions that can be triggered from chat messages.
enum ActionType {
  flashcards,
  practice,
  upload,
  results,
}

class _ActionPattern {
  final RegExp regex;
  final IconData icon;
  final String label;
  final ActionType actionType;

  _ActionPattern({
    required this.regex,
    required this.icon,
    required this.label,
    required this.actionType,
  });
}

/// Data model for a detected action card.
class ActionCardData {
  final IconData icon;
  final String label;
  final ActionType actionType;
  final String matchedText;

  ActionCardData({
    required this.icon,
    required this.label,
    required this.actionType,
    required this.matchedText,
  });
}

/// Widget that renders a tappable action card inline in chat.
class InlineActionCard extends StatelessWidget {
  final ActionCardData action;
  final VoidCallback? onTap;

  const InlineActionCard({
    super.key,
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                action.label,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convenience widget that parses a message and renders all detected action cards.
class ActionCardsFromMessage extends StatelessWidget {
  final String messageText;
  final void Function(ActionType actionType)? onActionTap;

  const ActionCardsFromMessage({
    super.key,
    required this.messageText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final actions = ActionCardParser.parseActions(messageText);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: actions
          .map(
            (action) => InlineActionCard(
              action: action,
              onTap: onActionTap != null
                  ? () => onActionTap!(action.actionType)
                  : null,
            ),
          )
          .toList(),
    );
  }
}
